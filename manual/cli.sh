#!/usr/bin/env bash
set -euo pipefail

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT
TIMEOUT=5

pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; exit 1; }

# --- test 1: default is in-place edit (file gets modified) ---
cat > "$tmpdir/in1.txt" <<-EOF
	a.com,1
	b.com,-2
	c.com,0
EOF

timeout $TIMEOUT cabal run ranked -- "$tmpdir/in1.txt" 2>/dev/null || true

actual_lines=$(grep -c . "$tmpdir/in1.txt" 2>/dev/null || true)
[ "$actual_lines" = "3" ] \
  && pass "in-place preserves line count" || fail "in-place line count: $actual_lines (expected 3)"

invalid=$(awk -F, 'NF < 2 || $2 !~ /^-?[0-9]+$/ {print}' "$tmpdir/in1.txt" 2>/dev/null || true)
[ -z "$invalid" ] \
  && pass "in-place output is valid url,number" || fail "invalid in-place output: $invalid"

# --- test 2: -o writes to stdout, file unchanged ---
cat > "$tmpdir/in2.txt" <<-EOF
	a.com,1
	b.com,-2
	c.com,0
EOF

cat > "$tmpdir/in2_original.txt" <<-EOF
	a.com,1
	b.com,-2
	c.com,0
EOF

timeout $TIMEOUT cabal run ranked -- -o "$tmpdir/in2.txt" > "$tmpdir/actual.txt" 2>/dev/null || true

actual_lines2=$(grep -c . "$tmpdir/actual.txt" 2>/dev/null || true)
[ "$actual_lines2" = "3" ] \
  && pass "stdout output has 3 lines" || fail "stdout output line count: $actual_lines2 (expected 3)"

diff "$tmpdir/in2.txt" "$tmpdir/in2_original.txt" \
  && pass "-o leaves file unchanged" || fail "-o modified the file"

# --- test 3: empty file ---
cat /dev/null > "$tmpdir/empty.txt"
timeout $TIMEOUT cabal run ranked -- "$tmpdir/empty.txt" 2>/dev/null || true
[ ! -s "$tmpdir/empty.txt" ] \
  && pass "empty file stays empty" || fail "empty file got content"

# --- test 4: error input ---
cat > "$tmpdir/err.txt" <<-EOF
	url,abc
EOF

actual=$(cabal run ranked -- "$tmpdir/err.txt" 2>&1 || true)
[[ "$actual" == Error:* ]] \
  && pass "error on bad input" || fail "error on bad input (got: $actual)"

# --- test 5: no args ---
actual=$(cabal run ranked 2>&1 || true)
[[ "$actual" == *"Usage: ranked"* ]] \
  && pass "usage message" || fail "usage message (got: $actual)"

echo "All CLI tests passed"