#!/usr/bin/env bash
set -eu

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <dependency to check>"
  exit 1
fi

while [ "$#" -gt 0 ]; do
  if ! command -v $1 >/dev/null; then
    echo "$1 not found, please install it" >&2
    exit 1
  fi
  shift
done
