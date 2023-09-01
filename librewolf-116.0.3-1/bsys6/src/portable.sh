#!/usr/bin/env bash
set -eu

source $BSYS6/exports/require_target.sh windows
source $BSYS6/exports/require_artifact.sh package
$BSYS6/utils/require_command.sh "jq" "zip" "unzip" "wget"

echo "-> Building portable zip" >&2
tmpdir="$(mktemp -d)"

cd $tmpdir
mkdir -p librewolf-$VERSION/Profiles/Default
mkdir -p librewolf-$VERSION/LibreWolf

cd librewolf-$VERSION/LibreWolf
unzip -q $PACKAGE
mv librewolf/* .
rmdir librewolf
$BSYS6/utils/vc_redist.sh
cd ..

# ahk-tools by @ltGuillaume
$BSYS6/utils/download_codeberg.sh "ltguillaume/librewolf-winupdater" 'LibreWolf-WinUpdater.*\\.zip' "LibreWolf-WinUpdater.zip"
$BSYS6/utils/download_codeberg.sh "ltguillaume/librewolf-portable" 'LibreWolf-Portable.*\\.zip' "LibreWolf-Portable.zip"
unzip LibreWolf-WinUpdater.zip
unzip LibreWolf-Portable.zip
rm LibreWolf-WinUpdater.zip LibreWolf-Portable.zip

# extra files from the zip files
rm *.url

# make the final zip
cd $tmpdir
zip -r9 librewolf-$VERSION.en-US.win64-portable.zip librewolf-$VERSION

source $BSYS6/exports/move_artifact.sh "PORTABLE" "$tmpdir" "librewolf-.*\.zip"
