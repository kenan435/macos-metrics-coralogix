#!/bin/bash
# Install otel-collector as a macOS background service (LaunchAgent)

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLIST_NAME="com.coralogix.otel-collector"
PLIST_SRC="${SCRIPT_DIR}/${PLIST_NAME}.plist"
PLIST_DST="${HOME}/Library/LaunchAgents/${PLIST_NAME}.plist"
BINARY="${SCRIPT_DIR}/otelcol-contrib"

# Download binary if missing
if [ ! -f "$BINARY" ]; then
  echo "Downloading otelcol-contrib..."
  ARCH=$(uname -m)
  VERSION="0.112.0"
  if [ "$ARCH" = "arm64" ]; then
    curl -L -o "${SCRIPT_DIR}/otelcol-contrib.tar.gz" \
      "https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v${VERSION}/otelcol-contrib_${VERSION}_darwin_arm64.tar.gz"
  else
    curl -L -o "${SCRIPT_DIR}/otelcol-contrib.tar.gz" \
      "https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v${VERSION}/otelcol-contrib_${VERSION}_darwin_amd64.tar.gz"
  fi
  tar -xzf "${SCRIPT_DIR}/otelcol-contrib.tar.gz" -C "$SCRIPT_DIR"
  rm "${SCRIPT_DIR}/otelcol-contrib.tar.gz"
fi

# Stop existing service if running
if launchctl list | grep -q "$PLIST_NAME"; then
  echo "Stopping existing service..."
  launchctl unload "$PLIST_DST" 2>/dev/null || true
fi

# Install plist
cp "$PLIST_SRC" "$PLIST_DST"
launchctl load "$PLIST_DST"

echo ""
echo "✅ Service installed and started!"
echo ""
echo "Useful commands:"
echo "  Status:    launchctl list | grep coralogix"
echo "  Logs:      tail -f ${SCRIPT_DIR}/collector.log"
echo "  Stop:      launchctl unload ${PLIST_DST}"
echo "  Start:     launchctl load ${PLIST_DST}"
echo "  Uninstall: ./uninstall-service.sh"
