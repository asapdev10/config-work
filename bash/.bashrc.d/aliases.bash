#!/bin/bash

alias n='nvim'
alias lg='lazygit'
alias r='source ~/.bashrc'
alias rl='source ~/.bashrc'
alias ll='ls -al --time-style="+%Y-%m-%d %H:%M:%S" | awk "{\$3=\"\"; \$4=\"\"; print}" | sed "s/  / /g"'
alias lc='ls --format=single-column'
alias gcb='git checkout $(git branch | fzf | sed "s/^[* ]*//")'
alias sqlite='sqlite3'
alias fly='flyctl'
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

aicommit() {
  local diff msg
  diff="$(git diff --staged | head -c 50000)"
  if [ -z "$diff" ]; then
    echo "aicommit: no staged changes" >&2
    return 1
  fi
  msg="$(printf '%s' "$diff" | claude -p --model claude-haiku-4-5 \
    'Write a Conventional Commits message for the staged diff on stdin.

Format: "<type>(<optional scope>): <imperative subject under 72 chars total>". Pick type from: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert. Use "!" after type/scope for breaking changes (e.g. "feat!: ...").

Body: usually omit. Only include a body if the diff has a non-obvious motivation that a reader could not infer from the change itself (e.g. a workaround, a constraint, a subtle invariant). When you do include one, blank line then 1-3 terse bullets stating the specific reason — not generic justifications like "improves consistency" or "better tooling". If you cannot state a specific why, omit the body.

Output only the commit message — no preamble, no code fences, no quotes.')"
  printf '%s\n' "$msg"
  if command -v pbcopy >/dev/null 2>&1; then
    printf '%s' "$msg" | pbcopy
  elif command -v wl-copy >/dev/null 2>&1; then
    printf '%s' "$msg" | wl-copy
  elif command -v xclip >/dev/null 2>&1; then
    printf '%s' "$msg" | xclip -selection clipboard
  fi
}

gdft() {
  git diff --name-only "$@" \
    | fzf --multi \
        --preview "GIT_EXTERNAL_DIFF=difft git diff $* -- {}" \
        --preview-window=down:70%:wrap \
        --bind "enter:become(GIT_EXTERNAL_DIFF=difft git diff $* -- {+} | less -R)"
}
