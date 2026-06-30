#!/usr/bin/env bash
# Claude Code telemetry hook.
# Invoked from settings.json PreToolUse / PostToolUse with $1 = "pre" | "post".
# Reads hook event JSON from stdin, appends one compact JSON line per call.

event="${1:-unknown}"
log="${HOME}/.claude/audit.jsonl"

jq -c --arg ev "$event" '{
  ts: (now | todate),
  event: $ev,
  session: .session_id,
  cwd: .cwd,
  tool: .tool_name,
  input: (if $ev == "pre" then .tool_input else null end),
  response_summary: (if $ev == "post" then (.tool_response | tostring | .[0:500]) else null end)
}' >> "$log" 2>/dev/null || true
