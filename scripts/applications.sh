#!/run/current-system/sw/bin/bash

# Copy desktop application launchers into the target directory, prefixing their
# Exec commands with bwbox. Each launcher uses its filename as the sandbox name
# and runs with the wayland profile.

if [ $# -ne 1 ]; then
  echo "Usage: $0 <target_dir>"
  exit 1
fi

check_dir() {
  local dir=$1
  local file
  local temporary

  for application in "$dir/"*; do
    file="$(basename "$application")"

    temporary="$(mktemp "$target/.bwbox-launcher.XXXXXX")" || return 1
    if ! sed "s/^Exec=/Exec=bwbox --name '$file' --profile wayland /gi" "$application" > "$temporary" ||
       ! mv -f -- "$temporary" "$target/$file"; then
      rm -f -- "$temporary"
      return 1
    fi
  done
}

dirs=($(echo "$XDG_DATA_DIRS" | tr ':' '\n'))
dirs+=("$HOME/.local/share")
target="$1"

mkdir -p "$target" || exit 1

for dir in "${dirs[@]}"; do
  if [ "$dir/applications" -ef "$target" ]; then
    echo "Target directory must not be a source applications directory: $target" >&2
    exit 1
  fi
done

for dir in "${dirs[@]}"; do
  if [ -d "$dir/applications" ]; then
    check_dir "$dir/applications" || exit 1
  fi
done
