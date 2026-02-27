#!/usr/bin/env bash
# Create MacBook Host Metrics dashboard in Coralogix via API
#
# Usage:
#   export CORALOGIX_API_KEY="your-api-key"   # needs team-dashboards:Write
#   ./create-dashboard.sh
#
# Or with region override (default: eu2):
#   CORALOGIX_REGION=us ./create-dashboard.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DASHBOARD_JSON="${SCRIPT_DIR}/dashboard-macbook-metrics.json"
REGION="${CORALOGIX_REGION:-eu2}"
API_BASE="https://api.${REGION}.coralogix.com/mgmt/openapi/latest/v1"

if [[ -z "${CORALOGIX_API_KEY}" ]]; then
  echo "Error: CORALOGIX_API_KEY is not set"
  echo "Usage: export CORALOGIX_API_KEY=\"your-api-key\" && ./create-dashboard.sh"
  exit 1
fi

if [[ ! -f "${DASHBOARD_JSON}" ]]; then
  echo "Error: dashboard-macbook-metrics.json not found"
  exit 1
fi

# Build request: { requestId, dashboard }
REQUEST=$(jq -n \
  --slurpfile d "${DASHBOARD_JSON}" \
  '{ requestId: (now | tostring), dashboard: $d[0] }')

echo "Creating dashboard via API (region: ${REGION})..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "${API_BASE}/dashboards/dashboards" \
  -H "Authorization: Bearer ${CORALOGIX_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "${REQUEST}")

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
HTTP_BODY=$(echo "$RESPONSE" | sed '$d')

if [[ "${HTTP_CODE}" == "200" ]]; then
  DASHBOARD_ID=$(echo "${HTTP_BODY}" | jq -r '.dashboardId')
  echo "Dashboard created successfully!"
  echo "Dashboard ID: ${DASHBOARD_ID}"
  echo "URL: https://kenan-lab.app.${REGION}.coralogix.com/#/dashboards/${DASHBOARD_ID}"
else
  echo "Error: API returned HTTP ${HTTP_CODE}"
  echo "Response:"
  echo "${HTTP_BODY}" | jq . 2>/dev/null || echo "${HTTP_BODY}"
  exit 1
fi
