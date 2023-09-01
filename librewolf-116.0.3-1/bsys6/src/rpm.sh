#!/usr/bin/env bash

# rpm.sh - make the Fedora-style `.rpm` package file.

set -eu

source $BSYS6/exports/require_target.sh linux
source $BSYS6/exports/require_artifact.sh package
source $BSYS6/exports/version.sh

print_arch() {
    case "$ARCH" in
    x86_64) echo "x86_64" ;;
    arm64) echo "aarch64" ;;
    i686) echo "i686" ;;
    esac
}

make_rpm_setup_folder() {
    # This line is stolen from $BSYS/update.sh
    # * We need a version here without the release number
    version="$(curl -sfS https://gitlab.com/librewolf-community/browser/source/-/raw/main/version)"
    release="$(curl -sfS https://gitlab.com/librewolf-community/browser/source/-/raw/main/release)"

    # Copy the needed assets.
    cp $BSYS6/../assets/linux.librewolf.spec librewolf.spec
    cp $BSYS6/../assets/linux.librewolf.desktop.in librewolf/librewolf.desktop.in
    cp $BSYS6/../assets/linux.librewolf.ico librewolf/librewolf.ico

    # Remove some files we don't want.
    rm -f librewolf/browser/features/proxy-failover@mozilla.com.xpi
    rm -f librewolf/pingsender
    rm -f librewolf/precomplete
    rm -f librewolf/removed-files
    rm -f librewolf/{glxtest,vaapitest} # fix: remove some tool binaries we don't want

    # Create and populate the source folder.
    rm -rf rpmbuild
    mkdir -p rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
    sed "s/__VERSION__/$version/g" <librewolf.spec >tmp.spec
    sed "s/__RELEASE__/$release/g" <tmp.spec >tmp2.spec
    arch2=$(print_arch)
    sed "s/__ARCH__/$arch2/g" <tmp2.spec >rpmbuild/SPECS/librewolf.spec
    rm librewolf.spec tmp.spec tmp2.spec

    # Populate the SOURCES folder.
    cp -r librewolf rpmbuild/SOURCES

    cd rpmbuild/SOURCES

    mkdir -p librewolf-$version/usr/share/librewolf
    mkdir -p librewolf-$version/usr/bin
    mv librewolf/* librewolf-$version/usr/share/librewolf
    rmdir librewolf
    (cd librewolf-$version/usr/bin && ln -s ../share/librewolf/librewolf)

    # Application icon
    mkdir -p librewolf-$version/usr/share/applications
    mkdir -p librewolf-$version/usr/share/icons/hicolor/16x16/apps
    mkdir -p librewolf-$version/usr/share/icons/hicolor/32x32/apps
    mkdir -p librewolf-$version/usr/share/icons/hicolor/64x64/apps
    mkdir -p librewolf-$version/usr/share/icons/hicolor/128x128/apps
    cp librewolf-$version/usr/share/librewolf/browser/chrome/icons/default/default16.png librewolf-$version/usr/share/icons/hicolor/16x16/apps/librewolf.png
    cp librewolf-$version/usr/share/librewolf/browser/chrome/icons/default/default32.png librewolf-$version/usr/share/icons/hicolor/32x32/apps/librewolf.png
    cp librewolf-$version/usr/share/librewolf/browser/chrome/icons/default/default64.png librewolf-$version/usr/share/icons/hicolor/64x64/apps/librewolf.png
    cp librewolf-$version/usr/share/librewolf/browser/chrome/icons/default/default128.png librewolf-$version/usr/share/icons/hicolor/128x128/apps/librewolf.png

    # This creates a `1ibrewolf.destop` file.
    sed "s/MYDIR/\/usr\/share\/librewolf/g" <librewolf-$version/usr/share/librewolf/librewolf.desktop.in >librewolf-$version/usr/share/applications/librewolf.desktop
    rm librewolf-$version/usr/share/librewolf/librewolf.desktop.in

    # This creates the `lw.tar.gz` file that is the payload in the SPEC file.
    tar cfz lw.tar.gz librewolf-$version
    rm -rf librewolf-$version
    cd ../.. # pop back to $tempdir folder
}

echo "-> Building Redhat package" >&2

if [ $(print_arch) != "aarch64" ]; then
    tmpdir=$(mktemp -d)
    (cd $tmpdir && tar xf "$PACKAGE")

    # This is the location to stuff the bsys5 stuff in here
    (cd $tmpdir && make_rpm_setup_folder)

    echo "-> Running rpmbuild"
    (cd $tmpdir && export HOME=$(pwd) && head rpmbuild/SPECS/librewolf.spec && setarch $(print_arch) rpmbuild -bb --target $(print_arch) --quiet --define "_rpmdir $tmpdir" rpmbuild/SPECS/librewolf.spec)
    (cd $tmpdir && cp -v $(print_arch)/*.rpm .)

    # Publish and cleanup.
    source $BSYS6/exports/move_artifact.sh "RPM" "$tmpdir" ".*\.rpm"
else
    echo "(limitation: skipping rpm package for aarch64)"
fi
