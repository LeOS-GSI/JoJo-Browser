#!/usr/bin/env bash
set -eu

$BSYS6/utils/require_command.sh awk gpg

if [ -n "${SIGNING_KEY:-}" ] && [ -z "${SIGNING_KEY_FPR:-}" ] && [ -f "$SIGNING_KEY" ]; then
  echo "-> Setting up gpg signing using key located at '$SIGNING_KEY'," >&2
  export SIGNING_KEY_FPR="$(gpg --with-colons --import-options show-only --import --fingerprint <"$SIGNING_KEY" | awk -F: '$1 == "fpr" {print $10;}' | head -n 1)"
  echo "   fingerprint is '$SIGNING_KEY_FPR'" >&2
  gpg --import "$SIGNING_KEY"
  rm "$SIGNING_KEY"
fi
