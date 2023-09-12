#!/bin/bash
printf "\n\n------------------------------------ APPIMAGE BUILD -----------------------------------------\n"

# Aborts the script upon any faliure
set -e

# Sets up script variables
# BINARY_TARBALL=$1
APPIMAGE_FILE=$1
_SCRIPT_FOLDER=$(realpath "$(dirname $0)")
_BINARY_TARBALL_EXTRACTED_FOLDER=$_SCRIPT_FOLDER/librewolf
_BUILD_APPIMAGE_FILE=$_SCRIPT_FOLDER/LibreWolf.${CARCH}.AppImage
# assume building on x86_64 all the time
# _APPIMAGETOOL_DOWNLOAD_URL=https://github.com/AppImage/AppImageKit/releases/latest/download/appimagetool-${CARCH}.AppImage
_APPIMAGETOOL_DOWNLOAD_URL=https://github.com/AppImage/AppImageKit/releases/latest/download/appimagetool-x86_64.AppImage
_APPIMAGE_RUNTIME_DOWNLOAD_URL=https://github.com/AppImage/AppImageKit/releases/download/continuous
_APPIMAGETOOL_EXTRACTED_FOLDER=$_SCRIPT_FOLDER/squashfs-root
_APPIMAGETOOL_FILE=$_SCRIPT_FOLDER/appimagetool
_APPIMAGE_CONTENT_FOLDER=$_SCRIPT_FOLDER/content
_LAUNCHER_SCRIPT=$_SCRIPT_FOLDER/content/launch_librewolf.sh;

echo " Installs needed dependencies"
#apt-get update && apt-get -y install file wget bzip2 libdbus-glib-1-2 gnupg2 gettext-base

if [[ ! -z "${TARBALL_URL_AARCH64}" && $CARCH == 'aarch64' ]]; then
  BINARY_TARBALL_URL="${TARBALL_URL_AARCH64}"
  RUNTIME_FILE=runtime-aarch64
elif [[ ! -z "${TARBALL_URL_X86_64}" && $CARCH == 'x86_64' ]]; then
  BINARY_TARBALL_URL="${TARBALL_URL_X86_64}"
  RUNTIME_FILE=runtime-x86_64
fi
echo "1"
BINARY_TARBALL_FILENAME=$(echo "${BINARY_TARBALL_URL}" | grep -o '[^/]*$')
BINARY_TARBALL="${_SCRIPT_FOLDER}/${BINARY_TARBALL_FILENAME}"
wget "${BINARY_TARBALL_URL}" -O "${BINARY_TARBALL}"
echo "2"
if [[ ! -f "${BINARY_TARBALL}" ]]; then
  echo "Tarball not provided via pipeline or download."
  exit 1
fi

if [[ $CARCH == 'aarch64' ]]; then
  # y?
  apt install -y zlib1g-dev
fi


echo " Extracts the binary tarball"
printf "\nExtracting librewolf binary tarball\n"
mkdir "$_BINARY_TARBALL_EXTRACTED_FOLDER"
tar --strip-components=1 -xvf "$BINARY_TARBALL" -C "$_BINARY_TARBALL_EXTRACTED_FOLDER"

echo " requirese pkgver and pkgrel env vars set"
export DATE=$(date +%Y-%m-%d)
envsubst < "${_SCRIPT_FOLDER}/io.gitlab.librewolf-community.appdata.xml.in" > "${_BINARY_TARBALL_EXTRACTED_FOLDER}/io.gitlab.librewolf-community.appdata.xml"

# flatpak only?
# cp $LAUNCHER_SCRIPT $_BINARY_TARBALL_EXTRACTED_FOLDER/launch_librewolf.sh;

echo "Copy appimage resources to main tarball"
printf "Copying AppImage resources to binary tarball folder\n"
cp -vrT "$_APPIMAGE_CONTENT_FOLDER" "$_BINARY_TARBALL_EXTRACTED_FOLDER"

echo " Downloads appimage tool and runtime"
printf "\nDownloading AppImage Tool and runtime\n"
wget "$_APPIMAGETOOL_DOWNLOAD_URL" -O "$_APPIMAGETOOL_FILE"
wget "$_APPIMAGE_RUNTIME_DOWNLOAD_URL/$RUNTIME_FILE" -O "${_SCRIPT_FOLDER}/$RUNTIME_FILE"
chmod +x "$_APPIMAGETOOL_FILE"

echo " add appstream metadata"
install -Dvm644 "$_BINARY_TARBALL_EXTRACTED_FOLDER/io.gitlab.librewolf-community.appdata.xml" "$_BINARY_TARBALL_EXTRACTED_FOLDER/usr/share/metainfo/io.gitlab.librewolf-community.appdata.xml"
rm -f "$_BINARY_TARBALL_EXTRACTED_FOLDER/io.gitlab.librewolf-community.appdata.xml"

echo " provide icons for appimage-launcher"
install -D -m644 "$_BINARY_TARBALL_EXTRACTED_FOLDER/browser/chrome/icons/default/default128.png" "$_BINARY_TARBALL_EXTRACTED_FOLDER/usr/share/icons/hicolor/128x128/apps/librewolf.png"

echo " import signing key"
gpg2 --import "${SIGNING_KEY}"

echo " Generate AppImage"
printf "\nGenerating AppImage\n"
ARCH=${CARCH} "$_APPIMAGETOOL_FILE" --appimage-extract-and-run --sign \
  --runtime-file "${_SCRIPT_FOLDER}/$RUNTIME_FILE" \
  -u "zsync|https://gitlab.com/api/v4/projects/24386000/packages/generic/librewolf/latest/LibreWolf.${CARCH}.AppImage.zsync" \
  "$_BINARY_TARBALL_EXTRACTED_FOLDER" "$_BUILD_APPIMAGE_FILE"
chmod +x "$_BUILD_APPIMAGE_FILE"

echo " Move AppImage to specified location"
printf "\nMoving AppImage to specified location\n"
mv "${_BUILD_APPIMAGE_FILE}" "${APPIMAGE_FILE}"
mv "${_BUILD_APPIMAGE_FILE}.zsync" "${APPIMAGE_FILE}.zsync"

echo " Cleanup files"
printf "\nCleaning up AppImage files\n"
rm -rf "$_BINARY_TARBALL_EXTRACTED_FOLDER"
rm -f "$_APPIMAGETOOL_FILE"
rm -rf "$_APPIMAGETOOL_EXTRACTED_FOLDER"
