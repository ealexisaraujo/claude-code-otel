# References

## Official Documentation

- [Claude Code Monitoring Usage](https://code.claude.com/docs/en/monitoring-usage) — official telemetry docs
- [Claude Code Monitoring Guide](https://github.com/anthropics/claude-code-monitoring-guide) — reference implementation

## Upstream Components

- [OpenTelemetry Collector Contrib](https://github.com/open-telemetry/opentelemetry-collector-contrib) — otelcol-contrib image
- [Loki OTLP Ingestion](https://grafana.com/docs/loki/latest/send-data/otel/) — Loki's native OTLP support
- [Prometheus](https://prometheus.io/docs/) — metrics storage
- [Grafana](https://grafana.com/docs/grafana/latest/) — visualization

## Relevant OTel Specs

- [OTLP Protocol](https://opentelemetry.io/docs/specs/otlp/) — gRPC and HTTP transport
- [OTel SDK Configuration](https://opentelemetry.io/docs/specs/otel/configuration/sdk-environment-variables/) — env var reference
