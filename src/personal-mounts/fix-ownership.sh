#!/usr/bin/env bash
set -euo pipefail

current_user="$(id -un)"

for dir in /root/.config/gh /root/.claude; do
  if [ -d "$dir" ]; then
    owner="$(stat -c '%U' "$dir" 2>/dev/null || echo unknown)"
    if [ "$owner" != "$current_user" ]; then
      chown -R "$current_user":"$current_user" "$dir" 2>/dev/null || true
    fi
  fi
done

if command -v gh >/dev/null 2>&1; then
  gh auth setup-git >/dev/null 2>&1 || true
fi

if [ -d /root/.claude ] && [ ! -s /root/.claude/.claude.json ]; then
  echo '{}' > /root/.claude/.claude.json
fi
