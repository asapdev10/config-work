# ~/.zshenv — read by EVERY zsh: interactive, scripts, and the non-interactive
# subshells fzf spawns for `become`/`execute`. Keep it to PATH + exported env +
# the few functions those subshells need. Interactive-only setup lives in .zshrc.

# PATH + brew, factored into a function so .zshrc can re-run it. On a login shell
# macOS's path_helper (/etc/zprofile) runs AFTER .zshenv and reorders PATH —
# pushing /opt/homebrew behind /usr/bin, so Apple's stock git would shadow brew's.
# .zshrc calls _setup_path again to restore our precedence. (path_helper only
# runs for login shells, so non-interactive agent subshells get the right order
# here and don't need the re-run.)
_setup_path() {
    # Local bins first.
    path=("$HOME/.local/bin" "$HOME/bin" $path)

    # pnpm.
    export PNPM_HOME="$HOME/.local/share/pnpm"
    path=("$PNPM_HOME" $path)

    # Homebrew (cached — avoids a subprocess on every shell start). Detect the
    # prefix across Apple Silicon, Intel Mac, and Linuxbrew.
    local _brew_bin _brew_cache
    for _brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
        [ -x "$_brew_bin" ] && break
        _brew_bin=""
    done
    if [ -n "$_brew_bin" ]; then
        _brew_cache="${XDG_CACHE_HOME:-$HOME/.cache}/brew/shellenv.zsh"
        if [ ! -f "$_brew_cache" ] || [ "$_brew_bin" -nt "$_brew_cache" ]; then
            mkdir -p "${_brew_cache%/*}"
            "$_brew_bin" shellenv > "$_brew_cache"
        fi
        source "$_brew_cache"
    fi

    # Extra tool dirs (kept after the essentials above).
    path+=(
        "$HOME/scripts"
        "$HOME/.dotnet/tools"
        "$HOME/.cargo/bin"
        "$HOME/.local/share/bob/nvim-bin"
        "$HOME/.fly/bin"
        "$HOME/go/bin"
    )

    # Cargo env (sets PATH + a few vars).
    [ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

    typeset -gU path   # dedup in place, keeping the first occurrence
}
_setup_path

export NVM_DIR="$HOME/.nvm"
export EDITOR="nvim"
export SUDO_EDITOR="$HOME/.local/share/bob/nvim-bin/nvim"

# clip(): copy stdin to the clipboard. Defined HERE, not in fzf.zsh, because fzf's
# become/execute run `$SHELL -c …` — a non-interactive zsh that reads only this
# file. (The bash config used `export -f clip`; zsh has no function export.)
# pbcopy on macOS; Wayland/X11 for Linuxbrew; OSC 52 so a path reaches the *local*
# clipboard over ssh/tmux. OSC 52 needs tmux `set-clipboard on`.
clip() {
    local data; data="$(cat)"; [ -z "$data" ] && return
    if command -v pbcopy >/dev/null 2>&1; then
        printf '%s' "$data" | pbcopy
    elif [ -n "$WAYLAND_DISPLAY" ] && command -v wl-copy >/dev/null 2>&1; then
        printf '%s' "$data" | wl-copy
    elif [ -n "$DISPLAY" ] && command -v xclip >/dev/null 2>&1; then
        printf '%s' "$data" | xclip -selection clipboard
    else
        local b64; b64="$(printf '%s' "$data" | base64 | tr -d '\n')"
        if [ -n "$TMUX" ]; then
            printf '\033Ptmux;\033\033]52;c;%s\007\033\\' "$b64"
        else
            printf '\033]52;c;%s\007' "$b64"
        fi
    fi
}

# Machine-local environment (work email, GOPRIVATE, tokens) — untracked. Create
# ~/.env.local with `export FOO=...` lines.
[ -f "$HOME/.env.local" ] && source "$HOME/.env.local"
