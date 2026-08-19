#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
install_script="${MITOLENDA_INSTALL_SCRIPT:-$repo_root/install.ps1}"
uninstall_script="${MITOLENDA_UNINSTALL_SCRIPT:-$repo_root/uninstall.ps1}"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

first_line_with_prefix() {
  awk -v prefix="$2" 'index($0, prefix) == 1 { print NR; exit }' "$1"
}

backup_line="$(first_line_with_prefix "$install_script" 'New-Item -ItemType Directory -Path $backupDir ')"
profile_backup_line="$(first_line_with_prefix "$install_script" '    Copy-Item -LiteralPath $profilePath -Destination ')"
config_backup_line="$(first_line_with_prefix "$install_script" '    Get-ChildItem -LiteralPath $configDir -Force | Copy-Item -Destination $managedBackup ')"
dependency_line="$(first_line_with_prefix "$install_script" 'Install-Dependencies')"
[ -n "$backup_line" ] || fail 'installer backup creation was not found'
[ -n "$profile_backup_line" ] || fail 'PowerShell profile backup copy was not found'
[ -n "$config_backup_line" ] || fail 'managed configuration backup copy was not found'
[ -n "$dependency_line" ] || fail 'dependency installation call was not found'
[ "$backup_line" -lt "$dependency_line" ] || fail 'backup must be created before dependency installation'
[ "$backup_line" -lt "$profile_backup_line" ] || fail 'PowerShell profile backup copy must follow backup directory creation'
[ "$profile_backup_line" -lt "$dependency_line" ] || fail 'PowerShell profile backup must be populated before dependency installation'
[ "$backup_line" -lt "$config_backup_line" ] || fail 'managed configuration backup copy must follow backup directory creation'
[ "$config_backup_line" -lt "$dependency_line" ] || fail 'managed configuration backup must be populated before dependency installation'

for script in "$install_script" "$uninstall_script"; do
  grep -Fq 'Get-ProfileFileState' "$script" || fail "missing encoding detection in $script"
  grep -Fq 'Write-ProfileFile' "$script" || fail "missing encoding-preserving profile write in $script"
  grep -Fq 'GetPreamble' "$script" || fail "missing BOM preservation in $script"
done

if grep -En 'settings\.json|LocalState|ConvertFrom-Json|ConvertTo-Json' "$install_script" "$uninstall_script"; then
  fail 'Windows Terminal JSON mutation path found'
fi
if grep -Ein 'winget[[:space:]]+uninstall' "$uninstall_script"; then
  fail 'uninstaller must not remove shared packages'
fi

printf 'PASS: Windows static safety contracts\n'
