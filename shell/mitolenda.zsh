# DEV_MITOLENDA // Terminal helpers for Zsh

DEV_MITOLENDA_TERMINAL_VERSION="1.0.0"

mt() {
  local command="${1:-help}"
  local config_dir="$HOME/.config/dev-mitolenda-terminal"
  local missing=0

  case "$command" in
    help)
      cat <<'EOF'
DEV_MITOLENDA // Terminal

Usage: mt <command>
  help     Show this help
  status   Show the current project and prompt status
  git      Show Git branch and working-tree changes
  doctor   Check optional tools and installed files
  version  Show the installed version
EOF
      ;;
    status)
      print "DEV_MITOLENDA // STATUS"
      print "DIR: $(pwd)"
      if [[ -f "$config_dir/starship.toml" ]]; then
        print "PROMPT: configured"
      else
        print "PROMPT: configuration not found"
      fi
      if command -v starship >/dev/null 2>&1; then
        print "STARSHIP: $(starship --version 2>/dev/null | head -n 1)"
      else
        print "STARSHIP: not installed"
      fi
      ;;
    git)
      if ! command -v git >/dev/null 2>&1; then
        print -u2 "Git is not installed. Install Git to use mt git."
        return 1
      fi
      if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        print -u2 "Not a Git repository. Run mt git inside a project repository."
        return 1
      fi
      git status --short --branch
      ;;
    doctor)
      print "DEV_MITOLENDA // DOCTOR"
      if command -v zsh >/dev/null 2>&1; then
        print "ZSH: ok"
      else
        print "ZSH: missing"
        missing=1
      fi
      if command -v starship >/dev/null 2>&1; then
        print "STARSHIP: ok"
      else
        print "STARSHIP: missing"
        missing=1
      fi
      if command -v git >/dev/null 2>&1; then
        print "GIT: ok"
      else
        print "GIT: missing"
        missing=1
      fi
      if [[ -f "$config_dir/starship.toml" && -f "$config_dir/mitolenda.zsh" ]]; then
        print "CONFIG: ok"
      else
        print "CONFIG: missing"
        missing=1
      fi
      return "$missing"
      ;;
    version)
      print "DEV_MITOLENDA Terminal $DEV_MITOLENDA_TERMINAL_VERSION"
      ;;
    *)
      print -u2 "Unknown mt command: $command"
      mt help
      return 1
      ;;
  esac
}
