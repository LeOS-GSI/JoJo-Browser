#!/usr/bin/env bash
set -eu

source $BSYS6/exports/target.sh
source $BSYS6/exports/require_build.sh

echo "-> Packaging locales (output hidden)" >&2
cat "$SOURCE/browser/locales/shipped-locales" | xargs "$SOURCE/mach" package-multi-locale --locales >/dev/null 2>/dev/null

if [ "$TARGET" == "windows" ]; then
  source $BSYS6/exports/move_artifact.sh "PACKAGE" "$SOURCE/obj-$MOZ_TARGET/dist" "librewolf-.*\.zip"
elif [ "$TARGET" == "macos" ]; then
  source $BSYS6/exports/move_artifact.sh "PACKAGE" "$SOURCE/obj-$MOZ_TARGET/dist" "librewolf-.*\.dmg"
else
  source $BSYS6/exports/move_artifact.sh "PACKAGE" "$SOURCE/obj-$MOZ_TARGET/dist" "librewolf-.*\.tar\.bz2"
fi
