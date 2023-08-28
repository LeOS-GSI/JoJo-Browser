#!/usr/bin/env bash
set -eu -o pipefail

source $BSYS6/exports/require_target.sh windows
source $BSYS6/exports/require_artifact.sh package

echo "-> Extracting packaged build"
tmpdir="$(mktemp -d)"
echo "tmpdir is $tmpdir"
unzip "$PACKAGE" -d "$tmpdir"
mv "$tmpdir/librewolf" "$tmpdir/LibreWolf"

echo "-> Building installer with nsis"
cp -v "$BSYS6/../assets/librewolf.ico" "$tmpdir/LibreWolf/librewolf.ico"
mkdir -p "$tmpdir/x86-ansi"
cp -v "$BSYS6/../assets/nsProcess.dll" "$tmpdir/x86-ansi/nsProcess.dll"
$BSYS6/utils/download.sh "https://aka.ms/vs/17/release/vc_redist.x64.exe" "$tmpdir/vc_redist.x64.exe"
$BSYS6/utils/download_codeberg.sh "ltguillaume/librewolf-winupdater" 'LibreWolf-WinUpdater.*\\.zip' "$tmpdir/LibreWolf-WinUpdater.zip"
$BSYS6/utils/download_codeberg.sh "ltguillaume/librewolf-portable" 'LibreWolf-Portable.*\\.zip' "$tmpdir/LibreWolf-Portable.zip"
$BSYS6/utils/vc_redist.sh "$tmpdir/LibreWolf"
unzip "$tmpdir/LibreWolf-WinUpdater.zip" -d "$tmpdir"
unzip "$tmpdir/LibreWolf-Portable.zip" -d "$tmpdir"
sed "s/pkg_version/$FULL_VERSION/g" <"$BSYS6/../assets/setup.nsi" >"$tmpdir/setup.nsi"
cp "$BSYS6/../assets/librewolf.ico" "$tmpdir"
cp "$BSYS6/../assets/banner.bmp" "$tmpdir"
printf "Running nsis... "
(cd "$tmpdir" && $MOZBUILD/nsis/bin/makensis -V1 "setup.nsi")
echo "Done"

source $BSYS6/exports/move_artifact.sh "SETUP" "$tmpdir" ".*setup\.exe"

rm -rf "$tmpdir"
unset TMPDIR
