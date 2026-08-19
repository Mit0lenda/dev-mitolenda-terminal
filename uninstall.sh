#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EFFECTIVE_HOME="${MITOLENDA_TEST_HOME:-$HOME}"
CONFIG_DIR="$EFFECTIVE_HOME/.config/dev-mitolenda-terminal"
ZSHRC="$EFFECTIVE_HOME/.zshrc"
source "$SCRIPT_DIR/shell/managed-block.sh"

is_unchanged_managed_file() {
  local installed_path="$1"
  local project_path="$2"

  [ -f "$installed_path" ] && cmp -s "$installed_path" "$project_path"
}

if ! mitolenda_remove_managed_blocks "$ZSHRC"; then
  printf 'DEV_MITOLENDA uninstall: refusing to change .zshrc with invalid managed block markers.\n' >&2
  exit 1
fi

removed_file=0
starship_path="$CONFIG_DIR/starship.toml"
helper_path="$CONFIG_DIR/mitolenda.zsh"

if is_unchanged_managed_file "$starship_path" "$SCRIPT_DIR/config/starship.toml"; then
  rm -f "$starship_path"
  removed_file=1
elif [ -e "$starship_path" ] || [ -L "$starship_path" ]; then
  printf 'Preserved %s because it differs from the DEV_MITOLENDA project file.\n' "$starship_path"
fi

if is_unchanged_managed_file "$helper_path" "$SCRIPT_DIR/shell/mitolenda.zsh"; then
  rm -f "$helper_path"
  removed_file=1
elif [ -e "$helper_path" ] || [ -L "$helper_path" ]; then
  printf 'Preserved %s because it differs from the DEV_MITOLENDA project file.\n' "$helper_path"
fi

if [ -d "$CONFIG_DIR" ]; then
  rmdir "$CONFIG_DIR" 2>/dev/null || true
fi
if [ "$removed_file" -eq 1 ]; then
  printf 'Removed unchanged DEV_MITOLENDA Terminal files from %s\n' "$CONFIG_DIR"
fi

printf 'DEV_MITOLENDA Terminal shell integration removed. Backups, Starship, and fonts were preserved.\n'
