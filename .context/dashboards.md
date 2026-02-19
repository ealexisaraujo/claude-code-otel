# Grafana Dashboards

## Dashboard 1: Overview (Prometheus)

**UID:** `claude-code-personal`
**URL:** http://localhost:3001/d/claude-code-personal/claude-code-personal-observability
**Datasource:** Prometheus
**Panels:** 23 (stat counters, cost/token time series, pie charts, tables)

## Dashboard 2: Deep Dive (Loki)

**UID:** `claude-code-deep`
**URL:** http://localhost:3001/d/claude-code-deep/claude-code-deep-dive-prompts-tools-mcps-skills
**Datasource:** Loki
**Panels:** 31

### Row: Prompt Intelligence (8 panels)

- **Total Prompts** (stat) — `count_over_time({service_name="claude-code"} | json | event_name="user_prompt" [$__range])`
- **Total Tool Calls** (stat)
- **Total API Requests** (stat)
- **API Errors** (stat) — red threshold at >= 1
- **Failed Tool Calls** (stat)
- **Rejected Tools** (stat)
- **All Events Over Time** (stacked bar by event_name)
- **Prompts Over Time** (bar chart)
- **Prompt Log** (logs panel) — shows actual prompt text with session ID

### Row: Tool Usage Deep Dive (6 panels)

- **Tool Usage Distribution** (donut pie by tool_name)
- **Successful Tool Calls by Tool** (donut pie)
- **Tool Decisions Accept/Reject** (donut pie)
- **Tool Calls Over Time by Tool** (stacked bar)
- **Avg Tool Duration Over Time** (line chart, ms) — uses `unwrap duration_ms`
- **Tool Execution Log** (logs panel) — tool_name, success, duration, size, decision

### Row: MCP Servers & Skills (4 panels)

- **MCP Server Usage by scope** (donut pie) — filters `mcp_server_scope!=""`
- **MCP Server Calls Over Time** (bar chart)
- **MCP Tool Calls Log** (logs) — MCP scope, tool name, params, duration
- **Skills Invocation Log** (logs) — filters `tool_name="Skill"`, shows skill params

### Row: API Performance & Cost per Request (6 panels)

- **Cost per API Request by Model** (scatter plot, USD)
- **Avg API Response Time by Model** (line chart, ms)
- **Input/Output Tokens per API Request** (stacked bar)
- **Fast vs Normal Mode** (donut pie by speed attribute)
- **API Requests Log** (logs) — model, cost, duration, tokens, speed
- **API Errors Log** (logs) — model, status_code, attempt, error message

### Row: Session Trace (1 panel)

- **Full Event Stream** (logs) — all events with formatted line showing event_name, session, prompt_id, tool, model, cost, duration

## LogQL Query Patterns

All queries use `{service_name="claude-code"}` as the stream selector, then `| json` to parse structured metadata.

| Pattern | Purpose |
|---------|---------|
| `{service_name="claude-code"} \| event_name="user_prompt"` | Select prompt events |
| `{service_name="claude-code"} \| event_name="tool_result"` | Select tool execution events |
| `{service_name="claude-code"} \| event_name="api_request"` | Select API call events |
| `{service_name="claude-code"} \| event_name="api_error"` | Select API error events |
| `{service_name="claude-code"} \| event_name="tool_result" \| mcp_server_scope!=""` | MCP tool calls only |
| `{service_name="claude-code"} \| event_name="tool_result" \| tool_name="Skill"` | Skill invocations only |
| `\| unwrap duration_ms` | Extract numeric field for aggregation (avg, sum, quantile) |
| `\| line_format "..."` | Format log lines with Go template syntax |
