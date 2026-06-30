# ~/lab/config-work — work-laptop dotfiles via GNU Stow (macOS)
# Usage: `just <recipe>`

# Stow packages, in install order. Edit this list to add/remove packages.
PACKAGES := "bash git nvim wezterm zellij yazi delta tig"

# Single source of truth for installed CLI tools (brew bundle format).
BREWFILE := justfile_directory() / "tools/Brewfile"

# Default: show recipes
default:
    @just --list

# ── Stow ─────────────────────────────────────────────────────────────────────
# All stow recipes run from the repo root and target $HOME via this helper.
_stow *FLAGS:
    @cd {{ justfile_directory() }} && stow --target="$HOME" {{ FLAGS }}

# Symlink all packages into $HOME (refuses to clobber existing files).
stow-install: (_stow "--verbose=1" PACKAGES)

# Dry-run all packages: show what would change, create nothing.
stow-check: (_stow "--simulate --verbose=2" PACKAGES)

# Re-link all packages (use after adding a file or restructuring a package).
stow-restow: (_stow "--restow --verbose=1" PACKAGES)

# ── CLI tools (tools/Brewfile) ───────────────────────────────────────────────

# Install + upgrade everything listed in the Brewfile, plus uv tools + Neovim.
tools-update:
    @brew update && brew upgrade
    @brew bundle install --file="{{ BREWFILE }}"
    @uv tool upgrade --all
    @chmod u+w ~/.local/share/bob/nvim-bin/nvim 2>/dev/null || true  # bob leaves the proxy read-only, breaking the next update
    @bob update stable

# Verify everything in the Brewfile is installed.
tools-check:
    @brew bundle check --file="{{ BREWFILE }}" --verbose

# Regenerate the Brewfile from what's installed (overwrites comments — review the diff).
tools-dump:
    @brew bundle dump --file="{{ BREWFILE }}" --force --describe

# List tools installed but NOT in the Brewfile (dry-run; add --force yourself to remove).
tools-cleanup:
    @brew bundle cleanup --file="{{ BREWFILE }}"
