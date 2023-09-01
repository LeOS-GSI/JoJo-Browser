#!/usr/bin/env bash
set -eu

source $BSYS6/exports/target.sh
source $BSYS6/exports/version.sh

if [ ! -d "$SOURCEDIR/obj-$MOZ_TARGET/dist" ]; then
  source "$BSYS6/build.sh"
else
  export SOURCE="$SOURCEDIR"
fi
