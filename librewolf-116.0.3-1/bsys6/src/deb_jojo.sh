#!/usr/bin/env bash

# deb.sh - make the debian style `.deb` package file.
echo "make JoJo's"
bash src/jojo.sh


set -eu

source $BSYS6/exports/require_target.sh linux
source $BSYS6/exports/require_artifact.sh package
source $BSYS6/exports/version.sh


src/utils/require_command.sh dpkg gpg

# Including legacy script as a function.
function build_deb() {
    mv librewolf lwdist

    mkdir -p librewolf/DEBIAN
    cd librewolf/DEBIAN
    cat <<EOF >control
Architecture: all
Build-Depends: inkscape, librsvg2-bin
Depends: lsb-release, libasound2 (>= 1.0.16), libatk1.0-0 (>= 1.12.4), libc6 (>= 2.31), libcairo-gobject2 (>= 1.10.0), libcairo2 (>= 1.10.0), libdbus-1-3 (>= 1.9.14), libdbus-glib-1-2 (>= 0.78), libfontconfig1 (>= 2.12.6), libfreetype6 (>= 2.10.1), libgcc-s1 (>= 3.3), libgdk-pixbuf2.0-0 (>= 2.22.0), libglib2.0-0 (>= 2.42), libgtk-3-0 (>= 3.14), libharfbuzz0b (>= 0.6.0), libpango-1.0-0 (>= 1.14.0), libpangocairo-1.0-0 (>= 1.14.0), libstdc++6 (>= 10), libx11-6, libx11-xcb1 (>= 2:1.6.9), libxcb-shm0, libxcb1, libxcomposite1 (>= 1:0.4.5), libxcursor1 (>> 1.1.2), libxdamage1 (>= 1:1.1), libxext6, libxfixes3, libxi6, libxrandr2 (>= 2:1.4.0), libxrender1, libxtst6
Recommends: libcanberra0, libdbusmenu-glib4, libdbusmenu-gtk3-4
Suggests: fonts-lyx
Description: JoJo's Browser
Download-Size: 56.0 MB
Essential: no
Installed-Size: 204 MB
Maintainer: harvey186 <harvey186@hotmail.com>
Package: jojo
Priority: optional
Provides: gnome-www-browser, www-browser, x-www-browser
Section: web
EOF
    echo "Version: $1" >>control
    cd ..

    mkdir -p usr/share/librewolf
    mv ../lwdist/* usr/share/librewolf
    rmdir ../lwdist

    mkdir -p usr/bin
    cd usr/bin
    ln -s ../share/librewolf/librewolf
    cd ../..

    # add the application icon
    mkdir -p usr/share/applications
    mkdir -p usr/share/icons/hicolor/16x16/apps
    mkdir -p usr/share/icons/hicolor/32x32/apps
    mkdir -p usr/share/icons/hicolor/64x64/apps
    mkdir -p usr/share/icons/hicolor/128x128/apps
    cp usr/share/librewolf/browser/chrome/icons/default/default16.png usr/share/icons/hicolor/16x16/apps/librewolf.png
    cp usr/share/librewolf/browser/chrome/icons/default/default32.png usr/share/icons/hicolor/32x32/apps/librewolf.png
    cp usr/share/librewolf/browser/chrome/icons/default/default64.png usr/share/icons/hicolor/64x64/apps/librewolf.png
    cp usr/share/librewolf/browser/chrome/icons/default/default128.png usr/share/icons/hicolor/128x128/apps/librewolf.png
    cp ../librewolf.desktop usr/share/applications/jojo.desktop

    cd ..
    dpkg-deb --build librewolf

    # Sign the deb file if private key is provided and we have dpkg-sig available
    if [[ -f pk.asc ]] && command -v dpkg-sig &>/dev/null; then
        gpg --import pk.asc
        dpkg-sig --sign builder jojo.deb
    fi
}

echo "-> Building Debian package" >&2

tmpdir=$(mktemp -d)
(cd $tmpdir && tar xf "$PACKAGE")

sed "s/MYDIR/\/usr\/share\/librewolf/g" <$BSYS6/../assets/linux.librewolf.desktop.in >$tmpdir/librewolf.desktop
(cd $tmpdir && build_deb $FULL_VERSION)

# Publish and cleanup.
source $BSYS6/exports/move_artifact.sh "DEB" "$tmpdir" ".*\.deb"
rm -rf $tmpdir
