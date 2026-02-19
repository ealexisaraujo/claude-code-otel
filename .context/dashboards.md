# Grafana Dashboards

## Dashboard 1: Overview (Prometheus)

**UID:** `claude-code-personal`
**URL:** http://localhost:3001/d/claude-code-personal/claude-code-personal-observability
**Datasource:** Prometheus
**Panels:** 25

### Row: Overview (6 stat panels)

Total Cost, Sessions, Tokens, Lines of Code, Commits, Pull Requests

### Row: Cost & Token Analysis (5 panels)

- Cost Over Time by Model (stacked bar)
- Token Usage Over Time by Type (line)
- Cost Distribution by Model (donut pie)
- Token Distribution by Type (donut pie)
- Lines of Code Added vs Removed (donut pie)
- **Output Tokens by Model** (donut pie) — shows which model tier generates most output
- **Output Tokens Over Time by Model** (stacked bar) — model usage patterns

### Row: Productivity & Activity (4 panels)

- Activity Over Time (Sessions, Commits, PRs)
- Lines of Code Over Time (Added/Removed)
- Active Time (User vs CLI)
- Code Edit Decisions (Accept/Reject)

### Row: Detailed Tables (4 panels)

- Cost Breakdown by Model (table)
- Token Usage by Type & Model (table)
- Cost by Session (table)
- Edit Tool Decisions by Tool & Decision (table)

## Dashboard 2: Deep Dive (Loki)

**UID:** `claude-code-deep`
**URL:** http://localhost:3001/d/claude-code-deep/claude-code-deep-dive-prompts-tools-mcps-skills
**Datasource:** Loki
**Panels:** 38

### Row: Prompt Intelligence (9 panels)

- **Total Prompts** (stat) — `count_over_time({service_name="claude-code"} | event_name="user_prompt" [$__range])`
- **Total Tool Calls** (stat)
- **Total API Requests** (stat)
- **API Errors** (stat) — red threshold at >= 1
- **Failed Tool Calls** (stat)
- **Rejected Tools** (stat)
- **All Events Over Time** (stacked bar by event_name)
- **Prompts Over Time** (bar chart)
- **Prompt Log** (logs panel) — shows actual prompt text with session ID

### Row: Model & Effort Analysis (7 panels)

Tracks which model tiers and speed modes are used. Reasoning effort level is not directly exported by Claude Code telemetry — output tokens serve as the best available proxy (higher output tokens correlate with extended thinking/higher effort).

- **API Requests by Model** (donut pie) — count of requests per model (opus/sonnet/haiku)
- **Cost Distribution by Model** (donut pie) — where the money goes
- **Speed Mode (Normal vs Fast)** (donut pie) — normal vs `/fast` mode usage
- **Model Usage Over Time** (stacked bar) — model tier trends
- **Avg Output Tokens by Model (Effort Proxy)** (line chart) — higher = more thinking/effort
- **Model Usage per Session** (table) — per-session breakdown: model, requests, cost, avg duration

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

All queries use `{service_name="claude-code"}` as the stream selector. No `| json` needed — OTLP attributes are stored as structured metadata.

| Pattern | Purpose |
|---------|---------|
| `{service_name="claude-code"} \| event_name="user_prompt"` | Select prompt events |
| `{service_name="claude-code"} \| event_name="tool_result"` | Select tool execution events |
| `{service_name="claude-code"} \| event_name="api_request"` | Select API call events |
| `{service_name="claude-code"} \| event_name="api_error"` | Select API error events |
| `{service_name="claude-code"} \| event_name="tool_result" \| mcp_server_scope!=""` | MCP tool calls only |
| `{service_name="claude-code"} \| event_name="tool_result" \| tool_name="Skill"` | Skill invocations only |
| `\| unwrap duration_ms` | Extract numeric field for aggregation (avg, sum, quantile) |
| `\| unwrap cost_usd` | Extract cost for per-model aggregation |
| `\| unwrap output_tokens` | Extract output tokens as effort proxy |
| `\| line_format "..."` | Format log lines with Go template syntax |

## Model & Effort Tracking Notes

Claude Code telemetry provides these effort-related attributes:

| Attribute | Values | What It Tracks |
|-----------|--------|---------------|
| `model` | `claude-opus-4-6`, `claude-haiku-4-5-20251001`, etc. | Model tier selection |
| `speed` | `normal`, `fast` | Normal vs `/fast` mode |
| `output_tokens` | integer | Proxy for reasoning effort (more tokens = more thinking) |

**Not tracked:** The reasoning effort bar level (low/medium/high) is not currently exported in Claude Code's OTLP telemetry. The `output_tokens` metric serves as the best available proxy.
