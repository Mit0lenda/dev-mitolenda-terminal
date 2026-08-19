#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EFFECTIVE_HOME="${MITOLENDA_TEST_HOME:-$HOME}"
CONFIG_DIR="$EFFECTIVE_HOME/.config/dev-mitolenda-terminal"
ZSHRC="$EFFECTIVE_HOME/.zshrc"
START_MARKER='# >>> DEV_MITOLENDA TERMINAL >>>'
END_MARKER='# <<< DEV_MITOLENDA TERMINAL <<<'

remove_managed_block() {
  local target="$1"
  local temporary

  [ -f "$target" ] || return 0
  temporary="$(mktemp "${target}.mitolenda.XXXXXX")"
  cp -p "$target" "$temporary"
  awk -v start="$START_MARKER" -v end="$END_MARKER" '
    !inside && $0 == start {
      inside = 1
      held = $0 ORS
      next
    }
    inside {
      held = held $0 ORS
      if ($0 == end) {
        inside = 0
        held = ""
      }
      next
    }
    { print }
    END {
      if (inside) {
        printf "%s", held
      }
    }
  ' "$target" > "$temporary"
  mv "$temporary" "$target"
}

is_managed_config() {
  [ -f "$CONFIG_DIR/starship.toml" ] && head -n 1 "$CONFIG_DIR/starship.toml" | grep -Fqx '# DEV_MITOLENDA // TERMINAL'
}

remove_managed_block "$ZSHRC"

if [ -d "$CONFIG_DIR" ]; then
  if is_managed_config; then
    rm -rf "$CONFIG_DIR"
    printf 'Removed DEV_MITOLENDA Terminal files from %s\n' "$CONFIG_DIR"
  else
    printf 'Preserved %s because it is not a recognized DEV_MITOLENDA configuration.\n' "$CONFIG_DIR"
  fi
fi

printf 'DEV_MITOLENDA Terminal shell integration removed. Backups, Starship, and fonts were preserved.\n'
