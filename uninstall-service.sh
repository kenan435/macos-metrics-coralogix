#!/bin/bash
# Uninstall the otel-collector LaunchAgent

PLIST_NAME="com.coralogix.otel-collector"
PLIST_DST="${HOME}/Library/LaunchAgents/${PLIST_NAME}.plist"

if launchctl list | grep -q "$PLIST_NAME"; then
  launchctl unload "$PLIST_DST"
  echo "Service stopped."
fi

if [ -f "$PLIST_DST" ]; then
  rm "$PLIST_DST"
  echo "Service uninstalled."
else
  echo "Service was not installed."
fi
