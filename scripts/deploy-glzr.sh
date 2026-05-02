#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
windows_home="/mnt/c/Users/Andrei"
live_root="$windows_home/.glzr"
glazewm_cli="/mnt/c/Program Files/glzr.io/GlazeWM/cli/glazewm.exe"

copy_file() {
  local source_path="$1"
  local target_path="$2"

  mkdir -p "$(dirname -- "$target_path")"
  cp -- "$source_path" "$target_path"
  printf 'deployed %s\n' "${target_path#$windows_home/}"
}

copy_file "$repo_root/.glzr/glazewm/config.yaml" "$live_root/glazewm/config.yaml"
copy_file "$repo_root/.glzr/glazewm/focus-or-launch.ps1" "$live_root/glazewm/scripts/focus-or-launch.ps1"
copy_file "$repo_root/.glzr/zebar/settings.json" "$live_root/zebar/settings.json"

if [[ -f "$repo_root/.glzr/zebar/.marketplace/glzr-io.starter.json" ]]; then
  copy_file \
    "$repo_root/.glzr/zebar/.marketplace/glzr-io.starter.json" \
    "$live_root/zebar/.marketplace/glzr-io.starter.json"
fi

if [[ -x "$glazewm_cli" ]]; then
  "$glazewm_cli" command wm-reload-config >/dev/null
  printf 'reloaded GlazeWM\n'
else
  printf 'GlazeWM CLI not found; skipped reload\n' >&2
fi
