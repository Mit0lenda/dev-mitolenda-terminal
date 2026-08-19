#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EFFECTIVE_HOME="${MITOLENDA_TEST_HOME:-$HOME}"
CONFIG_DIR="$EFFECTIVE_HOME/.config/dev-mitolenda-terminal"
BACKUP_ROOT="$EFFECTIVE_HOME/.config/dev-mitolenda-terminal-backups"
ZSHRC="$EFFECTIVE_HOME/.zshrc"
source "$SCRIPT_DIR/shell/managed-block.sh"

die() {
  printf 'DEV_MITOLENDA installer: %s\n' "$*" >&2
  exit 1
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

validate_starship_config() {
  local validation_status

  command -v starship >/dev/null 2>&1 || return 0
  if STARSHIP_CONFIG="$SCRIPT_DIR/config/starship.toml" starship prompt >/dev/null; then
    return 0
  else
    validation_status=$?
  fi
  die "Starship validation failed with exit $validation_status before changing the profile or managed configuration."
}

if [ "${MITOLENDA_SKIP_PLATFORM_CHECK:-0}" != "1" ] && [ "$(uname -s)" != 'Darwin' ]; then
  die 'This installer supports macOS with Zsh. Use the Windows installer on Windows.'
fi

command -v zsh >/dev/null 2>&1 || die 'Zsh is required but was not found.'
mitolenda_validate_managed_blocks "$ZSHRC" || die 'Refusing to change .zshrc with invalid managed block markers.'
install_packages
validate_starship_config

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
mitolenda_remove_managed_blocks "$ZSHRC" || die 'Refusing to replace an invalid managed block in .zshrc.'
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

printf 'DEV_MITOLENDA Terminal installed. Backup: %s\n' "$backup_dir"
printf 'Select Space Mono Nerd Font in your terminal settings, then start a new Zsh session.\n'
