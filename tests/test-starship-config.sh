#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
config_file="$repo_root/config/starship.toml"

if [[ ${TERM:-} == "dumb" || -z ${TERM:-} ]]; then
  export TERM=xterm-256color
fi

for expected in \
  'palette = "mitolenda"' \
  'DEV_MITOLENDA' \
  'background = "#080808"' \
  'surface = "#181818"' \
  'orange = "#F24A00"' \
  'blue = "#00AEEF"' \
  'green = "#00F5A0"' \
  'text = "#F7F2E8"' \
  'secondary = "#A1A1AA"' \
  '[git_branch]' \
  '[git_status]' \
  '[status]' \
  '[cmd_duration]' \
  '[time]' \
  '[username]' \
  '[hostname]'; do
  grep -F -- "$expected" "$config_file" >/dev/null
done

if command -v starship >/dev/null 2>&1; then
  STARSHIP_CONFIG="$config_file" starship prompt >/dev/null
fi
