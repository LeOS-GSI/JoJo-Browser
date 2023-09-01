#!/usr/bin/env bash
set -eu

source $BSYS6/exports/version.sh

if [ -d "$SOURCEDIR" ]; then
  echo "-> Running 'mach clobber'"
  $SOURCEDIR/mach clobber
else
  echo "No source directory found. Skipping clobber."
fi
