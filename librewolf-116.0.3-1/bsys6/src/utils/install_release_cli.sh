#!/usr/bin/env bash
set -eu

$BSYS6/utils/require_command.sh curl

echo "-> Installing GitLab release-cli" &>2
curl -L --output /usr/local/bin/release-cli "https://release-cli-downloads.s3.amazonaws.com/latest/release-cli-linux-amd64"
chmod +x /usr/local/bin/release-cli
