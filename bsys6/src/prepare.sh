#!/usr/bin/env bash
set -eu

source $BSYS6/exports/target.sh

case $TARGET in

linux)
  echo "-> Preparing build environment for native linux build (target: linux)"

  $BSYS6/utils/dependencies.sh "python3-pip curl rpm gnupg jq" "python-pip curl dpkg rpm gnupg jq"
  # cross-compilation
  $BSYS6/utils/dependencies.sh "binutils-aarch64-linux-gnu" "aarch64-linux-gnu-binutils"
  source $BSYS6/exports/version.sh
  $BSYS6/bootstrap.sh
  $BSYS6/utils/rustup_target.sh "aarch64-unknown-linux-gnu" "i686-unknown-linux-gnu"
  $BSYS6/utils/install_toolchain_artifact.sh "sysroot-wasm32-wasi" "linux64-cbindgen"
  ;;

windows)
  echo "-> Preparing build environment for cross-compilation to windows (target: windows)"

  $BSYS6/utils/dependencies.sh "python3-pip curl msitools zstd libc6-i386 p7zip-full jq zip unzip wget mono-complete gettext-base pkg-config" "python-pip curl msitools zstd lib32-glibc p7zip jq zip unzip wget mono gettext pkgconf"
  source $BSYS6/exports/version.sh
  $BSYS6/bootstrap.sh
  $BSYS6/utils/rustup_target.sh "x86_64-pc-windows-msvc" "aarch64-pc-windows-msvc" "i686-pc-windows-msvc"
  $BSYS6/utils/install_toolchain_artifact.sh "linux64-binutils" "linux64-cbindgen" "linux64-clang" "linux64-dump_syms" "linux64-nasm" "linux64-node" "linux64-rust-cross" "linux64-winchecksec" "linux64-wine" "linux64-msix-packaging" "linux64-mingw-fxc2-x86" "nsis" "sysroot-x86_64-linux-gnu"
  $BSYS6/utils/winsdk.sh
  $BSYS6/utils/install_chocolatey.sh
  ;;

macos)
  echo "-> Preparing build environment for cross-compilation to macOS (target: macos)"

  $BSYS6/utils/dependencies.sh "python3-pip curl rsync zip unzip python3-testresources jq" "python-pip curl rsync zip unzip python-testresources jq"
  source $BSYS6/exports/version.sh
  $BSYS6/bootstrap.sh
  $BSYS6/utils/rustup_target.sh "x86_64-apple-darwin" "aarch64-apple-darwin"
  $BSYS6/utils/install_toolchain_artifact.sh "sysroot-wasm32-wasi" "linux64-libdmg" "linux64-cctools-port" "linux64-hfsplus" "linux64-binutils"
  ;;

dind)
  if [ -z "${DOCKER:-}" ]; then
    echo "Error: Preparing the 'dind' target should only happen inside a docker container" >&2
    exit 1
  fi

  echo "-> Preparing dind container"

  $BSYS6/utils/dependencies.sh "ca-certificates curl gnupg lsb-release mono-complete jq gettext-base" ""
  curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list >/dev/null
  $BSYS6/utils/dependencies.sh "docker-ce docker-ce-cli containerd.io docker-compose-plugin make wget lbzip2" ""
  $BSYS6/utils/install_release_cli.sh
  $BSYS6/utils/install_chocolatey.sh
  ;;

*)
  echo "Can not prepare build environment for target '$TARGET'"
  exit 1
  ;;
esac
