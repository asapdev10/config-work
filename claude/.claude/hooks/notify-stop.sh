#!/usr/bin/env bash
# Stop hook: pop a desktop notification when a turn completes. macOS version
base="$(basename "$PWD")"
# Escape double quotes for the AppleScript string literals.
safe="${base//\"/\\\"}"

osascript -e "display notification \"Turn complete in ${safe}\" with title \"Claude Code\"" >/dev/null 2>&1 &
disown 2>/dev/null
exit 0
