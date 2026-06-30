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

# Optional shell env (GOPRIVATE, tokens, etc.) — sourced by variables.bash
# echo 'export GOPRIVATE=...' >> ~/.env.local
```

If `just stow-install` refuses because a real `~/.bashrc` already exists, either
delete it first or run `stow --adopt --target="$HOME" bash` once and inspect
`git diff` before keeping anything it pulled in.

## Packages

| Package    | Stows to                    | What it is                          |
|------------|-----------------------------|-------------------------------------|
| `bash`     | `~/.bashrc`, `~/.bashrc.d/`  | shell entry point + modular configs |
| `git`      | `~/.gitconfig`              | git config + delta/difftastic (identity in `~/.gitconfig.local`) |
| `nvim`     | `~/.config/nvim/`           | neovim                              |
| `wezterm`  | `~/.config/wezterm/`        | terminal                            |
| `zellij`   | `~/.config/zellij/`         | terminal multiplexer                |
| `yazi`     | `~/.config/yazi/`           | file manager                        |
| `delta`    | `~/.config/delta/`          | git diff theme                      |
| `tig`      | `~/.config/tig/`            | git TUI                             |

## What's intentionally NOT here

Excluded from the personal dotfiles to keep this work-machine-safe: Claude Code
config + auto-memory, VSCode workspaces, personal `scripts/`, the OPNsense CLI,
project scaffolding templates, Windows/WSL packages, and the Linux `Aptfile`.
The shell config is mac-first (Homebrew prefix auto-detected; clipboard via
`pbcopy`) but still works unchanged on Linuxbrew.
