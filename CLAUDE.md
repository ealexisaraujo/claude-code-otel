# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Self-hosted observability stack for Claude Code CLI sessions. Captures metrics (cost, tokens, sessions) and events (prompts, tool calls, API requests) via OpenTelemetry, stores them in Prometheus and Loki, and visualizes in Grafana dashboards. Designed for personal/single-user macOS usage.

## Architecture

Claude Code exports OTLP gRPC to `localhost:4317`. Two pipelines flow through the OTel Collector:
- **Metrics pipeline:** OTel Collector -> Prometheus exporter (`:8889`) -> Prometheus (`:9090`) -> Grafana
- **Events/logs pipeline:** OTel Collector -> OTLP HTTP -> Loki (`:3100`) -> Grafana

Five Docker containers: `otel-collector` (otelcol-contrib), `loki` (3.4.2), `prometheus`, `grafana` (on `:3001`), `grafana-renderer` (image rendering).

## Commands

```bash
# Start all services
docker compose up -d

# Stop (preserves data volumes)
docker compose stop

# Full teardown including data
docker compose down -v

# Debug incoming telemetry
docker logs otel-collector --tail 50 -f
docker logs loki --tail 20

# Check Loki readiness
curl http://localhost:3100/ready
```

## Key URLs

- Grafana: `http://localhost:3001` (admin / ClaudeCode2026)
- Overview dashboard: `/d/claude-code-personal/`
- Deep Dive dashboard: `/d/claude-code-deep/`
- Prometheus: `http://localhost:9090`

## Required Environment Variables

These must be set in `~/.zshrc` and Claude Code must be restarted in a new terminal after changes:

```bash
export CLAUDE_CODE_ENABLE_TELEMETRY=1
export OTEL_METRICS_EXPORTER=otlp
export OTEL_LOGS_EXPORTER=otlp
export OTEL_EXPORTER_OTLP_PROTOCOL=grpc
export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317
export OTEL_LOG_TOOL_DETAILS=1       # Enables MCP/skill names in events
export OTEL_LOG_USER_PROMPTS=1       # Enables prompt content in events
```

## File Layout

- `docker-compose.yml` — Service definitions and volume mounts
- `otel-collector-config.yaml` — OTLP receivers, two pipelines (metrics->Prometheus, logs->Loki), debug exporter
- `prometheus.yml` — Scrape config targeting `otel-collector:8889` every 15s
- `loki-config.yaml` — Schema v13/TSDB, OTLP structured metadata, 31-day retention
- `grafana/dashboards/*.json` — Two provisioned dashboards (Overview via Prometheus, Deep Dive via Loki)
- `grafana/provisioning/` — Datasource and dashboard provisioning configs
- `.context/` — Context engineering documents (see `.context/README.md` for index)
  - `architecture.md` — System diagram, data flow, Docker services
  - `configuration.md` — OTel Collector, Loki, Prometheus config, env vars
  - `dashboards.md` — Grafana panels, LogQL query patterns
  - `events-schema.md` — Event types, attributes, correlation model
  - `operations.md` — Start/stop, debugging, troubleshooting playbook
  - `references.md` — Official docs, upstream repos

## Key Config Details

- OTel Collector uses `resource_to_telemetry_conversion: enabled: true` to promote resource attributes into Prometheus labels
- Loki indexes `service.name` as a label via `otlp_config.resource_attributes`
- All Loki queries use stream selector `{service_name="claude-code"}` then filter by `event_name` (no `| json` needed — OTLP attributes are stored as structured metadata)
- Grafana datasource UIDs: Prometheus=`PBFA97CFB590B2093`, Loki=`loki-datasource` (referenced in dashboard JSON)
- Dashboard provisioning uses `allowUiUpdates: true` — edits in Grafana UI persist until container restart

## Claude Code Event Types

| Event | Key Attributes |
|-------|---------------|
| `user_prompt` | `prompt_length`, `prompt`, `prompt.id` |
| `tool_result` | `tool_name`, `success`, `duration_ms`, `mcp_server_scope`, `tool_parameters` |
| `api_request` | `model`, `cost_usd`, `duration_ms`, `input_tokens`, `output_tokens`, `speed` |
| `api_error` | `model`, `error`, `status_code`, `attempt` |
| `tool_decision` | `tool_name`, `decision`, `source` |

All events share `prompt.id`, `session.id`, and `event.sequence`.
