#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

cabal configure --enable-coverage 2>&1
cabal build 2>&1
cabal test 2>&1

tixfile=$(find dist-newstyle -name '*.tix' 2>/dev/null | head -1)
if [ -z "$tixfile" ]; then
  tixfile=$(find . -maxdepth 1 -name '*.tix' 2>/dev/null | head -1)
fi
if [ -z "$tixfile" ]; then
  echo "No .tix file found"
  exit 1
fi

echo "=== Coverage report ==="
hpc report "$tixfile"

echo ""
echo "=== Markup ==="
outputdir="$PWD/dist-newstyle/coverage"
mkdir -p "$outputdir"
hpc markup "$tixfile" --destdir="$outputdir" 2>&1 || true
echo "Coverage HTML: $outputdir/index.html"