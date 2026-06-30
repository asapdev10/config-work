#!/bin/bash
# fzf cockpit — fd/rg/plocate are the engines, fzf is the interactive layer.
# Design rationale lives in the planning brief (fzf.md). Functions:
#   fdi   file finder (one fd walk, in-memory filter, hidden toggle)
#   rgi   live content grep (re-runs rg per keystroke), opens at the match line
#   rgr   find-replace via sd (git-guarded), multi-select files, preview diff
#   loci  whole-FS filename search via the plocate index (instant)
#   dcp   pick any directory and copy its path to the clipboard
#   fj    pick + run a just recipe from the cwd justfile
#   gco   switch git branch (local + remote), preview its log
#   gll   browse git log, copy the SHA, ctrl-o for the full diff
#   gst   pick changed files, preview diff, edit / stage
#   fkill pick process(es) and signal them
#   fport pick a listening socket and kill its owning process
#   ghci  repos whose latest CI run failed (fzf-picks gh account + owner)
#   fz    fuzzy menu of every fzf helper here (computed at runtime)
#   clip  copy stdin to the clipboard (local or remote-over-ssh/tmux)
# fz discovers tools by parsing the "# ── name: desc ──" headers below, so any
# new helper that follows that convention and uses fzf shows up automatically.

# ── shared prune list ────────────────────────────────────────────────────────
# Dirs that are pure noise in every interactive search — pruned even when hidden
# and git-ignored files are included (so dotfiles like .env.prod still surface,
# but node_modules/vendor don't flood results). Edit this one list; fdi, rgi and
# the Ctrl-T/Alt-C widgets all build their excludes from it.
FZF_PRUNE_DIRS=(.git node_modules vendor .venv venv target dist build .next .cache)
_fd_prune() { local d; for d in "${FZF_PRUNE_DIRS[@]}"; do printf -- '--exclude %s ' "$d"; done; }
_rg_prune() { local d; for d in "${FZF_PRUNE_DIRS[@]}"; do printf -- '--glob !%s/ ' "$d"; done; }

# ── fzf built-in keybind engines (Ctrl-T files, Alt-C dirs) ──────────────────
export FZF_DEFAULT_COMMAND="fd --type f --hidden $(_fd_prune)"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type d --hidden $(_fd_prune)"
export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers {}'"
export FZF_ALT_C_OPTS="--preview 'eza -la --color=always {} 2>/dev/null || ls -la {}'"

# Applied to every fzf invocation (including all the functions below). Scroll the
# preview pane from the keyboard: shift-↑/↓ = line, alt-↑/↓ = page; ctrl-/ hides
# it. The mouse wheel scrolls the preview too, out of the box.
export FZF_DEFAULT_OPTS="--bind 'shift-up:preview-up,shift-down:preview-down,alt-up:preview-page-up,alt-down:preview-page-down,ctrl-/:toggle-preview'"

# ── clip: copy stdin to the clipboard, local or remote ───────────────────────
# Prefers a native local backend, then clip.exe (WSL → Windows clipboard), and
# finally OSC 52 so a path reaches the *local* machine's clipboard over ssh/tmux
# (e.g. when working on the home server). OSC 52 needs tmux `set-clipboard on`.
clip() {
  local data; data="$(cat)"; [ -z "$data" ] && return
  if command -v pbcopy >/dev/null 2>&1; then
    printf '%s' "$data" | pbcopy
  elif [ -n "$WAYLAND_DISPLAY" ] && command -v wl-copy >/dev/null 2>&1; then
    printf '%s' "$data" | wl-copy
  elif [ -n "$DISPLAY" ] && command -v xclip >/dev/null 2>&1; then
    printf '%s' "$data" | xclip -selection clipboard
  elif command -v clip.exe >/dev/null 2>&1; then
    printf '%s' "$data" | clip.exe
  else
    local b64; b64="$(printf '%s' "$data" | base64 | tr -d '\n')"
    if [ -n "$TMUX" ]; then
      printf '\033Ptmux;\033\033]52;c;%s\007\033\\' "$b64"
    else
      printf '\033]52;c;%s\007' "$b64"
    fi
  fi
}
# Export so fzf's non-interactive become/execute subshells (which don't source
# .bashrc) can still reach clip — otherwise it errors "clip: command not found".
export -f clip

