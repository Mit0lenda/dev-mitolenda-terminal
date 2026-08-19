#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
install_script="${MITOLENDA_INSTALL_SCRIPT:-$repo_root/install.ps1}"
uninstall_script="${MITOLENDA_UNINSTALL_SCRIPT:-$repo_root/uninstall.ps1}"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

backup_line="$(rg -n -m 1 '^New-Item -ItemType Directory -Path \$backupDir ' "$install_script" | cut -d: -f1)"
profile_backup_line="$(rg -n -m 1 '^    Copy-Item -LiteralPath \$profilePath -Destination ' "$install_script" | cut -d: -f1)"
config_backup_line="$(rg -n -m 1 '^    Get-ChildItem -LiteralPath \$configDir -Force \| Copy-Item -Destination \$managedBackup ' "$install_script" | cut -d: -f1)"
dependency_line="$(rg -n -m 1 '^Install-Dependencies$' "$install_script" | cut -d: -f1)"
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
  rg -q 'Get-ProfileFileState' "$script" || fail "missing encoding detection in $script"
  rg -q 'Write-ProfileFile' "$script" || fail "missing encoding-preserving profile write in $script"
  rg -q 'GetPreamble' "$script" || fail "missing BOM preservation in $script"
done

if rg -n 'settings\.json|LocalState|ConvertFrom-Json|ConvertTo-Json' "$install_script" "$uninstall_script"; then
  fail 'Windows Terminal JSON mutation path found'
fi
if rg -n -i 'winget[[:space:]]+uninstall' "$uninstall_script"; then
  fail 'uninstaller must not remove shared packages'
fi

printf 'PASS: Windows static safety contracts\n'
