#!/run/current-system/sw/bin/bash

if [ $# -ne 1 ]; then
  echo "Usage: $0 <target_dir>"
  exit 1
fi

check_dir() {
  local dir=$1
  local file

  for application in "$dir/"*; do
    file="$(basename "$application")"

    sed "s/^Exec=/Exec=bwbox --name '$file' --profile wayland /gi" "$application" > "$target/$file"
  done
}

dirs=($(echo "$XDG_DATA_DIRS" | tr ':' '\n'))
dirs+=("$HOME/.local/share")
target="$1"

mkdir -p "$target"

for dir in "${dirs[@]}"; do
  if [ -d "$dir/applications" ]; then
    check_dir "$dir/applications"
  fi
done
