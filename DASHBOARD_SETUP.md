# MacBook Metrics Dashboard Setup

Create a Custom Dashboard in Coralogix to visualize your Mac's host metrics.

## Option 1: Import JSON (try first)

1. Go to **Dashboards** → **Custom Dashboards**
2. Hover over **+ New Dashboard** → click **Import**
3. Open `dashboard-macbook-metrics.json` (or paste its contents)
4. Click **Import**

If import fails with "invalid dashboard", use Option 2 (manual) or Option 3 (API).

---

## Option 2: Create Manually

1. Go to **Dashboards** → **Custom Dashboards**
2. Click **+ New Dashboard**
3. Name it: **MacBook Host Metrics**
4. Set time range to **Last 1 hour**
5. Add the widgets below (click **+** then drag **Line Chart** from the left sidebar)
6. For each widget: open Query Builder → switch to **Query mode** → paste the PromQL

---

## Widget 1: CPU Load Average

- **Widget type**: Line Chart
- **Query** (Query mode / PromQL):

```
avg(system_cpu_load_average_1m__thread_{cx_application_name="macbook"})
```

- **Legend**: Load 1m
- **Time bucket**: Auto

---

## Widget 2: Memory Usage (GB)

- **Widget type**: Line Chart
- **Query**:

```
sum(system_memory_usage_By{cx_application_name="macbook"}) / 1024 / 1024 / 1024
```

- **Legend**: Memory GB
- **Units**: bytes (or leave default)

---

## Widget 3: Network I/O (bytes/sec)

- **Widget type**: Line Chart
- **Query**:

```
rate(system_network_io_By_total{cx_application_name="macbook"}[5m])
```

- **Legend**: Network I/O
- **Time bucket**: Auto

---

## Widget 4: Disk Usage (GB)

- **Widget type**: Line Chart
- **Query**:

```
system_filesystem_usage_By{cx_application_name="macbook"} / 1024 / 1024 / 1024
```

- **Legend**: Disk GB
- **Group by**: `mount_point` or `device` (to see per-filesystem)

---

## Widget 5: Paging Activity (optional)

- **Widget type**: Line Chart
- **Query**:

```
rate(system_paging_faults__faults__total{cx_application_name="macbook"}[5m])
```

- **Legend**: Page Faults/sec

---

## Layout Suggestion

| Row 1 | CPU Load (full width) |
|-------|------------------------|
| Row 2 | Memory Usage (full width) |
| Row 3 | Network I/O | Disk Usage |
| Row 4 | Paging (optional) |

---

## Time Range

Set dashboard time range to **Last 1 hour** or **Last 6 hours** to see your Mac data.

---

## Option 3: Create via API

If UI import fails, create the dashboard via API:

```bash
# Set your Coralogix API key (needs team-dashboards:Write permission)
export CORALOGIX_API_KEY="your-api-key"

# Build request payload (requires jq)
jq -n --slurpfile d dashboard-macbook-metrics.json '{requestId: (now|tostring), dashboard: $d[0]}' > /tmp/dashboard-request.json

# Create dashboard (EU2 region - adjust URL for your region)
curl -X POST "https://api.eu2.coralogix.com/mgmt/openapi/latest/dashboards/dashboards" \
  -H "Authorization: Bearer $CORALOGIX_API_KEY" \
  -H "Content-Type: application/json" \
  -d @/tmp/dashboard-request.json
```

---

## Troubleshooting

- **No data?** Ensure the OTEL collector is running (`./run.sh`)
- **Wrong data?** Add filter: `deployment_environment_name="local-mac"`
- **Empty chart?** Check that `cx_application_name="macbook"` matches your collector config
