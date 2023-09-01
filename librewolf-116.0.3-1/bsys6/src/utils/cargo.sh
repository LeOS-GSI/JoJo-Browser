#!/usr/bin/env bash
set -eu

PATH="$HOME/.cargo/bin:$PATH"

$BSYS6/utils/require_command.sh cargo

while [[ $# -gt 0 ]]; do
  echo "-> Installing $1 with cargo"
  cargo install "$1"
  shift
done
