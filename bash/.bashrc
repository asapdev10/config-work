# .bashrc

# ── PATH and environment (all sessions, including non-interactive/agents) ──

# Global definitions
[ -f /etc/bashrc ] && . /etc/bashrc

# Local bins
[[ ":$PATH:" != *":$HOME/.local/bin:"* ]] && PATH="$HOME/.local/bin:$HOME/bin:$PATH"

# Cargo
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# pnpm
export PNPM_HOME="$HOME/.local/share/pnpm"
[[ ":$PATH:" != *":$PNPM_HOME:"* ]] && export PATH="$PNPM_HOME:$PATH"

# Homebrew (cached — avoids subprocess on every shell start).
# Detect the prefix across Apple Silicon, Intel Mac, and Linuxbrew.
for _brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
    [ -x "$_brew_bin" ] && break
    _brew_bin=""
done
if [ -n "$_brew_bin" ]; then
    _brew_cache="${XDG_CACHE_HOME:-$HOME/.cache}/brew/shellenv.bash"
    if [ ! -f "$_brew_cache" ] || [ "$_brew_bin" -nt "$_brew_cache" ]; then
        mkdir -p "${_brew_cache%/*}"
        "$_brew_bin" shellenv > "$_brew_cache"
    fi
    . "$_brew_cache"
fi
unset _brew_bin

export NVM_DIR="$HOME/.nvm"
export EDITOR="nvim"
export SUDO_EDITOR="$HOME/.local/share/bob/nvim-bin/nvim"

# ── Non-interactive early exit ──────────────────────────────────────
case $- in
    *i*) ;;
      *) return;;
esac

# ── Interactive shell setup ─────────────────────────────────────────

# User scripts
if [ -d ~/.bashrc.d ]; then
    for rc in ~/.bashrc.d/*.bash; do
        [ -f "$rc" ] && . "$rc"
    done
    unset rc
fi

# Zoxide (cached — avoids subprocess on every shell start)
if command -v zoxide &>/dev/null; then
    _zox_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zoxide/init.bash"
    _zox_bin="$(command -v zoxide)"
    if [ ! -f "$_zox_cache" ] || [ "$_zox_bin" -nt "$_zox_cache" ]; then
        mkdir -p "${_zox_cache%/*}"
        zoxide init bash > "$_zox_cache"
    fi
    . "$_zox_cache"
fi

# fzf (cached — Ctrl-R history, Ctrl-T files, Alt-C cd, completion)
if command -v fzf &>/dev/null; then
    _fzf_cache="${XDG_CACHE_HOME:-$HOME/.cache}/fzf/init.bash"
    _fzf_bin="$(command -v fzf)"
    if [ ! -f "$_fzf_cache" ] || [ "$_fzf_bin" -nt "$_fzf_cache" ]; then
        mkdir -p "${_fzf_cache%/*}"
        fzf --bash > "$_fzf_cache"
    fi
    . "$_fzf_cache"
fi

# NVM (lazy-loaded — nvm.sh typically costs 200-400ms)
# Stubs are replaced with the real commands on first use.
_nvm_lazy_load() {
    unset -f nvm node npm npx
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
}
nvm()  { _nvm_lazy_load; nvm  "$@"; }
node() { _nvm_lazy_load; node "$@"; }
npm()  { _nvm_lazy_load; npm  "$@"; }
npx()  { _nvm_lazy_load; npx  "$@"; }

# Disable flow control (prevents Ctrl-S freeze)
stty -ixon
