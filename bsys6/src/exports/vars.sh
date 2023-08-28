#!/usr/bin/env bash
set -e

if [ -f "$BSYS6/../env.sh" ]; then
  source $BSYS6/../env.sh
fi

if [ -z "$BSYS6" ]; then
  export BSYS6="$(dirname "$(readlink -f "$0/..")")"
fi

if [ -z "${ARCH:-}" ]; then
  export ARCH="x86_64"
fi

if [ -z "${MOZBUILD:-}" ]; then
  export MOZBUILD="$HOME/.mozbuild"
fi

if [ -z "${WORKDIR:-}" ]; then
  export WORKDIR="$HOME/.local/share/bsys6/work"
fi
mkdir -p "$WORKDIR"

export AVAILABLE_TARGETS="linux windows macos"
export AVAILABLE_ARCHS="x86_64 arm64 i686"
export AVAILABLE_ARTIFACTS="SOURCE PACKAGE MSIX SETUP PORTABLE NUPKG DEB RPM"

if ! $BSYS6/utils/list_contains.sh "$AVAILABLE_ARCHS" "$ARCH"; then
  echo "Unsupported architecture $ARCH"
  exit 1
fi

if [ -z "${CI_API_V4_URL:-}" ]; then
  export CI_API_V4_URL="https://gitlab.com/api/v4"
fi

if [ -z "${CI_PROJECT_ID:-}" ]; then
  export CI_PROJECT_ID="44042130"
fi

if [ -z "${GL_API:-}" ]; then
  export GL_API="$CI_API_V4_URL/projects/$CI_PROJECT_ID"
fi
