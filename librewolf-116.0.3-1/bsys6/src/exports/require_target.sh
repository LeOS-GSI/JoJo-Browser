#!/usr/bin/env bash
set -eu

if [ "$#" -ne 1 ]; then
  echo "Usage: default_target.sh <target>" >&2
  exit 1
fi

if [ -z "${TARGET:-}" ]; then
  echo "Notice: Setting target to '$1' as this command requires it" >&2
  export TARGET="$1"
else
  if [ "$TARGET" != "$1" ]; then
    echo "Error: Target '$TARGET' is incompatible with this command" >&2
    exit 1
  fi
fi
