#!/usr/bin/env bash
set -eu

source $BSYS6/exports/require_target.sh windows
source $BSYS6/exports/require_artifact.sh package
source $BSYS6/source.sh

msix_arch() {
  case "$1" in
  i686) echo "x86" ;;
  *) echo "$1" ;;
  esac
}

echo "-> Building msix with mach" >&2
repackage_msix="$SOURCE/mach repackage msix --input $PACKAGE --channel unofficial --arch $(msix_arch $ARCH) --publisher CN=846D51B2-15A2-4033-86D1-071B877C86A7 --identity-name 31856maltejur.JoJo --publisher-display-name JoJo"
if [ ! -z "${MSIX_VERSION:-}" ]; then
  repackage_msix="$repackage_msix --version $MSIX_VERSION"
fi
(cd $SOURCE && MAKEAPPX=$MOZBUILD/msix-packaging/makemsix $repackage_msix)
source $BSYS6/exports/move_artifact.sh "MSIX" "$MOZBUILD/cache/mach-msix" "31856maltejur\.Meekat.*\.msix"
