#!/usr/bin/env bash
set -eu

$BSYS6/utils/require_command.sh apt-get

if [ "$#" -eq 0 ]; then
  echo "apt-get.sh: At least one argument is required"
  exit 1
fi

if ! command -v sudo >/dev/null; then
  apt-get update
  apt-get install -y sudo
else
  echo "# sudo apt-get update"
  sudo apt-get update
fi

echo "-> Installing $@ with apt-get"
echo "# sudo apt-get install -y $@"
sudo apt-get install -y $@
