#!/bin/bash
# Install macOS host metrics → Coralogix
# Usage: ./install.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLIST_NAME="com.coralogix.otel-collector"
PLIST_DST="${HOME}/Library/LaunchAgents/${PLIST_NAME}.plist"
BINARY="${SCRIPT_DIR}/otelcol-contrib"
VERSION="0.112.0"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  MacBook Host Metrics → Coralogix  Installer"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ── 1. Get Coralogix private key ──────────────────────
if [ -n "$CORALOGIX_PRIVATE_KEY" ]; then
  echo "Using CORALOGIX_PRIVATE_KEY from environment."
else
  echo "Enter your Coralogix Send-Your-Data API key (starts with cxtp_):"
  read -r -s CORALOGIX_PRIVATE_KEY
  echo ""
  if [ -z "$CORALOGIX_PRIVATE_KEY" ]; then
    echo "Error: API key is required." >&2
    exit 1
  fi
fi

# ── 2. Download otelcol-contrib if missing ────────────
if [ ! -f "$BINARY" ]; then
  echo "Downloading otelcol-contrib v${VERSION}..."
  ARCH=$(uname -m)
  if [ "$ARCH" = "arm64" ]; then
    TARBALL="otelcol-contrib_${VERSION}_darwin_arm64.tar.gz"
  else
    TARBALL="otelcol-contrib_${VERSION}_darwin_amd64.tar.gz"
  fi
  curl -fL --progress-bar \
    "https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v${VERSION}/${TARBALL}" \
    -o "${SCRIPT_DIR}/${TARBALL}"
  tar -xzf "${SCRIPT_DIR}/${TARBALL}" -C "$SCRIPT_DIR" otelcol-contrib
  rm "${SCRIPT_DIR}/${TARBALL}"
  chmod +x "$BINARY"
  echo "Binary downloaded."
else
  echo "otelcol-contrib binary already present."
fi

# ── 3. Stop existing service if running ──────────────
if launchctl list 2>/dev/null | grep -q "$PLIST_NAME"; then
  echo "Stopping existing service..."
  launchctl bootout "gui/$(id -u)/${PLIST_NAME}" 2>/dev/null || \
    launchctl unload "$PLIST_DST" 2>/dev/null || true
  sleep 1
fi

# ── 4. Generate plist with correct paths & key ───────
echo "Installing LaunchAgent..."
cat > "$PLIST_DST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${PLIST_NAME}</string>

    <key>ProgramArguments</key>
    <array>
        <string>${BINARY}</string>
        <string>--config</string>
        <string>${SCRIPT_DIR}/config.yaml</string>
    </array>

    <key>EnvironmentVariables</key>
    <dict>
        <key>CORALOGIX_PRIVATE_KEY</key>
        <string>${CORALOGIX_PRIVATE_KEY}</string>
    </dict>

    <key>RunAtLoad</key>
    <true/>

    <key>KeepAlive</key>
    <true/>

    <key>StandardOutPath</key>
    <string>${SCRIPT_DIR}/collector.log</string>

    <key>StandardErrorPath</key>
    <string>${SCRIPT_DIR}/collector.log</string>

    <key>ThrottleInterval</key>
    <integer>30</integer>
</dict>
</plist>
PLIST

# ── 5. Start the service ─────────────────────────────
launchctl bootstrap "gui/$(id -u)" "$PLIST_DST"

# ── 6. Verify ────────────────────────────────────────
echo ""
echo "Waiting for collector to start..."
sleep 10

if launchctl list 2>/dev/null | grep -q "$PLIST_NAME"; then
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  Installation complete!"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "  Metrics will appear in Coralogix within ~2 min"
  echo "  Application name : macbook"
  echo "  Subsystem name   : host-metrics"
  echo ""
  echo "  Useful commands:"
  echo "    Logs:      tail -f ${SCRIPT_DIR}/collector.log"
  echo "    Status:    launchctl list | grep coralogix"
  echo "    Uninstall: ./uninstall-service.sh"
  echo ""
else
  echo ""
  echo "Warning: service may not have started. Check logs:"
  echo "  tail -50 ${SCRIPT_DIR}/collector.log"
  exit 1
fi
