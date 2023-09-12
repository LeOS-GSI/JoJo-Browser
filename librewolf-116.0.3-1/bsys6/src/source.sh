#!/usr/bin/env bash
set -eu

source $BSYS6/exports/target.sh
source $BSYS6/exports/version.sh

if [ -z "${SOURCE:-}" ]; then
  if [ ! -d "$SOURCEDIR" ]; then
    echo "-> Fetching librewolf-$VERSION.source.tar.gz" >&2

    $BSYS6/utils/require_command.sh tar

    mkdir -p "$SOURCEDIR/.." >&2
    mkdir -p "$WORKDIR" >&2

    curl -o "$WORKDIR/librewolf-$VERSION.source.tar.gz" "$SOURCE_URL" >&2

    echo "-> Extracting librewolf-$VERSION.source.tar.gz" >&2
    tar xf "$WORKDIR/librewolf-$VERSION.source.tar.gz" -C "$SOURCEDIR/.." >&2
    if [ "$(readlink -f "$SOURCEDIR")" != "$(readlink -f "$SOURCEDIR/../librewolf-$VERSION")" ]; then
      mv "$SOURCEDIR/../librewolf-$VERSION" "$SOURCEDIR" >&2
    fi
    rm "$WORKDIR/librewolf-$VERSION.source.tar.gz" >&2
  fi

  if [ ! -f "$SOURCEDIR/mozconfig.backup" ]; then
    if [ -f "$SOURCEDIR/mozconfig" ]; then
      echo "-> Creating mozconfig backup" >&2
      cp "$SOURCEDIR/mozconfig" "$SOURCEDIR/mozconfig.backup"
    else
      touch "$SOURCEDIR/mozconfig.backup"
    fi
  fi

  mozconfig="$(
    cat <<EOF
$(cat "$SOURCEDIR/mozconfig.backup")
ac_add_options --target=$MOZ_TARGET
EOF
  )"

  if [ -f "$BSYS6/../assets/$TARGET.mozconfig" ]; then
    mozconfig="$(
      cat <<EOF
$mozconfig
$(cat "$BSYS6/../assets/$TARGET.mozconfig")
EOF
    )"
  fi

  mozconfig_new_hash=$(echo "$mozconfig" | sha256sum | cut -d' ' -f1)
  mozconfig_old_hash=$(cat "$SOURCEDIR/mozconfig.hash" 2>/dev/null || echo "")

  if [ "$mozconfig_new_hash" != "$mozconfig_old_hash" ]; then
    echo "-> Updating mozconfig, target is $MOZ_TARGET" >&2
    echo "$mozconfig" >"$SOURCEDIR/mozconfig"
    echo "$mozconfig_new_hash" >"$SOURCEDIR/mozconfig.hash"
    export MOZCONFIG_CHANGED="true"
  fi

  export SOURCE="$SOURCEDIR"
fi

