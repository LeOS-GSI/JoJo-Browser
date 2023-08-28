#!/usr/bin/env bash
set -eu

$BSYS6/utils/require_command.sh pacman

if ! command -v sudo >/dev/null; then
  pacman -Syu sudo
else
  echo "# sudo pacman -Syu --noconfirm"
  sudo pacman -Syu --noconfirm
fi

echo "-> Installing $@ dependencies with pacman"
echo "# sudo pacman -S --needed $@ --noconfirm"
sudo pacman -S --needed $@ --noconfirm
