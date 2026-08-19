#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
candidate_list="$(mktemp)"
failures=0
trap 'rm -f "$candidate_list"' EXIT

git -C "$repo_root" ls-files -co --exclude-standard -z > "$candidate_list"

report_match() {
  local label="$1"
  local relative_path="$2"

  printf 'FAIL: %s found in %q\n' "$label" "$relative_path" >&2
  failures=$((failures + 1))
}

scan_fixed() {
  local label="$1"
  local needle="$2"
  local relative_path
  local absolute_path

  while IFS= read -r -d '' relative_path; do
    absolute_path="$repo_root/$relative_path"

    if [[ $relative_path == *"$needle"* ]]; then
      report_match "$label in path" "$relative_path"
    fi
    if [ -f "$absolute_path" ] && LC_ALL=C grep -Fq -- "$needle" "$absolute_path"; then
      report_match "$label in content" "$relative_path"
    fi
  done < "$candidate_list"
}

scan_regex() {
  local label="$1"
  local pattern="$2"
  local relative_path
  local absolute_path

  while IFS= read -r -d '' relative_path; do
    absolute_path="$repo_root/$relative_path"

    if printf '%s\n' "$relative_path" | LC_ALL=C grep -Eq -- "$pattern"; then
      report_match "$label in path" "$relative_path"
    fi
    if [ -f "$absolute_path" ] && LC_ALL=C grep -Eq -- "$pattern" "$absolute_path"; then
      report_match "$label in content" "$relative_path"
    fi
  done < "$candidate_list"
}

mac_home_pattern='/'"Us"'ers/'
windows_home_pattern='C:''\\+''Us''ers''\\+'
private_key_pattern='BE''GIN[[:space:]].*PRI''VATE[[:space:]]K''EY'
generic_api_key_pattern='(^|[^[:alnum:]_])s''k-'
classic_github_token_pattern='gh''p_'
fine_grained_github_token_pattern='github''_pat_'
aws_access_key_pattern='AK''IA'
slack_token_pattern='xo''x[baprs]-'
local_env_pattern='.''env.local'
configured_email="$(git -C "$repo_root" config --get user.email || true)"

scan_fixed 'absolute macOS home path' "$mac_home_pattern"
scan_regex 'absolute Windows home path' "$windows_home_pattern"
scan_regex 'private key header' "$private_key_pattern"
scan_regex 'generic API key prefix' "$generic_api_key_pattern"
scan_fixed 'classic GitHub token prefix' "$classic_github_token_pattern"
scan_fixed 'fine-grained GitHub token prefix' "$fine_grained_github_token_pattern"
scan_fixed 'AWS access key prefix' "$aws_access_key_pattern"
scan_regex 'Slack token prefix' "$slack_token_pattern"
scan_fixed 'local environment file reference' "$local_env_pattern"

if [ -n "$configured_email" ]; then
  scan_fixed 'configured Git email' "$configured_email"
fi

if [ "$failures" -ne 0 ]; then
  printf 'FAIL: security audit found %d forbidden match(es)\n' "$failures" >&2
  exit 1
fi

printf 'PASS: tracked and untracked repository files contain no forbidden public-release data\n'
