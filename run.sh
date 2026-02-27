#!/bin/bash
# Run OTEL collector - sends Mac metrics to Coralogix

set -e
cd "$(dirname "$0")"

if [ -z "$CORALOGIX_PRIVATE_KEY" ]; then
  echo "Error: Set CORALOGIX_PRIVATE_KEY environment variable"
  echo "  export CORALOGIX_PRIVATE_KEY=\"your_send_your_data_api_key\""
  exit 1
fi

# Binary name (extracted from tarball - same for both architectures)
BINARY="otelcol-contrib"

if [ ! -f "./$BINARY" ]; then
  ARCH=$(uname -m)
  echo "Downloading otelcol-contrib..."
  VERSION="0.112.0"
  if [ "$ARCH" = "arm64" ]; then
    curl -L -o otelcol-contrib.tar.gz "https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v${VERSION}/otelcol-contrib_${VERSION}_darwin_arm64.tar.gz"
  else
    curl -L -o otelcol-contrib.tar.gz "https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v${VERSION}/otelcol-contrib_${VERSION}_darwin_amd64.tar.gz"
  fi
  tar -xzf otelcol-contrib.tar.gz
fi

echo "Starting OTEL collector (metrics → Coralogix)..."
./$BINARY --config config.yaml
