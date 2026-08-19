#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EFFECTIVE_HOME="${MITOLENDA_TEST_HOME:-$HOME}"
CONFIG_DIR="$EFFECTIVE_HOME/.config/dev-mitolenda-terminal"
ZSHRC="$EFFECTIVE_HOME/.zshrc"
source "$SCRIPT_DIR/shell/managed-block.sh"

is_managed_config() {
  [ -f "$CONFIG_DIR/starship.toml" ] && head -n 1 "$CONFIG_DIR/starship.toml" | grep -Fqx '# DEV_MITOLENDA // TERMINAL'
}

if ! mitolenda_remove_managed_blocks "$ZSHRC"; then
  printf 'DEV_MITOLENDA uninstall: refusing to change .zshrc with invalid managed block markers.\n' >&2
  exit 1
fi

if [ -d "$CONFIG_DIR" ]; then
  if is_managed_config; then
    rm -rf "$CONFIG_DIR"
    printf 'Removed DEV_MITOLENDA Terminal files from %s\n' "$CONFIG_DIR"
  else
    printf 'Preserved %s because it is not a recognized DEV_MITOLENDA configuration.\n' "$CONFIG_DIR"
  fi
fi

printf 'DEV_MITOLENDA Terminal shell integration removed. Backups, Starship, and fonts were preserved.\n'
