# Preferred tools
- `rg` (ripgrep) for searching in files
- `fd` for finding files

---

# Dotfiles workflow
- To modify a config file (or when you suggest modifying one), edit it inside `~/lab/config-work` rather than the stowed location; run `just stow-restow` only if a new file/symlink was added (existing edits flow through automatically). If the file isn't tracked there yet, ask before creating it.

---

# Git
- Never add AI attribution to commits: no `Co-Authored-By: Claude`, no "Generated with Claude Code" — not in messages you write, and not in commit-message prompts/scripts you help build.

---

# Working style
- **Code changes:** keep individual change batches to ~150–200 lines. Stop and check in before going past that so I can review.
- **Answers:** be direct and brief. Expand only when I ask.
