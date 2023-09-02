#!/usr/bin/env bash
set -eu

if [ "$#" -lt 3 ]; then
  echo "Usage: move_artifact.sh <artifact_name> <directory> <file_regex> (new_file)" >&2
  exit 1
fi

source "$BSYS6/exports/target.sh"

echo "Searching for artifact $3" >&2
file="$(ls "$2" | grep -x "$3" | tail -n 1)"
if [ -z "$file" ]; then
  echo "$0: Failed to find artifact file $2/$3" >&2
  exit 1
fi

ext="${file##*.}"
if [[ "${file%.*}" == *".tar" ]]; then
  ext="tar.$ext"
fi
unique_file_name="librewolf-$FULL_VERSION-$TARGET-$ARCH-${1,,}"
if [ "$#" -lt 4 ]; then
  new_file="$unique_file_name.$ext"
elif [ "${4,,}" == "!keep" ]; then
  new_file="$file"
else
  new_file="$4"
fi

export $1="$ENTRY_PWD/$new_file"

if [ -f "$1" ]; then
  rm "$1"
fi
echo "Found $file, moving to ${!1}" >&2
mv -f "$2/$file" "${!1}"
mkdir -p "$WORKDIR/artifacts"
rm -rf "$WORKDIR/artifacts/$unique_file_name"
ln -s "${!1}" "$WORKDIR/artifacts/$unique_file_name"

echo "Calculating checksum" >&2
sha256sum "${!1}" | tee /dev/stderr | cut -f 1 -d " " >"${!1}.sha256sum"
export $1_SHA256="${!1}.sha256sum"
