#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

cabal test ranked-test 2>&1

tixfile="$PWD/ranked-test.tix"
if [ ! -f "$tixfile" ]; then
  tixfile=$(find . -name '*.tix' 2>/dev/null | head -1)
fi
if [ -z "$tixfile" ]; then
  echo "No .tix file found"
  exit 1
fi

export HPCDIR="$PWD/dist-newstyle/build/*/ghc-*/ranked-*/hpc/.hpc"
echo "=== Coverage report ==="
hpc report "$tixfile"

echo ""
echo "=== Markup ==="
outputdir="$PWD/dist-newstyle/coverage"
mkdir -p "$outputdir"
hpc markup "$tixfile" --destdir="$outputdir" 2>&1 || true
echo "Coverage HTML: $outputdir/index.html"