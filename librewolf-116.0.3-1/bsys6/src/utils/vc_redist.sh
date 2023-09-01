#!/usr/bin/env bash
set -eu

# https://gitlab.com/librewolf-community/browser/windows/-/issues/244
case "$ARCH" in
x86_64) VC_REDIST_URL="https://gitlab.com/librewolf-community/browser/windows/uploads/7106b776dc663d985bb88eabeb4c5d7d/vc_redist.x64-extracted.zip" ;;
i686) VC_REDIST_URL="https://gitlab.com/librewolf-community/browser/bsys6/uploads/c4f4203ba35a344f28de28c525951e40/vc_redist_x32.zip" ;;
*) echo "Notice: No Visual C++ Redistributable available for architecture '$ARCH', excluding the dlls from the windows portable" ;;
esac
if [ -n "${VC_REDIST_URL:-}" ]; then
  pwd="$(pwd)"
  if [ "$#" -gt 0 ]; then
    cd "$1"
  fi
  $BSYS6/utils/download.sh "$VC_REDIST_URL" "vc_redist.zip"
  unzip vc_redist.zip
  rm vc_redist.zip
  cd "$pwd"
fi
