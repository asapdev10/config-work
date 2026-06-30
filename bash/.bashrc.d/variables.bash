#!/bin/bash
paths_to_add=(
  "$HOME/scripts"
  "$HOME/.dotnet/tools"
  "$HOME/.cargo/bin"
  "$HOME/.local/share/bob/nvim-bin"
  "$HOME/.local/bin"
  "$HOME/.fly/bin"
  "$HOME/go/bin"
)

# Add the paths to PATH
for new_path in "${paths_to_add[@]}"; do
  if [[ ":$PATH:" != *":$new_path:"* ]]; then
    export PATH="$PATH:$new_path"
  fi
done

# Remove duplicate entries from PATH
if [ -n "$PATH" ]; then
  old_PATH=$PATH:; PATH=
  while [ -n "$old_PATH" ]; do
    x=${old_PATH%%:*}
    case $PATH: in
      *:"$x":*) ;;
      *) PATH=$PATH:$x;;
    esac
    old_PATH=${old_PATH#*:}
  done
  PATH=${PATH#:}
  export PATH
fi

# Machine-local environment (work email, GOPRIVATE, tokens, etc.) lives in an
# untracked file so nothing private lands in this repo. Create ~/.env.local and
# put `export FOO=...` lines there.
[ -f "$HOME/.env.local" ] && . "$HOME/.env.local"

# Setup prompt
PS1='\[\e[32m\]$PWD\[\e[0m\] $ '
