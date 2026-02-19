# Operations

## Start / Stop

```bash
# Start all services
docker compose up -d

# Stop (preserves data volumes)
docker compose stop

# Full teardown including data
docker compose down -v
```

## Debugging

```bash
# Watch incoming telemetry in real time
docker logs otel-collector --tail 50 -f

# Check Loki health
docker logs loki --tail 20
curl http://localhost:3100/ready

# Check all containers are running
docker compose ps

# Query Prometheus for Claude Code metrics
curl -s -G 'http://localhost:9090/api/v1/query' --data-urlencode 'query={__name__=~"claude_code.*"}'

# Query Loki for recent events
curl -s -G 'http://localhost:3100/loki/api/v1/query_range' \
  --data-urlencode 'query={service_name="claude-code"}' \
  --data-urlencode 'limit=5' \
  --data-urlencode "start=$(date -v-1H +%s)" \
  --data-urlencode "end=$(date +%s)"

# Check Loki labels
curl -s 'http://localhost:3100/loki/api/v1/labels'
```

## Troubleshooting Playbook

### No data in either dashboard

1. **Most common:** Claude Code was started before env vars were set. Open a **new terminal** and run `claude` again.
2. Verify: `echo $CLAUDE_CODE_ENABLE_TELEMETRY` should print `1`
3. Check Docker: `docker compose ps` — all 4 should be Up
4. Check collector is receiving data: `docker logs otel-collector --tail 10`

### Metrics dashboard has data but Deep Dive is empty

- Verify `OTEL_LOGS_EXPORTER=otlp` is set (events pipeline)
- Check collector logs: `docker logs otel-collector --tail 20` — look for log export entries
- Verify Loki is ready: `curl http://localhost:3100/ready`

### MCP/Skills panels are empty

- Verify `OTEL_LOG_TOOL_DETAILS=1` is set — without it, MCP server names and skill names are redacted

### Prompt Log shows no text content

- Verify `OTEL_LOG_USER_PROMPTS=1` is set — without it, only prompt_length is recorded

### Metrics appear delayed

- `OTEL_METRIC_EXPORT_INTERVAL=60000` means metrics export every 60s
- Prometheus scrapes every 15s
- Combined worst-case delay: ~75 seconds

### Events appear delayed

- `OTEL_LOGS_EXPORT_INTERVAL=5000` means events export every 5s
- Loki ingestion is near-instant after receipt
