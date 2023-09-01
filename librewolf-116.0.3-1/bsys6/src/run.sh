#!/usr/bin/env bash
set -eu

source $BSYS6/exports/require_build.sh

echo "-> Running 'mach run'" >&2
$SOURCE/mach run $@
exit 0
