# Architecture

## System Diagram

```
                                    ┌──────────────────────┐
                                    │    OTel Collector     │
                                    │  (otelcol-contrib)    │
┌──────────────┐   OTLP gRPC       │                      │
│  Claude Code  │ ────────────────► │  Receivers:          │
│  (CLI)        │   :4317           │    otlp (gRPC+HTTP)  │
└──────────────┘                    │                      │
                                    │  Pipelines:          │
                                    │  ┌─ metrics ──────► Prometheus :8889 ──► Prometheus :9090
                                    │  │                                            │
                                    │  └─ logs ─────────► otlphttp ──────► Loki :3100
                                    └──────────────────────┘                    │
                                                                                │
                                                                          ┌─────▼──────┐
                                                                          │  Grafana    │
                                                                          │  :3001      │
                                                                          │             │
                                                                          │ Datasources:│
                                                                          │  Prometheus  │
                                                                          │  Loki        │
                                                                          └─────────────┘
```

## Data Flow

### Metrics Pipeline

Counters: cost, tokens, sessions, commits, PRs, lines of code.

1. Claude Code exports metrics via OTLP gRPC to `localhost:4317`
2. OTel Collector re-exports as Prometheus-compatible metrics on `:8889`
3. Prometheus scrapes every 15 seconds, stores with 200h retention
4. Grafana queries Prometheus for the **Overview dashboard**

### Events/Logs Pipeline

Per-prompt, per-tool, per-API-request detail.

1. Claude Code exports events via OTLP gRPC to `localhost:4317`
2. OTel Collector forwards to Loki via OTLP HTTP at `loki:3100/otlp`
3. Loki stores as structured logs with 744h (31 day) retention
4. Grafana queries Loki for the **Deep Dive dashboard**

## Docker Services

| Container | Image | Ports | Purpose |
|-----------|-------|-------|---------|
| `otel-collector` | `otel/opentelemetry-collector-contrib:latest` | 4317, 4318, 8889 | Receives OTLP, routes to Prometheus + Loki |
| `loki` | `grafana/loki:3.4.2` | 3100 | Event/log storage with OTLP ingestion |
| `prometheus` | `prom/prometheus:latest` | 9090 | Time-series metrics, 200h retention |
| `grafana-renderer` | `grafana/grafana-image-renderer:latest` | 8081 (internal) | Server-side PNG rendering for sharing/alerts |
| `grafana` | `grafana/grafana:latest` | 3001 | Dashboards (admin/ClaudeCode2026) |

## Port Map

| Port | Service | Protocol |
|------|---------|----------|
| 4317 | OTel Collector | OTLP gRPC (from Claude Code) |
| 4318 | OTel Collector | OTLP HTTP |
| 8889 | OTel Collector | Prometheus metrics exporter |
| 3100 | Loki | HTTP API + OTLP ingestion |
| 9090 | Prometheus | HTTP API + UI |
| 3001 | Grafana | Web UI |
