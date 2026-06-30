# ~/.zshrc — interactive zsh setup. PATH + exported env live in ~/.zshenv.

# Restore PATH precedence after macOS path_helper reordered it (see ~/.zshenv).
typeset -f _setup_path >/dev/null && _setup_path

# Disable flow control (prevents Ctrl-S freeze).
stty -ixon 2>/dev/null

# Completion system — required before fzf's zsh completion and most tools.
autoload -Uz compinit
compinit -d "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump"

# History (zsh defaults are tiny and unshared).
HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
mkdir -p "${HISTFILE%/*}"
HISTSIZE=50000
SAVEHIST=50000
setopt SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE INC_APPEND_HISTORY

# Modular interactive config ((N) = no error when the glob is empty).
for rc in ~/.zshrc.d/*.zsh(N); do
    source "$rc"
done
unset rc

# Zoxide (cached — avoids a subprocess on every shell start).
if command -v zoxide >/dev/null 2>&1; then
    _zox_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zoxide/init.zsh"
    _zox_bin="$(command -v zoxide)"
    if [ ! -f "$_zox_cache" ] || [ "$_zox_bin" -nt "$_zox_cache" ]; then
        mkdir -p "${_zox_cache%/*}"
        zoxide init zsh > "$_zox_cache"
    fi
    source "$_zox_cache"
fi

# fzf (cached — Ctrl-R history, Ctrl-T files, Alt-C cd, completion).
if command -v fzf >/dev/null 2>&1; then
    _fzf_cache="${XDG_CACHE_HOME:-$HOME/.cache}/fzf/init.zsh"
    _fzf_bin="$(command -v fzf)"
    if [ ! -f "$_fzf_cache" ] || [ "$_fzf_bin" -nt "$_fzf_cache" ]; then
        mkdir -p "${_fzf_cache%/*}"
        fzf --zsh > "$_fzf_cache"
    fi
    source "$_fzf_cache"
fi

# NVM (lazy-loaded — nvm.sh typically costs 200-400ms). The stubs swap themselves
# for the real commands on first use.
_nvm_lazy_load() {
    unset -f nvm node npm npx 2>/dev/null
    [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
}
nvm()  { _nvm_lazy_load; nvm  "$@"; }
node() { _nvm_lazy_load; node "$@"; }
npm()  { _nvm_lazy_load; npm  "$@"; }
npx()  { _nvm_lazy_load; npx  "$@"; }

# Prompt: green cwd, like the bash config (PROMPT_SUBST for the %~ expansion).
setopt PROMPT_SUBST
PROMPT='%F{green}%~%f $ '
