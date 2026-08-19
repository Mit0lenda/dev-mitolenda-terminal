#!/usr/bin/env bash

MITOLENDA_BLOCK_START='# >>> DEV_MITOLENDA TERMINAL >>>'
MITOLENDA_BLOCK_END='# <<< DEV_MITOLENDA TERMINAL <<<'

mitolenda_validate_managed_blocks() {
  local target="$1"

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
  local temporary

  [ -f "$target" ] || return 0
  mitolenda_validate_managed_blocks "$target" || return 1
  temporary="$(mktemp "${target}.mitolenda.XXXXXX")"
  cp -p "$target" "$temporary"
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
  ' "$target" > "$temporary"
  mv "$temporary" "$target"
}
