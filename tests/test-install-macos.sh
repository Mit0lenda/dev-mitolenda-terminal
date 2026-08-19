#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
test_home="$(mktemp -d)"
non_repo="$(mktemp -d)"
package_home="$(mktemp -d)"
trap 'rm -rf "$test_home" "$non_repo" "$package_home"' EXIT

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

assert_file() {
  [ -f "$1" ] || fail "expected file: $1"
}

assert_contains() {
  grep -Fq "$2" "$1" || fail "expected $1 to contain: $2"
}

zshrc="$test_home/.zshrc"
managed_dir="$test_home/.config/dev-mitolenda-terminal"
backup_dir="$test_home/.config/dev-mitolenda-terminal-backups"
start_marker='# >>> DEV_MITOLENDA TERMINAL >>>'
end_marker='# <<< DEV_MITOLENDA TERMINAL <<<'

printf '%s\n' '# SENTINEL: keep this setting' 'export EXISTING_SETTING=1' > "$zshrc"
chmod 644 "$zshrc"

MITOLENDA_TEST_HOME="$test_home" MITOLENDA_SKIP_PACKAGES=1 bash "$repo_root/install.sh"
cp "$zshrc" "$test_home/.zshrc.after-first-install"
MITOLENDA_TEST_HOME="$test_home" MITOLENDA_SKIP_PACKAGES=1 bash "$repo_root/install.sh"

assert_contains "$zshrc" '# SENTINEL: keep this setting'
cmp -s "$test_home/.zshrc.after-first-install" "$zshrc" || fail 'expected repeated install to leave .zshrc unchanged'
[ "$(stat -f '%Lp' "$zshrc")" = '644' ] || fail 'expected installer to preserve .zshrc permissions'
[ "$(grep -Fxc "$start_marker" "$zshrc")" -eq 1 ] || fail 'expected one start marker'
[ "$(grep -Fxc "$end_marker" "$zshrc")" -eq 1 ] || fail 'expected one end marker'
assert_file "$managed_dir/starship.toml"
assert_file "$managed_dir/mitolenda.zsh"
find "$backup_dir" -type f -name '.zshrc' -print -quit | grep -q . || fail 'expected a .zshrc backup'

version_output="$(HOME="$test_home" zsh -f -c 'source "$1"; mt version' zsh "$managed_dir/mitolenda.zsh")"
[ "$version_output" = 'DEV_MITOLENDA Terminal 1.0.0' ] || fail 'expected mt version output'
help_output="$(HOME="$test_home" zsh -f -c 'source "$1"; mt help' zsh "$managed_dir/mitolenda.zsh")"
printf '%s\n' "$help_output" | grep -Fq 'doctor   Check optional tools' || fail 'expected mt help output'
status_output="$(HOME="$test_home" zsh -f -c 'source "$1"; mt status' zsh "$managed_dir/mitolenda.zsh")"
printf '%s\n' "$status_output" | grep -Fq 'PROMPT: configured' || fail 'expected mt status output'
if doctor_output="$(HOME="$test_home" zsh -f -c 'source "$1"; mt doctor' zsh "$managed_dir/mitolenda.zsh" 2>&1)"; then
  :
fi
printf '%s\n' "$doctor_output" | grep -Fq 'DEV_MITOLENDA // DOCTOR' || fail 'expected mt doctor output'
printf '%s\n' "$doctor_output" | grep -Fq 'CONFIG: ok' || fail 'expected mt doctor config check'
git_repo="$test_home/git-repo"
git init -q "$git_repo"
git_success_output="$(cd "$git_repo" && HOME="$test_home" zsh -f -c 'source "$1"; mt git' zsh "$managed_dir/mitolenda.zsh")"
printf '%s\n' "$git_success_output" | grep -Fq '## ' || fail 'expected mt git status inside a repository'
if git_output="$(cd "$non_repo" && HOME="$test_home" zsh -f -c 'source "$1"; mt git' zsh "$managed_dir/mitolenda.zsh" 2>&1)"; then
  fail 'expected mt git to return nonzero outside a repository'
