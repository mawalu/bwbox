#!/bin/bash

if [ $# -ne 1 ]; then
  echo "Usage: $0 <target_dir>"
  exit 1
fi

check_dir() {
  local dir=$1
  local file

  for application in "$dir/"*; do
    file="$(basename "$application")"

    sed "s/^Exec=/Exec=bwshell --name '$file' --profile gui /gi" "$application" > "$target/$file"
  done
}

dirs=("/usr/share/applications" "$HOME/.local/share/applications")
target="$1"

mkdir -p "$target"

for dir in "${dirs[@]}"; do
  check_dir "$dir"
done