# ── fdi: file finder, ctrl-h toggles hidden+ignored ──────────────────────────
# Shows hidden + git-ignored files by default (so .env.prod and friends surface)
# with the prune list keeping node_modules/vendor out. ctrl-h drops back to a
# plain, gitignore-respecting walk.
fdi() {
  local ex; ex="$(_fd_prune)"
  local def="fd --type f $ex"
  local all="fd --type f --hidden --no-ignore $ex"
  $all | fzf --prompt 'files+hidden> ' \
    --header 'ctrl-h: toggle hidden+ignored  ·  enter: print path (+ copy)' \
    --preview 'bat --color=always --style=numbers {}' \
    --bind "ctrl-h:transform:[[ \$FZF_PROMPT == *hidden* ]] \
      && echo \"change-prompt(files> )+reload($def)\" \
      || echo \"change-prompt(files+hidden> )+reload($all)\"" \
    --bind "enter:become(p=\$(realpath {}); command -v clip >/dev/null 2>&1 && printf '%s' \"\$p\" | clip 2>/dev/null; printf '%s\\n' \"\$p\")"
}

# ── rgi: live grep, rg re-runs per keystroke, enter opens at file:line ───────
# Searches hidden + git-ignored files by default (binary files are skipped by
# rg automatically). ctrl-h toggles back to a plain, gitignore-respecting walk.
rgi() {
  local base="rg --column --line-number --no-heading --color=always --smart-case $(_rg_prune)"
  local def="$base"
  local all="$base --hidden --no-ignore"
  fzf --ansi --disabled --prompt 'rg+hidden> ' \
      --header 'ctrl-h: toggle hidden+ignored  ·  enter: open at match line' \
      --bind "start:reload:$all {q} || true" \
      --bind "change:transform:[[ \$FZF_PROMPT == *hidden* ]] \
        && echo \"reload:$all {q} || true\" \
        || echo \"reload:$def {q} || true\"" \
      --bind "ctrl-h:transform:[[ \$FZF_PROMPT == *hidden* ]] \
        && echo \"change-prompt(rg> )+reload($def {q} || true)\" \
        || echo \"change-prompt(rg+hidden> )+reload($all {q} || true)\"" \
      --delimiter : \
      --preview 'bat --color=always {1} --highlight-line {2}' \
      --preview-window 'up,60%,+{2}/2' \
      --bind "enter:become($EDITOR {1} +{2})"
}

