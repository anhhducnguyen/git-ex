#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_SCRIPT="$SCRIPT_DIR/bootstrap.sh"
SOURCE_ZSHRC="$SCRIPT_DIR/zshrc"
TARGET_SCRIPT="/usr/local/bin/setupterminal"
TARGET_ZSHRC="/usr/local/bin/zshrc"

if [[ ! -f "$SOURCE_SCRIPT" ]]; then
  echo "Missing source script: $SOURCE_SCRIPT"
  exit 1
fi

if [[ ! -f "$SOURCE_ZSHRC" ]]; then
  echo "Missing zshrc template: $SOURCE_ZSHRC"
  exit 1
fi

if command -v sudo >/dev/null 2>&1; then
  sudo install -m 0755 "$SOURCE_SCRIPT" "$TARGET_SCRIPT"
  sudo install -m 0644 "$SOURCE_ZSHRC" "$TARGET_ZSHRC"
else
  install -m 0755 "$SOURCE_SCRIPT" "$TARGET_SCRIPT"
  install -m 0644 "$SOURCE_ZSHRC" "$TARGET_ZSHRC"
fi

echo "Installed: $TARGET_SCRIPT"
echo "Installed: $TARGET_ZSHRC"
echo "Run: setupterminal"
