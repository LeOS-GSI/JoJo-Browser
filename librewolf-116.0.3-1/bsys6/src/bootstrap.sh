#!/usr/bin/env bash
set -eu

source $BSYS6/source.sh

echo "-> Bootstrapping the build system with mach"
(cd $SOURCE && ./mach --no-interactive bootstrap --application-choice=browser)
