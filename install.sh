#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EFFECTIVE_HOME="${MITOLENDA_TEST_HOME:-$HOME}"
CONFIG_DIR="$EFFECTIVE_HOME/.config/dev-mitolenda-terminal"
BACKUP_ROOT="$EFFECTIVE_HOME/.config/dev-mitolenda-terminal-backups"
ZSHRC="$EFFECTIVE_HOME/.zshrc"
START_MARKER='# >>> DEV_MITOLENDA TERMINAL >>>'
END_MARKER='# <<< DEV_MITOLENDA TERMINAL <<<'

die() {
  printf 'DEV_MITOLENDA installer: %s\n' "$*" >&2
  exit 1
}

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

install_packages() {
  if [ "${MITOLENDA_SKIP_PACKAGES:-0}" = "1" ]; then
    return 0
  fi

  command -v brew >/dev/null 2>&1 || die 'Homebrew is required. Install it from https://brew.sh and run this script again.'

  if ! command -v starship >/dev/null 2>&1; then
    brew install starship
  fi
  if ! brew list --cask font-space-mono-nerd-font >/dev/null 2>&1; then
    brew install --cask font-space-mono-nerd-font
  fi
}

if [ "${MITOLENDA_SKIP_PLATFORM_CHECK:-0}" != "1" ] && [ "$(uname -s)" != 'Darwin' ]; then
  die 'This installer supports macOS with Zsh. Use the Windows installer on Windows.'
fi

command -v zsh >/dev/null 2>&1 || die 'Zsh is required but was not found.'
install_packages

timestamp="$(date '+%Y%m%d%H%M%S')"
backup_dir="$BACKUP_ROOT/$timestamp"
suffix=1
while [ -e "$backup_dir" ]; do
  backup_dir="$BACKUP_ROOT/$timestamp-$suffix"
  suffix=$((suffix + 1))
done
mkdir -p "$backup_dir"

if [ -f "$ZSHRC" ]; then
  cp -p "$ZSHRC" "$backup_dir/.zshrc"
fi
if [ -d "$CONFIG_DIR" ]; then
  mkdir -p "$backup_dir/managed-config"
  cp -R "$CONFIG_DIR"/. "$backup_dir/managed-config"
fi

mkdir -p "$CONFIG_DIR"
cp "$SCRIPT_DIR/config/starship.toml" "$CONFIG_DIR/starship.toml"
cp "$SCRIPT_DIR/shell/mitolenda.zsh" "$CONFIG_DIR/mitolenda.zsh"

touch "$ZSHRC"
remove_managed_block "$ZSHRC"
if [ -s "$ZSHRC" ]; then
  last_byte="$(tail -c 1 "$ZSHRC" | od -An -tx1 | tr -d '[:space:]')"
  if [ "$last_byte" != '0a' ]; then
    printf '\n' >> "$ZSHRC"
  fi
fi
cat >> "$ZSHRC" <<'EOF'
# >>> DEV_MITOLENDA TERMINAL >>>
export STARSHIP_CONFIG="$HOME/.config/dev-mitolenda-terminal/starship.toml"
source "$HOME/.config/dev-mitolenda-terminal/mitolenda.zsh"
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi
# <<< DEV_MITOLENDA TERMINAL <<<
EOF

if command -v starship >/dev/null 2>&1; then
  STARSHIP_CONFIG="$CONFIG_DIR/starship.toml" starship prompt >/dev/null
fi

printf 'DEV_MITOLENDA Terminal installed. Backup: %s\n' "$backup_dir"
printf 'Select Space Mono Nerd Font in your terminal settings, then start a new Zsh session.\n'
