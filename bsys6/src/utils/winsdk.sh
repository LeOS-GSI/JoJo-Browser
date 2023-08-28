#!/usr/bin/env bash
set -e

source $BSYS6/source.sh

tmpdir="$(mktemp -d)"

echo "-> Fetching Windows SDK with mach"
$SOURCE/mach --no-interactive python --virtualenv build "$SOURCE/build/vs/pack_vs.py" "$SOURCE/build/vs/vs2019.yaml" -o "$tmpdir/vs.tar.zst"

echo "-> Extracting Windows SDK"
mkdir -p "$MOZBUILD/win-cross"
tar xfv "$tmpdir/vs.tar.zst" -C "$MOZBUILD/win-cross"

echo "-> Cleaning up"
rm -rf "$tmpdir"
