---
description: Batch memory review of past sessions that were never wrapped (reads the wrap ledger); auto-applies the memory edits worth making
---

Process the backlog of sessions I ended without running `/wrap`. The `SessionEnd`
hook (`wrap-queue.sh`) records each ended session in `~/.claude/wrap-ledger.json`
with `status: "pending"`. This command mines those transcripts and **applies** the
memory edits worth making, then reports what it did. (Unlike `/wrap`, it does not
wait for per-item approval — I'll review the memory later if I want.)

## Procedure

1. **Read the ledger** at `~/.claude/wrap-ledger.json`. Select entries with
   `status == "pending"`, oldest `ended_at` first.
   - If none are pending, say so and stop.
   - Cap this run at the **10 oldest** pending sessions. If more remain, note how
     many are deferred to the next run.
   - Cheaply skip empties first: an effectively-empty transcript (e.g. ≤10 lines /
     a couple KB) gets marked `wrapped` without a subagent.

2. **Process each pending session with a subagent** — do NOT read the raw
   transcripts into this conversation (they can be multiple MB each). For each
   selected session, launch a `general-purpose` Agent with the transcript path
   and these instructions:

   > Read the JSONL transcript at `<transcript>`. It is one Claude Code session.
   > Extract only what a future session would want to know but couldn't get from
   > the code or git log. Look for: new durable facts (preferences, decisions,
   > projects, tools, plans); corrections to how I work; repeated corrections
   > (feedback candidates); universal rules for CLAUDE.md; things that became
   > stale. Ignore ephemeral task state and anything already in code/git.
   > DATES: this is an OLD session. Do NOT assume work happened "today" — derive
   > any date from the transcript's own `timestamp` fields (the session's real
   > date), never from the current date in your context. If you can't date
   > something from the transcript, say "undated" rather than guessing.
   > Return a compact punch-list (or "nothing" if the session yielded none),
   > each item tagged NEW_MEMORY / UPDATE_MEMORY / DELETE_MEMORY /
   > NEW_CLAUDE_RULE / UPDATE_CLAUDE_RULE with a one-line why and proposed content.

   Launch independent sessions' subagents in parallel.

3. **Consolidate** the subagent results. Dedupe across sessions (the same fact
   may surface in several), and reconcile against my **current** memory
   (the auto-memory dir under `~/.claude/projects/*/memory/`) — read existing
   files before editing; never overwrite blindly. Drop anything already captured.

4. **Verify before writing.** Before persisting any item with a concrete,
   checkable claim (a file/path/recipe/flag/migration/app-name/code fact), confirm
   it against the live repo/filesystem (see [[feedback_catchup_verify_claims]]).
   Discard or correct claims that don't check out — never write an unverified
   concrete claim to memory.

5. **Apply the worthwhile memory edits automatically.** Use my judgment for the
   bar (durable, non-obvious, verified, not already captured); write `NEW_MEMORY` /
   `UPDATE_MEMORY` / `DELETE_MEMORY` directly to the memory dir, and keep the
   `MEMORY.md` index in sync (add a line for each new file, remove the line for any
   deleted file, fix lines whose summary went stale). For `feedback_*` memories
   include **Why:** and **How to apply:** lines. Prefer surgical edits to existing
   files over new files when the fact belongs in one. Skip borderline/low-value
   items rather than padding memory.

6. **Report** a concise summary of what was written (one line per memory file
   touched, grouped new/updated/deleted), what was skipped and why (already
   captured / too trivial / unverified), and the **flags** from step 7. Note the
   remaining pending count so I know whether to run `/catchup` again.

## Constraints

- **Do not auto-apply outside the memory dir.** Memory edits are automatic;
  anything broader is not. Surface these as **flags** for me to decide, don't act
  on them: changes to a CLAUDE.md file (global or project), and any real-world
  action a session implied (e.g. `git init`, committing, deploying, deleting code,
  installing). A `NEW_CLAUDE_RULE` / `UPDATE_CLAUDE_RULE` becomes a flag, not an
  edit.
- **DELETE_MEMORY:** apply only when the memory is clearly wrong or fully
  superseded and you've verified so; if it's merely stale-ish or uncertain, flag
  it instead of deleting.
- **Mark every session you scanned as done in the ledger**, whether or not it
  yielded items (so it is never re-scanned). Use:

  ```
  tmp=$(mktemp); jq --arg s "<session_id>" --arg w "$(date -u +%FT%TZ)" \
    '.[$s].status="wrapped" | .[$s].wrapped_at=$w' \
    ~/.claude/wrap-ledger.json > "$tmp" && mv "$tmp" ~/.claude/wrap-ledger.json
  ```

- If a session yielded nothing, still mark it `wrapped`.
- Empty is a valid outcome — if the backlog produced nothing worth keeping, say so.
