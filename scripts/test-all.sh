#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_CONFIG_DIR="$(mktemp -d)"
TMP_PROJECT_DIR="$(mktemp -d)"
TMP_AUTOSKETCH_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_CONFIG_DIR" "$TMP_PROJECT_DIR" "$TMP_AUTOSKETCH_DIR"' EXIT

cd "$ROOT_DIR"
IOT_UTILS_CONFIG_DIR="$TMP_CONFIG_DIR" python3 -m py_compile ./iot-utils
IOT_UTILS_CONFIG_DIR="$TMP_CONFIG_DIR" ./iot-utils --help
IOT_UTILS_CONFIG_DIR="$TMP_CONFIG_DIR" ./iot-utils upload --help
IOT_UTILS_CONFIG_DIR="$TMP_CONFIG_DIR" ./iot-utils port --help
IOT_UTILS_CONFIG_DIR="$TMP_CONFIG_DIR" ./iot-utils port list
IOT_UTILS_CONFIG_DIR="$TMP_CONFIG_DIR" ./iot-utils port show
(cd "$TMP_PROJECT_DIR" && IOT_UTILS_CONFIG_DIR="$TMP_CONFIG_DIR" "$ROOT_DIR/iot-utils" config init --project --force)
(cd "$TMP_PROJECT_DIR" && IOT_UTILS_CONFIG_DIR="$TMP_CONFIG_DIR" "$ROOT_DIR/iot-utils" port show)
grep -q "default_upload_speed: 115200" "$TMP_PROJECT_DIR/.iot-utils.yml"
IOT_UTILS_CONFIG_DIR="$TMP_CONFIG_DIR" ./iot-utils verify examples/Blink/Blink.ino --fqbn esp32
IOT_UTILS_CONFIG_DIR="$TMP_CONFIG_DIR" ./iot-utils verify examples/Blink/Blink.ino --fqbn uno
IOT_UTILS_CONFIG_DIR="$TMP_CONFIG_DIR" ./iot-utils verify examples/StagingFixture/WrongName.ino --fqbn uno
cp "$ROOT_DIR/examples/Blink/Blink.ino" "$TMP_AUTOSKETCH_DIR/older.ino"
sleep 1
cp "$ROOT_DIR/examples/Blink/Blink.ino" "$TMP_AUTOSKETCH_DIR/newer.ino"
AUTOSKETCH_OUTPUT="$(cd "$TMP_AUTOSKETCH_DIR" && IOT_UTILS_CONFIG_DIR="$TMP_CONFIG_DIR" "$ROOT_DIR/iot-utils" verify --fqbn esp32 2>&1)"
printf '%s\n' "$AUTOSKETCH_OUTPUT"
printf '%s' "$AUTOSKETCH_OUTPUT" | grep -q "No sketch path provided; using latest .ino in current directory: newer.ino"
set +e
UPLOAD_OUTPUT="$(IOT_UTILS_CONFIG_DIR="$TMP_CONFIG_DIR" ./iot-utils upload examples/Blink/Blink.ino --fqbn esp32 --port /dev/does-not-exist --upload-speed 115200 --no-input 2>&1)"
UPLOAD_STATUS=$?
set -e
printf '%s\n' "$UPLOAD_OUTPUT"
if [ "$UPLOAD_STATUS" -eq 0 ]; then
	printf '❌ Expected upload to fail safely for an invalid requested port\n' >&2
	exit 1
fi
printf '%s' "$UPLOAD_OUTPUT" | grep -q "Requested port not found among supported serial ports"
printf '🎉 iot-utils smoke tests completed\n'
