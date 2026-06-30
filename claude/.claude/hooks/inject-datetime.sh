#!/usr/bin/env bash
# UserPromptSubmit hook: prepend the current local date/time to each prompt as
# additional context. The harness already injects the calendar date at session
# start, but it can go stale in long sessions and never carries time-of-day.
# stdout from a UserPromptSubmit hook is added to the model's context.
set -euo pipefail
printf 'Current date/time: %s\n' "$(date '+%A %Y-%m-%d %H:%M %Z')"
exit 0
