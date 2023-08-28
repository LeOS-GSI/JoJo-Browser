#!/usr/bin/env bash
set -eu

if [ "$#" -ne 1 ]; then
  echo "Usage: require_artifact.sh <artifact>" >&2
  exit 1
fi

NAME="${1^^}"
name="${1,,}"
if [ -z "${!NAME:-}" ]; then
  source "$BSYS6/exports/version.sh"

  mkdir -p "$WORKDIR/artifacts"

  artifact="$WORKDIR/artifacts/librewolf-$FULL_VERSION-$TARGET-$ARCH-$name"

  if [ -f "$artifact" ] && [ -f "$(readlink -f "$artifact")" ]; then
    export $NAME="$(readlink -f "$artifact")"
    export ${NAME}_SHA256="$(readlink -f "$artifact").sha256sum"
  else
    source $BSYS6/$name.sh
  fi
fi
