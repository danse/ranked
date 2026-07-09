#!/usr/bin/env bash
set -euo pipefail

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; exit 1; }

# --- test 1: default in-place cycles and opens browser (hard to test fully),
#             instead use -u to verify the up/write path works ---
cat > "$tmpdir/in1.txt" <<-EOF
	a.com,1
	b.com,-2
	c.com,0
EOF

cabal run ranked -- -u "$tmpdir/in1.txt" 2>/dev/null

last_counter=$(tail -1 "$tmpdir/in1.txt" | cut -d, -f2)
[ "$last_counter" = "1" ] \
  && pass "-u increments last counter" || fail "-u: expected last counter 1, got $last_counter"

# --- test 2: -u with -o writes to stdout, file unchanged ---
cat > "$tmpdir/in2.txt" <<-EOF
	a.com,1
	b.com,-2
	c.com,0
EOF

cp "$tmpdir/in2.txt" "$tmpdir/in2_original.txt"

cabal run ranked -- -u -o "$tmpdir/in2.txt" > "$tmpdir/actual.txt" 2>/dev/null

actual_lines=$(grep -c . "$tmpdir/actual.txt" 2>/dev/null || true)
[ "$actual_lines" = "3" ] \
  && pass "-u -o has 3 output lines" || fail "-u -o output line count: $actual_lines"

diff "$tmpdir/in2.txt" "$tmpdir/in2_original.txt" \
  && pass "-o leaves file unchanged" || fail "-o modified the file"

# --- test 3: -d decrements last counter ---
cat > "$tmpdir/in3.txt" <<-EOF
	a.com,1
	b.com,-2
	c.com,0
EOF

cabal run ranked -- -d "$tmpdir/in3.txt" 2>/dev/null

actual_counter=$(tail -1 "$tmpdir/in3.txt" | cut -d, -f2)
[ "$actual_counter" = "-1" ] \
  && pass "-d decrements last counter" || fail "-d: expected last counter -1, got $actual_counter"

# --- test 4: empty file ---
cat /dev/null > "$tmpdir/empty.txt"
cabal run ranked -- -u "$tmpdir/empty.txt" 2>/dev/null
[ ! -s "$tmpdir/empty.txt" ] \
  && pass "empty file stays empty" || fail "empty file got content"

# --- test 5: error input ---
cat > "$tmpdir/err.txt" <<-EOF
	url,abc
EOF

actual=$(cabal run ranked -- "$tmpdir/err.txt" 2>&1 || true)
[[ "$actual" == Error:* ]] \
  && pass "error on bad input" || fail "error on bad input (got: $actual)"

# --- test 6: no args ---
actual=$(cabal run ranked 2>&1 || true)
[[ "$actual" == *"Usage: ranked"* ]] \
  && pass "usage message" || fail "usage message (got: $actual)"

echo "All CLI tests passed"