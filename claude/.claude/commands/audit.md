---
description: Audit Claude config and memory for rot (stale refs, contradictions, drift)
---

Audit my Claude state for rot. Output a punch list grouped by severity, then stop. Do not change anything — I will review and decide what to fix.

## 1. Broken references (highest severity)

- Read `~/.claude/CLAUDE.md`. For every file path or directory mentioned, verify it exists on disk. Flag any that don't.
- Read every file in the auto-memory dir(s) `~/.claude/projects/*/memory/`. For each memory referencing a file path, verify it exists. Flag any that don't.
- Check every `@import` in `~/.claude/CLAUDE.md` and any project CLAUDE.md found in the current project tree.

## 2. Index drift

- Verify every link in MEMORY.md points to a file that exists in the memory directory.
- Verify every memory file in the directory is linked from MEMORY.md (no orphans).
- Verify each memory file's `name:` frontmatter matches its filename slug.

## 3. Contradictions

- Compare memories against each other and against CLAUDE.md. Flag any direct contradictions (e.g., "use X for Y" in one, "never use X" in another).
- Compare global `~/.claude/CLAUDE.md` rules against rules in any project CLAUDE.md files in the current project tree. Flag duplicates (candidate for removal from project) or conflicts.

## 4. Staleness signals

- Memory files with dates older than 6 months relative to today that describe "current state" of a project — flag for verification.
- Memory files describing initiatives, deadlines, or in-progress work — flag for review (these decay fastest).
- Project memories where the project directory no longer exists or has been archived.

## 5. Bloat signals

- Token count estimate per CLAUDE.md and per memory file.
- Largest 3 memory files — are they justified or candidates for splitting?
- Any rule in `~/.claude/CLAUDE.md` that applies only to one specific project (candidate for demotion to project CLAUDE.md).

## Output format

```
## BROKEN REFERENCES (N)
- file:line — what's broken — suggested fix

## INDEX DRIFT (N)
- ...

## CONTRADICTIONS (N)
- ...

## STALE (N)
- ...

## BLOAT (N)
- ...
```

If a section is empty, write `## SECTION (0)\n(none)`.
