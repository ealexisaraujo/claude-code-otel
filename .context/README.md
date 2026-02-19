# Context Engineering - Claude Code OpenTelemetry

Self-hosted observability stack for Claude Code CLI sessions. Captures metrics (cost, tokens, sessions) and events (prompts, tool calls, API requests) via OpenTelemetry, stores in Prometheus and Loki, visualizes in Grafana.

## Document Index

| Document | Purpose |
|----------|---------|
| [architecture.md](architecture.md) | System diagram, data flow, Docker services, port map |
| [configuration.md](configuration.md) | OTel Collector pipelines, Loki/Prometheus config, env vars |
| [dashboards.md](dashboards.md) | Grafana dashboard panels, LogQL query patterns |
| [events-schema.md](events-schema.md) | Claude Code event types, attributes, correlation IDs |
| [operations.md](operations.md) | Start/stop commands, debugging, troubleshooting playbook |
| [references.md](references.md) | Official docs, upstream repos, related resources |

## Quick Reference

- **Grafana:** http://localhost:3001 (admin / ClaudeCode2026)
- **Overview dashboard:** `/d/claude-code-personal/`
- **Deep Dive dashboard:** `/d/claude-code-deep/`
- **Prometheus:** http://localhost:9090
- **Loki:** http://localhost:3100

## File Layout (repo root)

```
claude-code-otel/
├── docker-compose.yml                        # 4 services: loki, otel-collector, prometheus, grafana
├── otel-collector-config.yaml                # OTLP receivers, two pipelines
├── prometheus.yml                            # Scrape config targeting otel-collector:8889
├── loki-config.yaml                          # Loki 3.4 with OTLP + structured metadata
├── CLAUDE.md                                 # Claude Code project instructions
├── .context/                                 # Context engineering documents (this folder)
│   ├── README.md                             # This index
│   ├── architecture.md
│   ├── configuration.md
│   ├── dashboards.md
│   ├── events-schema.md
│   ├── operations.md
│   └── references.md
└── grafana/
    ├── dashboards/
    │   ├── claude-code-dashboard.json        # Overview (Prometheus metrics)
    │   └── claude-code-deep-dashboard.json   # Deep Dive (Loki events)
    └── provisioning/
        ├── dashboards/dashboards.yaml
        └── datasources/datasources.yaml
```
