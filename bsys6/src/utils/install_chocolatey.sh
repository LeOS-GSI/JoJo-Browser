#!/usr/bin/env bash
set -eu

$BSYS6/utils/require_command.sh curl
$BSYS6/utils/require_command.sh tar

echo "-> Installing chocolatey" >&2
rm -rf "$MOZBUILD/chocolatey"
mkdir -p "$MOZBUILD/chocolatey"
curl -Lo "$MOZBUILD/chocolatey/chocolatey.tar.gz" "https://github.com/chocolatey/choco/releases/download/1.3.1/chocolatey.v1.3.1.tar.gz"
tar -C "$MOZBUILD/chocolatey" -xf "$MOZBUILD/chocolatey/chocolatey.tar.gz"
rm "$MOZBUILD/chocolatey/chocolatey.tar.gz"
cat >"$MOZBUILD/chocolatey/choco" <<EOF
#!/bin/bash
set -e
mono "\$(dirname \$(readlink -f "\$0"))/choco.exe" "\$@"
EOF
chmod +x "$MOZBUILD/chocolatey/choco"
