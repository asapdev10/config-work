# config-work

Work-laptop dotfiles (macOS), managed via [GNU Stow](https://www.gnu.org/software/stow/).
A deliberately minimal, **personal-data-free** subset of my main dotfiles —
nothing here references private notes, business repos, or my personal identity.

## Install on a new Mac

```bash
brew install stow just
git clone <this-repo> ~/lab/config-work
cd ~/lab/config-work
just stow-check                # dry-run, see what would link
just stow-install              # create the symlinks
just tools-update              # install the CLI toolkit from tools/Brewfile
```

Then set your machine-local bits (these are **gitignored**, never committed):

```bash
# Git identity + any host-specific url rewrites
cat > ~/.gitconfig.local <<'EOF'
[user]
  name = Your Name
  email = you@work.example
EOF

# Optional shell env (GOPRIVATE, tokens, etc.) — sourced by ~/.zshenv
# echo 'export GOPRIVATE=...' >> ~/.env.local
```

If `just stow-install` refuses because a real `~/.zshrc` already exists, either
delete it first or run `stow --adopt --target="$HOME" zsh` once and inspect
`git diff` before keeping anything it pulled in.

The `claude` package stows into `~/.claude/`, which Claude Code populates with
live state (`projects/`, `*.jsonl`, ledgers). Stow leaves those alone and links
only the tracked config files — but if a real `~/.claude/settings.json` or
`~/.claude/CLAUDE.md` already exists it'll refuse; back them up or
`stow --adopt --target="$HOME" claude` and review the diff.

## Packages

| Package    | Stows to                    | What it is                          |
|------------|-----------------------------|-------------------------------------|
| `zsh`      | `~/.zshenv`, `~/.zshrc`, `~/.zshrc.d/` | shell env + entry point + modular configs |
| `git`      | `~/.gitconfig`              | git config + delta/difftastic (identity in `~/.gitconfig.local`) |
| `nvim`     | `~/.config/nvim/`           | neovim                              |
| `zellij`   | `~/.config/zellij/`         | terminal multiplexer                |
| `yazi`     | `~/.config/yazi/`           | file manager                        |
| `delta`    | `~/.config/delta/`          | git diff theme                      |
| `claude`   | `~/.claude/`                | Claude Code config: CLAUDE.md, settings, hooks, commands, skills (NO auto-memory — built fresh per machine) |