# ── rgr: find-replace — pick files, preview, apply with sd (git-guarded) ─────
rgr() {
  if [ $# -lt 2 ]; then
    echo "usage: rgr <pattern> <replacement>" >&2; return 2
  fi
  local pat="$1" rep="$2"
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "rgr: refusing to run outside a git repo (so a bad replace is one 'git checkout' away)" >&2
    return 1
  fi
  rg -l --null --color=never "$pat" \
    | fzf --read0 --print0 --multi \
        --preview "rg --passthru -n --color=always -r '$rep' '$pat' {}" \
        --preview-window 'up,70%' \
        --header "replace: $pat -> $rep  ·  tab: pick  enter: apply" \
    | xargs -0 -r sd "$pat" "$rep"
}

# ── loci: whole-FS filename search via the plocate index (instant) ───────────
loci() {
  fzf --disabled --prompt 'locate> ' \
      --bind 'start:reload:true' \
      --bind 'change:reload:plocate {q} 2>/dev/null || true' \
      --preview 'bat --color=always {} 2>/dev/null || ls -la {}' \
      --bind "enter:become($EDITOR {})"
}

# ── dcp: pick any directory (live fd from $HOME, arg overrides root) → clip ──
dcp() {
  local root="${1:-$HOME}" sel
  sel="$(fd --type d --hidden --exclude .git . "$root" \
    | fzf --prompt 'dir> ' --header 'enter: copy path to clipboard' \
        --preview 'eza -la --color=always {} 2>/dev/null || ls -la {}')"
  [ -z "$sel" ] && return
  sel="${sel%/}"                       # fd --type d appends a trailing slash; drop it
  printf '%s' "$sel" | clip
  printf 'copied: %s\n' "$sel"
}

# ── fj: pick a just recipe from the cwd justfile, preview body, run on enter ──
fj() {
  command -v just >/dev/null 2>&1 || { echo "fj: just not installed" >&2; return 1; }
  just --summary >/dev/null 2>&1 || { echo "fj: no justfile in $PWD" >&2; return 1; }
  local sel
  sel=$(just --summary 2>/dev/null | tr ' ' '\n' | sort \
    | fzf --prompt 'just> ' --header 'enter: run recipe (ctrl-c if it needs args)' \
        --preview 'just --show {1}' --preview-window 'up,55%')
  [ -n "$sel" ] && just "$sel"
}

# ── gco: switch git branch (local + remote), preview its log ─────────────────
gco() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "gco: not a git repo" >&2; return 1; }
  local sel
  # Locals first (populates the dedup set), then remotes. The awk drops the
  # remote HEAD pointer and any remote branch that just mirrors a local one.
  sel=$( {
        git for-each-ref --sort=-committerdate --format='L %(refname:short)' refs/heads
        git for-each-ref --sort=-committerdate --format='R %(refname:short) %(symref)' refs/remotes
      } | awk '
          $1 == "R" && $3 != "" { next }                       # remote symbolic HEAD
          $1 == "L" { loc[$2] = 1; print $2; next }            # local branch
          { name = $2; sub(/^[^\/]+\//, "", name)              # strip remote prefix
            if (!(name in loc)) print $2 }' \
    | fzf --prompt 'branch> ' --header 'enter: checkout' \
        --preview 'git log --oneline --graph --color=always --decorate -n 30 {1}' \
        --preview-window 'right,60%' \
        --bind 'ctrl-d:preview-half-page-down,ctrl-u:preview-half-page-up')
  [ -z "$sel" ] && return
  if git show-ref --verify --quiet "refs/heads/$sel"; then
    git switch "$sel"
  else
    git switch "${sel#*/}" 2>/dev/null || git checkout "$sel"   # remote → tracking branch
  fi
}

# ── gll: browse git log, enter copies the SHA, ctrl-o shows the full diff ─────
gll() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "gll: not a git repo" >&2; return 1; }
  git log --color=always \
      --format='%C(auto)%h %C(blue)%an%C(reset) %s %C(dim)(%cr)%C(reset)' \
    | fzf --ansi --no-sort --prompt 'log> ' \
        --header 'enter: copy SHA  ·  ctrl-o: full diff in pager' \
        --preview 'git show {1} | delta' --preview-window 'right,60%' \
        --bind 'ctrl-d:preview-half-page-down,ctrl-u:preview-half-page-up' \
        --bind 'ctrl-o:execute(git show {1} | delta | less -R)' \
        --bind "enter:become(command -v clip >/dev/null 2>&1 && printf '%s' {1} | clip 2>/dev/null; printf '%s\\n' {1})"
}

# ── gpick: pickaxe — find commits that added/removed a string (-G for regex) ──
gpick() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "gpick: not a git repo" >&2; return 1; }
  local mode=-S; [ "$1" = "-G" ] && mode=-G   # -S: occurrence count changed  ·  -G: diff matches regex
  local log="git log --color=always --format='%C(auto)%h %C(blue)%as %C(green)%an%C(reset) %s'"
  # --disabled hands typing to git (via reload), not fzf's own filter, so this is
  # a true pickaxe: each keystroke re-runs git log $mode<query>.
  FZF_DEFAULT_COMMAND=true fzf --ansi --disabled --prompt "pickaxe${mode}> " \
        --header 'type a string  ·  enter: show diff  ·  ctrl-y: copy SHA' \
        --bind "change:reload([ -n {q} ] && $log $mode{q} -- 2>/dev/null || true)" \
        --preview "[ -n {q} ] && git show --color=always $mode{q} {1} | delta --width=\${FZF_PREVIEW_COLUMNS:-80}" \
        --preview-window 'right,60%' \
        --bind 'ctrl-d:preview-half-page-down,ctrl-u:preview-half-page-up' \
        --bind 'ctrl-y:execute-silent(command -v clip >/dev/null 2>&1 && printf %s {1} | clip 2>/dev/null)' \
        --bind 'enter:become(git show {1} | delta 2>/dev/null || git show {1})'
}

