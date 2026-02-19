# Claude Code Event Schema

## Event Types

| Event | Trigger | Key Attributes |
|-------|---------|---------------|
| `user_prompt` | User submits prompt | `prompt_length`, `prompt` (if OTEL_LOG_USER_PROMPTS=1), `prompt.id` |
| `tool_result` | Tool finishes executing | `tool_name`, `success`, `duration_ms`, `tool_result_size_bytes`, `mcp_server_scope`, `tool_parameters` |
| `api_request` | API call completes | `model`, `cost_usd`, `duration_ms`, `input_tokens`, `output_tokens`, `cache_read_tokens`, `cache_creation_tokens`, `speed` |
| `api_error` | API call fails | `model`, `error`, `status_code`, `attempt`, `duration_ms`, `speed` |
| `tool_decision` | Accept/reject tool | `tool_name`, `decision`, `source` |

## Shared Attributes (all events)

| Attribute | Description |
|-----------|-------------|
| `prompt.id` | UUID linking all events from the same user prompt |
| `session.id` | UUID for the Claude Code session |
| `event.sequence` | Monotonic integer for ordering events within a session |
| `event.name` | Event type (see table above) |
| `event.timestamp` | ISO 8601 timestamp |

## Resource Attributes (attached to all telemetry)

| Attribute | Example |
|-----------|---------|
| `service.name` | `claude-code` |
| `service.version` | `2.1.47` |
| `user.id` | SHA256 hash |
| `user.email` | User email |
| `user.account_uuid` | Account UUID |
| `organization.id` | Org UUID |
| `terminal.type` | `ghostty`, `iterm2`, etc. |
| `host.arch` | `arm64` |
| `os.type` | `darwin` |
| `os.version` | `25.3.0` |

## Tool Result Details

When `OTEL_LOG_TOOL_DETAILS=1` is set, the `tool_parameters` attribute contains a JSON object with:

| Field | Present When |
|-------|-------------|
| `mcp_server_name` | Tool is from an MCP server |
| `mcp_tool_name` | Tool is from an MCP server |
| `skill_name` | Tool is a Skill invocation |
| `bash_command` | Tool is Bash (first word of command) |
| `full_command` | Tool is Bash (full command text) |
| `description` | Tool is Bash (command description) |

## Correlation

Events within the same prompt share a `prompt.id`, enabling correlation of the full execution chain:
1. `user_prompt` — the user's input
2. `tool_decision` — accept/reject for each tool
3. `tool_result` — execution result for each tool
4. `api_request` / `api_error` — LLM API calls made during processing