fi
printf '%s\n' "$git_output" | grep -Fq 'Not a Git repository' || fail 'expected helpful mt git error'

MITOLENDA_TEST_HOME="$test_home" bash "$repo_root/uninstall.sh"

assert_contains "$zshrc" '# SENTINEL: keep this setting'
if grep -Fq "$start_marker" "$zshrc" || grep -Fq "$end_marker" "$zshrc"; then
  fail 'expected uninstall to remove only the managed block'
fi
[ ! -e "$managed_dir" ] || fail 'expected managed directory to be removed'

mkdir -p "$managed_dir"
printf '%s\n' '# personal Starship configuration' > "$managed_dir/starship.toml"
MITOLENDA_TEST_HOME="$test_home" bash "$repo_root/uninstall.sh"
assert_file "$managed_dir/starship.toml"

fake_bin="$package_home/bin"
brew_log="$package_home/brew.log"
package_zshrc="$package_home/.zshrc"
mkdir -p "$fake_bin"
printf '%s\n' '#!/usr/bin/env bash' 'printf "%s\\n" "$*" >> "${MITOLENDA_BREW_LOG:?}"' 'exit 0' > "$fake_bin/brew"
chmod +x "$fake_bin/brew"
PATH="$fake_bin:/bin:/usr/bin" MITOLENDA_TEST_HOME="$package_home" MITOLENDA_BREW_LOG="$brew_log" /bin/bash "$repo_root/install.sh"
grep -Fqx 'install starship' "$brew_log" || fail 'expected Starship installation when its binary is absent'
MITOLENDA_TEST_HOME="$package_home" /bin/bash "$repo_root/uninstall.sh"

assert_malformed_block_is_preserved() {
  local name="$1"
  shift
  local case_home="$test_home/malformed-$name"
  local case_zshrc="$case_home/.zshrc"
  local case_config="$case_home/.config/dev-mitolenda-terminal"
  local install_output
  local uninstall_output

  mkdir -p "$case_config"
  printf '%s\n' "$@" > "$case_zshrc"
  cp "$case_zshrc" "$case_home/original.zshrc"
  cp "$repo_root/config/starship.toml" "$case_config/starship.toml"

  if install_output="$(MITOLENDA_TEST_HOME="$case_home" MITOLENDA_SKIP_PACKAGES=1 bash "$repo_root/install.sh" 2>&1)"; then
    fail "expected install to reject $name markers"
  fi
  cmp -s "$case_home/original.zshrc" "$case_zshrc" || fail "expected install to preserve $name .zshrc"
  printf '%s\n' "$install_output" | grep -Fq 'invalid managed block' || fail "expected install error for $name markers"

  if uninstall_output="$(MITOLENDA_TEST_HOME="$case_home" bash "$repo_root/uninstall.sh" 2>&1)"; then
    fail "expected uninstall to reject $name markers"
  fi
  cmp -s "$case_home/original.zshrc" "$case_zshrc" || fail "expected uninstall to preserve $name .zshrc"
  assert_file "$case_config/starship.toml"
  printf '%s\n' "$uninstall_output" | grep -Fq 'invalid managed block' || fail "expected uninstall error for $name markers"
}

assert_malformed_block_is_preserved nested \
  '# SENTINEL BEFORE' "$start_marker" 'managed content' "$start_marker" 'nested content' "$end_marker" '# SENTINEL AFTER'
assert_malformed_block_is_preserved unmatched_start \
  '# SENTINEL BEFORE' "$start_marker" 'managed content' '# SENTINEL AFTER'
assert_malformed_block_is_preserved unmatched_end \
  '# SENTINEL BEFORE' "$end_marker" '# SENTINEL AFTER'

printf 'PASS: macOS installer is idempotent and reversible\n'
