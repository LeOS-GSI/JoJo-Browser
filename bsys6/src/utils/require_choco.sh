#!/usr/bin/env bash
set -eu

if [ ! -f "$MOZBUILD/chocolatey/choco" ]; then
  echo "Error: Chocolatey was not found, did you run 'TARGET=windows bsys6 prepare'?" >&2
  exit 1
fi
