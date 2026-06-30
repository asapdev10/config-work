#!/usr/bin/env bash
cmd="$(jq -r '.tool_input.command // empty')"
if ! printf '%s' "$cmd" | grep -Eq '(^|[[:space:];&|])curl([[:space:]]|$)'; then
  exit 0
fi
if ! printf '%s' "$cmd" | grep -Eq '(localhost|127\.0\.0\.1|0\.0\.0\.0|\[::1\])'; then
  exit 0
fi
if printf '%s' "$cmd" | grep -Eq '(^|[[:space:]])(-m|--max-time)([[:space:]]|=)'; then
  exit 0
fi
echo "Add -m 10 (or similar) when curling localhost — slow responses should fail fast, not hang." >&2
exit 2
