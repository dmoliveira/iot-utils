#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL_BASE="${IOT_UTILS_HOME:-$HOME/.local/share/iot-utils}"
BIN_DIR="${IOT_UTILS_BIN:-$HOME/.local/bin}"

mkdir -p "$INSTALL_BASE" "$BIN_DIR"
cp "$ROOT_DIR/iot-utils" "$INSTALL_BASE/iot-utils"
cp "$ROOT_DIR/iot-utils.json" "$INSTALL_BASE/iot-utils.json"
chmod +x "$INSTALL_BASE/iot-utils"
ln -sf "$INSTALL_BASE/iot-utils" "$BIN_DIR/iot-utils"

printf '✅ Installed iot-utils to %s\n' "$INSTALL_BASE"
printf '✅ Linked command at %s/iot-utils\n' "$BIN_DIR"
printf '🔎 If needed, add this to your shell profile: export PATH="%s:$PATH"\n' "$BIN_DIR"
