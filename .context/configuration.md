# Configuration

## Environment Variables

Added to `~/.zshrc` — Claude Code reads these at startup. **Restart terminal + Claude Code after changes.**

```bash
# Claude Code OpenTelemetry - Personal Observability
export CLAUDE_CODE_ENABLE_TELEMETRY=1
export OTEL_METRICS_EXPORTER=otlp
export OTEL_LOGS_EXPORTER=otlp
export OTEL_EXPORTER_OTLP_PROTOCOL=grpc
export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317
export OTEL_METRIC_EXPORT_INTERVAL=60000    # 60s default
export OTEL_LOGS_EXPORT_INTERVAL=5000       # 5s default
export OTEL_METRICS_INCLUDE_SESSION_ID=true
export OTEL_METRICS_INCLUDE_ACCOUNT_UUID=true
export OTEL_LOG_TOOL_DETAILS=1              # MCP server/tool names + skill names in events
export OTEL_LOG_USER_PROMPTS=1              # Actual prompt content in events
```

### Key Env Vars for Deep Observability

| Variable | Why It Matters |
|----------|---------------|
| `OTEL_LOG_TOOL_DETAILS=1` | Without this, `mcp_server_name`, `mcp_tool_name`, and `skill_name` are **redacted** from tool_result events. Required for MCP & Skills dashboard panels. |
| `OTEL_LOG_USER_PROMPTS=1` | Without this, only `prompt_length` is recorded. With it, actual prompt text appears in the Prompt Log panel. |
| `OTEL_LOGS_EXPORTER=otlp` | Enables the events/logs pipeline. Without it, only metrics (counters) are exported. |
| `CLAUDE_CODE_ENABLE_TELEMETRY=1` | Master switch — nothing is exported without this. |

## OTel Collector Config

File: `otel-collector-config.yaml`

### Two Pipelines

```yaml
service:
  pipelines:
    metrics:                              # cost, tokens, sessions, LOC, commits, PRs
      receivers: [otlp]
      processors: [memory_limiter, batch]
      exporters: [prometheus, debug]

    logs:                                 # prompts, tool calls, API requests, errors, decisions
      receivers: [otlp]
      processors: [memory_limiter, batch]
      exporters: [otlphttp/loki, debug]
```

### Key Config Decisions

- **`resource_to_telemetry_conversion: enabled: true`** on Prometheus exporter — promotes OTel resource attributes into Prometheus labels
- **`otlphttp/loki` exporter** — sends events to Loki's native OTLP endpoint (`http://loki:3100/otlp`)
- **`debug` exporter** — logs incoming data to container logs for troubleshooting

## Loki Config

File: `loki-config.yaml`

- **Schema v13 with TSDB** — latest Loki schema for efficient storage
- **`allow_structured_metadata: true`** — enables OTel attributes as structured metadata (queryable without JSON parsing)
- **`otlp_config.resource_attributes`** — indexes `service.name` as a label for efficient stream selection
- **`retention_period: 744h`** (31 days) — auto-cleanup of old events
- **`delete_request_store: filesystem`** — required for retention to work in Loki 3.x

## Prometheus Config

File: `prometheus.yml`

- Scrapes `otel-collector:8889` every 15 seconds
- 200h retention (configured in docker-compose.yml `--storage.tsdb.retention.time`)

## Grafana Provisioning

- **Datasource UIDs:** Prometheus=`PBFA97CFB590B2093`, Loki=`loki-datasource`
- **Dashboard provisioning:** `allowUiUpdates: true` — edits in Grafana UI persist until container restart
- **Datasources file:** `grafana/provisioning/datasources/datasources.yaml`
- **Dashboards config:** `grafana/provisioning/dashboards/dashboards.yaml`
