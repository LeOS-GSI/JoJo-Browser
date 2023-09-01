#!/usr/bin/env bash
set -eu
set -o pipefail

source "$BSYS6/exports/vars.sh"

if [ -z "${VERSION:-}" ]; then
  if [ ! -f "$WORKDIR/version" ] || find "$WORKDIR/version" -mmin +720 | grep . >/dev/null; then
    source "$BSYS6/update.sh"
  else
    export VERSION="$(cat "$WORKDIR/version")"
  fi
fi

if [ -z "${SOURCEDIR:-}" ]; then
  export SOURCEDIR="$WORKDIR/librewolf-$VERSION"
fi

if [ -z "${SOURCE_URL:-}" ]; then
  export SOURCE_URL="https://gitlab.com/api/v4/projects/32320088/packages/generic/librewolf-source/$VERSION/librewolf-$VERSION.source.tar.gz"
fi

if [ -z "${FULL_VERSION:-}" ]; then
  if [ -n "${RELEASE:-}" ] && [ "$RELEASE" != "1" ]; then
    export FULL_VERSION="$VERSION-$RELEASE"
  else
    export RELEASE="1"
    export FULL_VERSION="$VERSION"
  fi
fi

if [ -z "${CHOCO_VERSION:-}" ]; then
  ver=$(echo "$VERSION" | sed 's/-.*$//g')
  rel=$(echo "$VERSION" | sed 's/^.*-//g')
  export CHOCO_VERSION="$ver$(echo $(for i in $(seq $(echo "$ver" | tr -cd '.' | wc -c) 1); do printf ".0"; done)).$rel"
fi
