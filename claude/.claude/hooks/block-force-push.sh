#!/usr/bin/env bash
cmd="$(jq -r '.tool_input.command // empty')"
if [[ ! "$cmd" =~ (^|[[:space:];&|])git[[:space:]]+push([[:space:]]|$) ]]; then
  exit 0
fi
if printf '%s' "$cmd" | grep -Eq '(^|[[:space:]])(-f|--force)([[:space:]]|$)'; then
  echo "git push --force / -f is blocked per user policy. Use --force-with-lease if a force push is truly needed." >&2
  exit 2
fi
exit 0
