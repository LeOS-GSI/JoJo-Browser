#!/usr/bin/env bash
set -eu

if [ "$#" -ne 2 ]; then
  echo "Usage: list_contains.sh <list> <item>" >&2
  exit 1
fi

[[ $1 =~ (^|[[:space:]])"$2"($|[[:space:]]) ]]
