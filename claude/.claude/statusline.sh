#!/usr/bin/env bash
# Claude Code status line.
# Reads session info JSON from stdin, prints one line to stdout.
# Shows: model | current context tokens (% of window) | cumulative session cost.

input=$(cat)
model=$(jq -r '.model.display_name // "claude"' <<<"$input")
transcript=$(jq -r '.transcript_path // ""' <<<"$input")
cost=$(jq -r '.cost.total_cost_usd // 0' <<<"$input")
cwd=$(jq -r '.workspace.current_dir // .cwd // ""' <<<"$input")

# Pull last assistant usage from transcript to approximate current context size.
context=0
if [[ -f "$transcript" ]]; then
  last=$(grep '"type":"assistant"' "$transcript" | tail -1)
  if [[ -n "$last" ]]; then
    u=$(jq -c '.message.usage // empty' <<<"$last" 2>/dev/null)
    if [[ -n "$u" ]]; then
      it=$(jq -r '.input_tokens // 0' <<<"$u")
      cr=$(jq -r '.cache_read_input_tokens // 0' <<<"$u")
      cc=$(jq -r '.cache_creation_input_tokens // 0' <<<"$u")
      context=$((it + cr + cc))
    fi
  fi
fi

# Estimate context window limit from model name.
limit=200000
[[ "$model" == *"1M"* ]] && limit=1000000
pct=0
[[ $limit -gt 0 ]] && pct=$((context * 100 / limit))

# Short cwd: basename only.
short_cwd=$(basename "$cwd" 2>/dev/null)

printf '%s │ %s │ %dk (%d%%) │ $%.3f' \
  "$model" "$short_cwd" $((context / 1000)) "$pct" "$cost"
