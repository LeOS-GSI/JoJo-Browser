#!/usr/bin/env bash
set -eu

if [ "$#" -ne 2 ]; then
  echo 'Usage: download.sh <url> <target_file>'
  exit 1
fi

echo "'$1' -> '$2'"
curl -fL "$1" -o "$2"
