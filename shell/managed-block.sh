#!/usr/bin/env bash

MITOLENDA_BLOCK_START='# >>> DEV_MITOLENDA TERMINAL >>>'
MITOLENDA_BLOCK_END='# <<< DEV_MITOLENDA TERMINAL <<<'

mitolenda_resolve_edit_target() {
  local target="$1"
  local link_target
  local target_parent
  local depth=0

  while [ -L "$target" ]; do
    if [ "$depth" -ge 40 ]; then
      printf 'DEV_MITOLENDA: refusing to edit %s: symbolic-link chain is too deep\n' "$1" >&2
      return 1
    fi
    link_target="$(readlink "$target")" || {
      printf 'DEV_MITOLENDA: refusing to edit %s: symbolic-link destination could not be read\n' "$1" >&2
      return 1
    }
    case "$link_target" in
      /*) target="$link_target" ;;
      *) target="$(dirname "$target")/$link_target" ;;
    esac
    depth=$((depth + 1))
  done

  if [ ! -f "$target" ]; then
    printf 'DEV_MITOLENDA: refusing to edit %s: symbolic link does not resolve to a regular file\n' "$1" >&2
    return 1
  fi
  target_parent="$(cd -P "$(dirname "$target")" && pwd)" || return 1
  printf '%s/%s\n' "$target_parent" "$(basename "$target")"
}

mitolenda_validate_managed_blocks() {
  local target="$1"

  if [ -L "$target" ] && [ ! -f "$target" ]; then
    printf 'DEV_MITOLENDA: refusing to edit %s: symbolic link does not resolve to a regular file\n' "$target" >&2
    return 1
  fi
  [ -f "$target" ] || return 0
  awk -v start="$MITOLENDA_BLOCK_START" -v end="$MITOLENDA_BLOCK_END" '
    $0 == start {
      if (inside) {
        print "DEV_MITOLENDA: invalid managed block in " FILENAME ": nested opening marker" > "/dev/stderr"
        invalid = 1
        exit 1
      }
      inside = 1
      next
    }
    $0 == end {
      if (!inside) {
        print "DEV_MITOLENDA: invalid managed block in " FILENAME ": closing marker without an opening marker" > "/dev/stderr"
        invalid = 1
        exit 1
      }
      inside = 0
    }
    END {
      if (!invalid && inside) {
        print "DEV_MITOLENDA: invalid managed block in " FILENAME ": opening marker without a closing marker" > "/dev/stderr"
        exit 1
      }
    }
  ' "$target"
}

mitolenda_remove_managed_blocks() {
  local target="$1"
  local edit_target
  local temporary

  [ -f "$target" ] || return 0
  mitolenda_validate_managed_blocks "$target" || return 1
  edit_target="$(mitolenda_resolve_edit_target "$target")" || return 1
  temporary="$(mktemp "${edit_target}.mitolenda.XXXXXX")"
  cp -p "$edit_target" "$temporary"
  awk -v start="$MITOLENDA_BLOCK_START" -v end="$MITOLENDA_BLOCK_END" '
    $0 == start {
      inside = 1
      next
    }
    $0 == end {
      inside = 0
      next
    }
    !inside { print }
  ' "$edit_target" > "$temporary"
  mv "$temporary" "$edit_target"
}
