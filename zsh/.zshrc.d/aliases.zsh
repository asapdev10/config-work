#!/usr/bin/env zsh

alias n='nvim'
alias lg='lazygit'
alias r='source ~/.zshrc'
alias rl='source ~/.zshrc'
# eza replaces GNU `ls` here — macOS BSD ls has no --time-style. --no-user drops
# the owner column (eza omits group by default), matching the old awk-stripped view.
alias ll='eza -la --no-user --time-style="+%Y-%m-%d %H:%M:%S"'
alias lc='eza -1'
alias gcb='git checkout $(git branch | fzf | sed "s/^[* ]*//")'
alias sqlite='sqlite3'
alias python='python3'
alias cs='cd ~/lab/config-work && just stow-install'
alias lgcfg='lazygit -p=$HOME/lab/config-work'
alias gcp="git log --oneline | fzf --preview 'git show --name-only --oneline {1}' | awk '{print $1}'"
alias gfd='git log --oneline | fzf --preview "git show --name-only --oneline {1}" --prompt="Commit> " | awk "{print \$1}" | xargs -I{} sh -c "git diff --name-only {}^ {} | fzf --prompt=\"File> \" --preview \"git diff --color=always {}^ {} -- {}\""'
alias gfd2='commit=$(git log --oneline | fzf --preview "git show --name-only --oneline {1}" --prompt="Commit> " | awk "{print \$1}") && file=$(git diff --name-only "$commit^" "$commit" | fzf --no-preview --prompt="File> ") && git diff --color=always "$commit^" "$commit" -- "$file" | delta'

y() {
  local tmp cwd
  tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
    builtin cd -- "$cwd"
  fi
  rm -f -- "$tmp"
}
# NOTE: `aicommit` (pipes the staged diff to Anthropic for a commit message) is
# intentionally omitted from this work-laptop config — it would send work code
# externally. Re-add it from the main dotfiles if your employer permits it.

gdft() {
  git diff --name-only "$@" \
    | fzf --multi \
        --preview "GIT_EXTERNAL_DIFF=difft git diff $* -- {}" \
        --preview-window=down:70%:wrap \
        --bind "enter:become(GIT_EXTERNAL_DIFF=difft git diff $* -- {+} | less -R)"
}
