#!/usr/bin/env bash
set -eu

if [ "$#" -ne 2 ]; then
  echo 'Usage: dependencies.sh "<apt_dependencies>" "<pacman_dependencies>"'
  exit 1
fi

if command -v apt-get >/dev/null; then
  $BSYS6/utils/apt-get.sh $1
  exit
fi

if command -v pacman >/dev/null; then
  $BSYS6/utils/pacman.sh $2
  exit
fi

echo "No supported package manager found. Alternatives for the following apt packages need to be installed:"
echo "$1"
