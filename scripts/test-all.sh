#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_CONFIG_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_CONFIG_DIR" "$ROOT_DIR/.iot-utils.yml"' EXIT

cd "$ROOT_DIR"
IOT_UTILS_CONFIG_DIR="$TMP_CONFIG_DIR" python3 -m py_compile ./iot-utils
IOT_UTILS_CONFIG_DIR="$TMP_CONFIG_DIR" ./iot-utils --help
IOT_UTILS_CONFIG_DIR="$TMP_CONFIG_DIR" ./iot-utils port --help
IOT_UTILS_CONFIG_DIR="$TMP_CONFIG_DIR" ./iot-utils port list
IOT_UTILS_CONFIG_DIR="$TMP_CONFIG_DIR" ./iot-utils port show
IOT_UTILS_CONFIG_DIR="$TMP_CONFIG_DIR" ./iot-utils config init --project --force
IOT_UTILS_CONFIG_DIR="$TMP_CONFIG_DIR" ./iot-utils port show
IOT_UTILS_CONFIG_DIR="$TMP_CONFIG_DIR" ./iot-utils verify examples/Blink/Blink.ino --fqbn esp32
IOT_UTILS_CONFIG_DIR="$TMP_CONFIG_DIR" ./iot-utils verify examples/Blink/Blink.ino --fqbn uno
IOT_UTILS_CONFIG_DIR="$TMP_CONFIG_DIR" ./iot-utils verify examples/StagingFixture/WrongName.ino --fqbn uno
set +e
UPLOAD_OUTPUT="$(IOT_UTILS_CONFIG_DIR="$TMP_CONFIG_DIR" ./iot-utils upload examples/Blink/Blink.ino --fqbn esp32 --no-input 2>&1)"
UPLOAD_STATUS=$?
set -e
printf '%s\n' "$UPLOAD_OUTPUT"
if [ "$UPLOAD_STATUS" -eq 0 ]; then
	printf '❌ Expected upload to fail safely when no usable port is available\n' >&2
	exit 1
fi
printf '%s' "$UPLOAD_OUTPUT" | grep -q "No usable serial ports detected"
printf '🎉 iot-utils smoke tests completed\n'
