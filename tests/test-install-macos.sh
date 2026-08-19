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

selective_home="$test_home/selective-uninstall"
selective_config="$selective_home/.config/dev-mitolenda-terminal"
mkdir -p "$selective_config"
cp "$repo_root/config/starship.toml" "$selective_config/starship.toml"
cp "$repo_root/shell/mitolenda.zsh" "$selective_config/mitolenda.zsh"
printf '%s\n' '# user customization' >> "$selective_config/mitolenda.zsh"
printf '%s\n' 'keep this unrelated file' > "$selective_config/notes.txt"
MITOLENDA_TEST_HOME="$selective_home" bash "$repo_root/uninstall.sh"
[ ! -e "$selective_config/starship.toml" ] || fail 'expected uninstall to remove the unchanged known Starship configuration'
assert_file "$selective_config/mitolenda.zsh"
assert_contains "$selective_config/mitolenda.zsh" '# user customization'
assert_file "$selective_config/notes.txt"
[ -d "$selective_config" ] || fail 'expected uninstall to preserve a non-empty managed directory'

symlink_home="$test_home/symlink-profile"
symlink_target_dir="$symlink_home/profile-files"
symlink_target="$symlink_target_dir/zshrc"
symlink_zshrc="$symlink_home/.zshrc"
mkdir -p "$symlink_target_dir"
printf '%s\n' '# SYMLINK SENTINEL' 'export SYMLINK_SETTING=1' > "$symlink_target"
cp "$symlink_target" "$symlink_home/original-target"
ln -s 'profile-files/zshrc' "$symlink_zshrc"
MITOLENDA_TEST_HOME="$symlink_home" MITOLENDA_SKIP_PACKAGES=1 bash "$repo_root/install.sh"
[ -L "$symlink_zshrc" ] || fail 'expected install to preserve the .zshrc symlink'
[ "$(readlink "$symlink_zshrc")" = 'profile-files/zshrc' ] || fail 'expected install to preserve the .zshrc symlink destination'
assert_contains "$symlink_target" "$start_marker"
MITOLENDA_TEST_HOME="$symlink_home" bash "$repo_root/uninstall.sh"
[ -L "$symlink_zshrc" ] || fail 'expected uninstall to preserve the .zshrc symlink'
[ "$(readlink "$symlink_zshrc")" = 'profile-files/zshrc' ] || fail 'expected uninstall to preserve the .zshrc symlink destination'
cmp -s "$symlink_home/original-target" "$symlink_target" || fail 'expected uninstall to remove only the managed block from the symlink target'

failure_home="$test_home/starship-prevalidation-failure"
failure_config="$failure_home/.config/dev-mitolenda-terminal"
failure_bin="$failure_home/bin"
mkdir -p "$failure_config" "$failure_bin"
printf '%s\n' '# FAILURE SENTINEL' 'export FAILURE_SETTING=1' > "$failure_home/.zshrc"
printf '%s\n' 'existing config must survive' > "$failure_config/starship.toml"
printf '%s\n' 'existing helper must survive' > "$failure_config/mitolenda.zsh"
cp "$failure_home/.zshrc" "$failure_home/original.zshrc"
cp "$failure_config/starship.toml" "$failure_home/original.starship.toml"
cp "$failure_config/mitolenda.zsh" "$failure_home/original.mitolenda.zsh"
printf '%s\n' '#!/usr/bin/env bash' 'exit 23' > "$failure_bin/starship"
chmod +x "$failure_bin/starship"
if failure_output="$(PATH="$failure_bin:$PATH" MITOLENDA_TEST_HOME="$failure_home" MITOLENDA_SKIP_PACKAGES=1 bash "$repo_root/install.sh" 2>&1)"; then
  fail 'expected install to stop when Starship rejects the source configuration'
fi
printf '%s\n' "$failure_output" | grep -Fq 'before changing the profile or managed configuration' || fail 'expected a prevalidation failure message'
cmp -s "$failure_home/original.zshrc" "$failure_home/.zshrc" || fail 'expected Starship prevalidation failure to preserve .zshrc'
cmp -s "$failure_home/original.starship.toml" "$failure_config/starship.toml" || fail 'expected Starship prevalidation failure to preserve existing configuration'
cmp -s "$failure_home/original.mitolenda.zsh" "$failure_config/mitolenda.zsh" || fail 'expected Starship prevalidation failure to preserve existing helper'

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