# ── gst: pick changed files, preview diff, enter edits, ctrl-a stages ────────
gst() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "gst: not a git repo" >&2; return 1; }
  local files
  files=$(git -c color.status=always status --short \
    | fzf --ansi --multi --prompt 'status> ' \
        --header 'tab: multi  ·  enter: edit  ·  ctrl-a: toggle stage' \
        --preview 'if [ "{1}" = "??" ]; then bat --color=always --style=numbers {2}; \
          else { git diff -- {2}; git diff --cached -- {2}; } | delta --width=${FZF_PREVIEW_COLUMNS:-80}; fi' \
        --preview-window 'right,60%' \
        --bind 'ctrl-d:preview-half-page-down,ctrl-u:preview-half-page-up' \
        --bind 'ctrl-a:execute-silent(if git diff --cached --quiet -- {2}; then git add -- {2}; else git reset -q -- {2}; fi)+reload(git -c color.status=always status --short)' \
    | awk '{print $2}')
  [ -z "$files" ] && return
  ${EDITOR:-vi} $files
}

# ── fkill: pick process(es) — pid · name · [dir] · cmdline, enter signals ────
#   [dir] = basename of the process's cwd, the only tell for `go run`/`npm`
#   style temp binaries (e.g. bomtrail shows as comm=main). cmdline truncated.
#   sorted by CPU. arg = signal.
fkill() {
  local sig="${1:-TERM}" pids
  pids=$(ps -eo pid,comm,args --no-headers --sort=-pcpu 2>/dev/null \
    | while read -r pid comm args; do
        local cwd; cwd=$(readlink "/proc/$pid/cwd" 2>/dev/null)
        printf '%-7s %-15s %-14s %s\n' "$pid" "$comm" "[${cwd##*/}]" "${args:0:60}"
      done \
    | fzf --multi --prompt "kill -$sig> " \
        --header "tab: multi-select  ·  enter: kill -$sig  (pass a signal to fkill for another)" \
    | awk '{print $1}')
  [ -z "$pids" ] && return
  echo "$pids" | xargs -r kill -"$sig" && echo "sent SIG$sig to: $(echo $pids | tr '\n' ' ')"
}

