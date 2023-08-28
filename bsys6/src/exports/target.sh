#!/usr/bin/env bash
set -eu

# Extension of vars.sh, but kept in a seperate file because
# sometimes we want TARGET to be undefined, to be able to set
# it to the right value when needed in require_target.sh.

if [ -z "${TARGET:-}" ]; then
  export TARGET="linux"
fi

case $TARGET in
linux)
  export MOZ_TARGET="$ARCH-pc-linux-gnu"
  if [ "${ARCH:-}" == "arm64" ]; then
    export MOZ_TARGET="aarch64-unknown-linux-gnu"
  fi
  ;;
windows)
  export MOZ_TARGET="$ARCH-pc-mingw32"
  ;;
macos)
  export MOZ_TARGET="$ARCH-apple-darwin"
  if [ "${ARCH:-}" == "arm64" ]; then
    export MOZ_TARGET="aarch64-apple-darwin"
  fi
  ;;
dind) ;;
*)
  echo "Unsupported target $TARGET"
  exit 1
  ;;
esac
