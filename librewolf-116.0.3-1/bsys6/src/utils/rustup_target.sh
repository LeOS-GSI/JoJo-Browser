#!/usr/bin/env bash
set -e

PATH="$HOME/.cargo/bin:$PATH"

$BSYS6/utils/require_command.sh rustup

while [[ $# -gt 0 ]]; do
  echo "-> Adding rustup target $1"
  rustup target add "$1"
  shift
done
