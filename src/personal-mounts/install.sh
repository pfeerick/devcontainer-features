#!/usr/bin/env bash
set -euo pipefail

mkdir -p /usr/local/share/personal-mounts
cp "$(dirname "$0")/fix-ownership.sh" /usr/local/share/personal-mounts/fix-ownership.sh
chmod +x /usr/local/share/personal-mounts/fix-ownership.sh

echo "personal-mounts feature installed"
