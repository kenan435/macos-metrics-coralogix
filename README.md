# Local OTEL Collector → Coralogix

Send your Mac's host metrics to Coralogix UI.

## Prerequisites

- **Send-Your-Data API Key** from Coralogix (Data Flow → API Keys → Send-Your-Data)
- **otelcol-contrib** binary (includes Coralogix exporter)

## Setup

### 1. Download otelcol-contrib

```bash
cd otel-collector

# Apple Silicon (M1/M2/M3)
curl -L -o otelcol-contrib.tar.gz https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v0.112.0/otelcol-contrib_0.112.0_darwin_arm64.tar.gz

# Intel Mac - use this instead:
# curl -L -o otelcol-contrib.tar.gz https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v0.112.0/otelcol-contrib_0.112.0_darwin_amd64.tar.gz

tar -xzf otelcol-contrib.tar.gz
```

### 2. Set your API key

```bash
export CORALOGIX_PRIVATE_KEY="your_send_your_data_api_key"
```

### 3. Run the collector

```bash
./run.sh
```

## View in Coralogix

- **Explore** → **Metrics** → filter by `applicationname: macbook` and `subsystemname: host-metrics`
- **Custom Dashboard** → see [DASHBOARD_SETUP.md](./DASHBOARD_SETUP.md) for step-by-step instructions

## Metrics Collected

| Scraper    | Metrics                          |
|-----------|-----------------------------------|
| load      | CPU load averages                |
| memory    | Memory usage, available          |
| network   | Bytes in/out, packets            |
| filesystem| Disk usage per mount             |
| paging    | Paging/swapping activity         |

## Run in Background

```bash
nohup ./otelcol-contrib --config config.yaml > collector.log 2>&1 &
```

## Stop

```bash
pkill -f otelcol-contrib
```
