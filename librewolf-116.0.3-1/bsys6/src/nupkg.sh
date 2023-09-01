#!/usr/bin/env bash
set -eu

source $BSYS6/exports/version.sh
source $BSYS6/exports/require_target.sh windows
source $BSYS6/exports/require_artifact.sh setup
source $BSYS6/utils/require_choco.sh

echo "-> Building .nupkg" >&2
echo "v$VERSION -> v$CHOCO_VERSION"
tmpdir=$(mktemp -d)
echo "tmpdir is $tmpdir"
mkdir -p "$tmpdir/tools"
export CHOCO_FILE="$GL_API/packages/generic/librewolf/$FULL_VERSION/$(basename "$SETUP")"
export CHOCO_CHECKSUM="$(cat "$SETUP_SHA256")"
envsubst '$CHOCO_VERSION' \
  <"$BSYS6/../assets/choco/librewolf.nuspec.in" \
  >$tmpdir/librewolf.nuspec
envsubst '$CHOCO_FILE $CHOCO_CHECKSUM' \
  <"$BSYS6/../assets/choco/tools/chocolateyinstall.ps1.in" \
  >$tmpdir/tools/chocolateyinstall.ps1
cp "$BSYS6/../assets/choco/tools/chocolateyuninstall.ps1" "$tmpdir/tools"
(cd "$tmpdir" && "$MOZBUILD/chocolatey/choco" pack)

source $BSYS6/exports/move_artifact.sh "NUPKG" "$tmpdir" ".*\.nupkg"

rm -rf "$tmpdir"
