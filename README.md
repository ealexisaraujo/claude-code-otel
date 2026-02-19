# Claude Code Observability

See exactly what Claude Code is doing — every prompt, tool call, API request, and dollar spent — in beautiful Grafana dashboards.

```
┌──────────────┐   OTLP gRPC    ┌─────────────────┐    ┌────────────┐    ┌──────────┐
│  Claude Code  │ ─────────────► │  OTel Collector  │───►│ Prometheus │───►│          │
│  (your CLI)   │    :4317       │                  │    └────────────┘    │  Grafana │
└──────────────┘                 │                  │    ┌────────────┐    │  :3001   │
                                 │                  │───►│    Loki     │───►│          │
                                 └─────────────────┘    └────────────┘    └──────────┘
```

## Quick Start

**Prerequisites:** [Docker Desktop](https://docs.docker.com/get-docker/) must be installed and running.

```bash
git clone https://github.com/ealexisaraujo/claude-code-otel.git
cd claude-code-otel
./setup.sh
```

That's it. Open a **new terminal**, run `claude`, and watch the data flow into your dashboards.

## What You Get

### Overview Dashboard — Metrics at a Glance

`http://localhost:3001/d/claude-code-personal/`

- Total cost (USD), tokens used, active sessions
- Cost over time by model
- Token usage breakdown (input/output/cache)
- Session activity timeline

### Deep Dive Dashboard — Every Event

`http://localhost:3001/d/claude-code-deep/`

- Full prompt log with actual text content
- Tool usage distribution and execution times
- MCP server and Skills tracking
- API cost per request, response times by model
- Complete session event stream

## How It Works

Claude Code has built-in [OpenTelemetry support](https://docs.claude.com/en/docs/monitoring-usage). When enabled, it exports metrics and events to any OTLP-compatible collector.

This project runs four Docker containers:

| Service | What It Does |
|---------|-------------|
| **OTel Collector** | Receives telemetry from Claude Code and routes it |
| **Prometheus** | Stores metrics (cost, tokens, sessions) |
| **Loki** | Stores events (prompts, tool calls, API requests) |
| **Grafana** | Visualizes everything in two dashboards |
| **Image Renderer** | Enables PNG export and sharing of dashboard panels |

The setup script configures the environment variables that tell Claude Code where to send telemetry.

## Manual Setup

If you prefer to set things up yourself instead of using the setup script:

### 1. Add environment variables

Add these to your `~/.zshrc` (or `~/.bashrc`):

```bash
# Claude Code OpenTelemetry - Observability Stack
export CLAUDE_CODE_ENABLE_TELEMETRY=1
export OTEL_METRICS_EXPORTER=otlp
export OTEL_LOGS_EXPORTER=otlp
export OTEL_EXPORTER_OTLP_PROTOCOL=grpc
export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317
export OTEL_METRIC_EXPORT_INTERVAL=60000
export OTEL_LOGS_EXPORT_INTERVAL=5000
export OTEL_METRICS_INCLUDE_SESSION_ID=true
export OTEL_METRICS_INCLUDE_ACCOUNT_UUID=true
export OTEL_LOG_TOOL_DETAILS=1
export OTEL_LOG_USER_PROMPTS=1
```

### 2. Start the stack

```bash
docker compose up -d
```

### 3. Open a new terminal and start Claude Code

```bash
claude
```

Environment variables are read at Claude Code startup, so you need a fresh terminal.

## Usage

```bash
# Start the stack
docker compose up -d

# Stop (keeps your data)
docker compose stop

# View container status
docker compose ps

# View collector logs (see telemetry arriving)
docker logs otel-collector --tail 20 -f
```

### Grafana Access

| | |
|---|---|
| **URL** | http://localhost:3001 |
| **Username** | `admin` |
| **Password** | `ClaudeCode2026` |

## Ports

| Port | Service |
|------|---------|
| 3001 | Grafana (dashboards) |
| 4317 | OTel Collector (OTLP gRPC — Claude Code sends here) |
| 4318 | OTel Collector (OTLP HTTP) |
| 8889 | OTel Collector (Prometheus exporter) |
| 9090 | Prometheus |
| 3100 | Loki |

## Troubleshooting

### Dashboards show "No data"

**Most common cause:** Claude Code was started before the environment variables were set.

1. Verify the env vars are active: `echo $CLAUDE_CODE_ENABLE_TELEMETRY` should print `1`
2. If not, open a **new terminal** (to pick up the env vars) and restart Claude Code
3. Check containers are running: `docker compose ps` — all 4 should show "Up"

### Overview dashboard works but Deep Dive is empty

- Check `echo $OTEL_LOGS_EXPORTER` — should print `otlp`
- Check Loki is healthy: `curl http://localhost:3100/ready`

### MCP/Skills panels are empty

- Check `echo $OTEL_LOG_TOOL_DETAILS` — should print `1`
- Without this, MCP server names and skill names are redacted from events

### Data appears with a delay

- Metrics export every 60 seconds (`OTEL_METRIC_EXPORT_INTERVAL`)
- Events export every 5 seconds (`OTEL_LOGS_EXPORT_INTERVAL`)
- After starting Claude Code, wait ~60s for the first metrics to appear

## Uninstall

```bash
# Stop and remove containers + data
docker compose down -v

# Remove environment variables: delete the "Claude Code OpenTelemetry" block from ~/.zshrc
```

## Data Retention

- **Prometheus metrics:** 200 hours (~8 days)
- **Loki events:** 744 hours (31 days)
- **Data persists** across container restarts. Only `docker compose down -v` deletes data.

## Claude Code Event Types

| Event | When | Key Data |
|-------|------|----------|
| `user_prompt` | You send a prompt | Prompt text, length |
| `tool_result` | A tool finishes | Tool name, success, duration, MCP server |
| `api_request` | API call completes | Model, cost, tokens, response time |
| `api_error` | API call fails | Error, status code, retry attempt |
| `tool_decision` | Tool accepted/rejected | Tool name, decision, source |

## References

- [Claude Code Monitoring Docs](https://docs.claude.com/en/docs/monitoring-usage)
- [Claude Code Monitoring Guide](https://github.com/anthropics/claude-code-monitoring-guide)
- [OpenTelemetry Collector Contrib](https://github.com/open-telemetry/opentelemetry-collector-contrib)
- [Loki OTLP Ingestion](https://grafana.com/docs/loki/latest/send-data/otel/)

## License

MIT