# ── fport: pick a listening socket (address · process · pid), enter kills it ─
fport() {
  local sel pid raw
  # ss only reveals a socket's process to its owner; system ports are masked
  # unless ss runs as root. Try unprivileged, escalate only if nothing's visible.
  raw=$(ss -tlnpH 2>/dev/null)
  if ! grep -q 'pid=' <<<"$raw"; then
    echo "fport: process info hidden — re-running ss as root…" >&2
    raw=$(sudo ss -tlnpH 2>/dev/null) || return
  fi
  # Reformat into columns; pid=N is preserved so the kill grep still works.
  sel=$(printf '%s\n' "$raw" | awk '
    {
      name = "-"; pid = "pid=?"
      if (match($0, /"[^"]+"/))    name = substr($0, RSTART + 1, RLENGTH - 2)
      if (match($0, /pid=[0-9]+/)) pid  = substr($0, RSTART, RLENGTH)
      printf "%-24s %-16s %s\n", $4, name, pid
    }' \
    | fzf --prompt 'port> ' --header 'addr · process · pid  —  enter: kill (SIGTERM)')
  [ -z "$sel" ] && return
  pid=$(printf '%s\n' "$sel" | grep -oP 'pid=\K[0-9]+' | head -1)
  [ -z "$pid" ] && { echo "fport: no pid for that socket" >&2; return 1; }
  if kill "$pid" 2>/dev/null; then
    echo "killed pid $pid ($(ps -o comm= -p "$pid" 2>/dev/null))"
  else
    sudo kill "$pid" && echo "killed pid $pid via sudo"
  fi
}

# ── ghci: repos whose latest CI run failed; fzf-picks account+owner if no args ─
# gh has no cross-repo run view and no per-command account flag, so we pick a
# logged-in account, switch to it (needed to see that account's *private* org
# repos), scan each repo's most recent run, and switch back. Args skip the
# pickers: ghci [account] [owner].  e.g. `ghci myaccount` or `ghci me myorg`.
ghci() {
  command -v gh >/dev/null 2>&1 || { echo "ghci: gh not installed" >&2; return 1; }
  local acct="$1" owner="$2" orig fails
  orig=$(gh auth status --active 2>&1 | grep -oP 'account \K\S+')

  # No account → pick from the logged-in gh accounts.
  if [ -z "$acct" ]; then
    acct=$(gh auth status 2>&1 | grep -oP 'account \K\S+' | sort -u \
      | fzf --prompt 'gh account> ' --header 'enter: account to scan as')
    [ -z "$acct" ] && return
  fi
  gh auth switch --user "$acct" >/dev/null 2>&1 \
    || { echo "ghci: cannot switch to account '$acct'" >&2; return 1; }

  # No owner → pick the account itself or one of its orgs (preview lists repos).
  if [ -z "$owner" ]; then
    owner=$( { printf '%s\n' "$acct"; gh api user/orgs --jq '.[].login' 2>/dev/null; } \
      | fzf --prompt 'owner> ' --header 'enter: user/org to scan  ·  preview: its repos' \
          --preview 'gh repo list {} --no-archived -L 100 --json nameWithOwner -q ".[].nameWithOwner"')
  fi

  if [ -n "$owner" ]; then
    fails=$(gh repo list "$owner" --no-archived -L 200 --json nameWithOwner -q '.[].nameWithOwner' \
      | while read -r r; do
          gh run list -R "$r" -L 1 --json conclusion,workflowName,url \
            -q ".[] | select(.conclusion==\"failure\" or .conclusion==\"timed_out\" or .conclusion==\"startup_failure\") | \"❌ $r\t\(.workflowName)\t\(.url)\""
        done)
    if [ -n "$fails" ]; then
      printf '%s\n' "$fails"
    else
      echo "ghci: ✅ $owner — no repo's latest run is failing (or no CI configured)" >&2
    fi
  fi

  gh auth switch --user "$orig" >/dev/null 2>&1
}

# ── fz: fuzzy menu of every fzf helper in this file, enter runs the choice ────
# Self-maintaining: parses the "# ── name: desc ──" headers above and keeps only
# functions that actually use fzf (so clip and the _*_prune helpers drop out).
fz() {
  local src="${BASH_SOURCE[0]}" line rest name desc out=""
  while IFS= read -r line; do
    case $line in
      '# ── '[a-z]*': '*'──'*)
        rest=${line#'# ── '}
        name=${rest%%:*}
        [[ $name == fz || $name == clip ]] && continue
        declare -f "$name" 2>/dev/null | grep -q '\bfzf\b' || continue
        desc=${rest#*: }; desc=${desc%% ──*}
        out+=$(printf '%-7s %s' "$name" "$desc")$'\n'
        ;;
    esac
  done < "$src"
  local sel
  sel=$(printf '%s' "$out" | fzf --prompt 'fzf tools> ' --header 'enter: run it' \
    --preview "sed -n '/^{1}() {/,/^}/p' \"$src\" | bat --color=always -l bash --style=plain" \
    --preview-window 'right,62%' \
    --bind 'ctrl-d:preview-half-page-down,ctrl-u:preview-half-page-up' | awk '{print $1}')
  [ -n "$sel" ] && "$sel"
}
