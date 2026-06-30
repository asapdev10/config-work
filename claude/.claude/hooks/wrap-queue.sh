#!/usr/bin/env bash
# SessionEnd hook: append the just-ended session to the wrap ledger as `pending`
# so /catchup can review it later. This is the "never forget to run /wrap" half:
# detection is automatic and free; the interactive review stays in /catchup.
#
# Ledger lives at ~/.claude/wrap-ledger.json (state, not config — not stowed):
#   { "<session_id>": { transcript, cwd, ended_at, status } }
#
# Skips trivially short transcripts.
set -euo pipefail

ledger="$HOME/.claude/wrap-ledger.json"

payload="$(cat)"
sid="$(printf '%s' "$payload"        | jq -r '.session_id // empty')"
transcript="$(printf '%s' "$payload" | jq -r '.transcript_path // empty')"
cwd="$(printf '%s' "$payload"        | jq -r '.cwd // empty')"

[[ -z "$sid" || -z "$transcript" ]] && exit 0

# Skip transcripts that don't exist or are basically empty (trivial sessions).
[[ -f "$transcript" ]] || exit 0
size="$(wc -c < "$transcript" 2>/dev/null || echo 0)"
[[ "$size" -lt 1000 ]] && exit 0

# Skip non-interactive SDK invocations (aicommit, ai-title, etc.) — they carry
# entrypoint "sdk-cli" and never yield durable memory. Real sessions are "cli".
if head -n 10 "$transcript" | jq -r '.entrypoint // empty' 2>/dev/null | grep -qx 'sdk-cli'; then
  exit 0
fi

[[ -s "$ledger" ]] || echo '{}' > "$ledger"

# Don't clobber an entry that's already been wrapped or queued.
already="$(jq -r --arg s "$sid" '.[$s].status // empty' "$ledger")"
[[ -n "$already" ]] && exit 0

tmp="$(mktemp)"
jq --arg s "$sid" \
   --arg t "$transcript" \
   --arg c "$cwd" \
   --arg e "$(date -u +%FT%TZ)" \
   '.[$s] = {transcript: $t, cwd: $c, ended_at: $e, status: "pending"}' \
   "$ledger" > "$tmp" && mv "$tmp" "$ledger"

exit 0
