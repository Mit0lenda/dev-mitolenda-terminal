#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
temp_root="$(mktemp -d)"
index_list="$temp_root/index-files"
untracked_list="$temp_root/untracked-files"
commit_list="$temp_root/commits"
tree_list="$temp_root/tree"
blob_file="$temp_root/blob"
commit_file="$temp_root/commit"
message_file="$temp_root/message"
path_file="$temp_root/path"
historical_blob_file="$temp_root/historical-blob"
failures=0
trap 'rm -rf "$temp_root"' EXIT

fatal() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

report_match() {
  local label="$1"
  local source="$2"
  local source_kind

  case "$source" in
    index:*) source_kind='index blob' ;;
    commit-message:*) source_kind='commit message' ;;
    commit:*) source_kind='historical blob' ;;
    untracked:*) source_kind='untracked candidate' ;;
    *) source_kind='repository candidate' ;;
  esac
  printf 'FAIL: %s found in %s\n' "$label" "$source_kind" >&2
  failures=$((failures + 1))
}

grep_fixed() {
  local needle="$1"
  local file="$2"
  local status

  if LC_ALL=C grep -Fq -- "$needle" "$file"; then
    return 0
  else
    status=$?
  fi
  [ "$status" -eq 1 ] || fatal "unable to scan $file"
  return 1
}

grep_regex() {
  local pattern="$1"
  local file="$2"
  local status

  if LC_ALL=C grep -Eq -- "$pattern" "$file"; then
    return 0
  else
    status=$?
  fi
  [ "$status" -eq 1 ] || fatal "unable to scan $file"
  return 1
}

grep_regex_insensitive() {
  local pattern="$1"
  local file="$2"
  local status

  if LC_ALL=C grep -Eiq -- "$pattern" "$file"; then
    return 0
  else
    status=$?
  fi
  [ "$status" -eq 1 ] || fatal "unable to scan $file"
  return 1
}

signature_documentation_path='docs/superpowers/plans/2026-08-18-dev-mitolenda-terminal.md'
mac_home_signature='/'"Us"'ers/'
windows_home_signature='C:'\\'Us'ers'\'
unix_personal_path_pattern='/('"Users"'|'"home"'|usr/'"home"'|var/'"home"'|'"root"')/[[:alnum:]_.-]+'
windows_personal_path_pattern='[[:alpha:]]:''\\+''Us''ers''\\+[[:alnum:]_.-]+'
private_key_pattern='BE''GIN[[:space:]].*PRI''VATE[[:space:]]K''EY'
generic_api_key_pattern='(^|[^[:alnum:]_])s''k-'
classic_github_token_pattern='gh''p_'
fine_grained_github_token_pattern='github''_pat_'
aws_access_key_pattern='AK''IA'
slack_token_pattern='xo''x[baprs]-'
credential_assignment_pattern='(^|[^[:alnum:]_])(pass''word|pass''wd|pwd|sec''ret|client[_-]?sec''ret|api[_-]?key|to''ken|auth[_-]?to''ken|access[_-]?to''ken)[[:space:]]*[:=][[:space:]]*[^[:space:]]+'
cookie_assignment_pattern='(^|[^[:alnum:]_])(coo''kie|set-coo''kie)[[:space:]]*[:=][[:space:]]*[^[:space:]]+'
email_pattern='[[:alnum:]._%+-]+@[[:alnum:].-]+\.[[:alpha:]]{2,}'
international_phone_pattern='(^|[^[:alnum:]])\+[1-9][0-9 .()_-]{7,}[0-9]($|[^[:alnum:]])'
domestic_phone_pattern='(^|[^0-9])(\([0-9]{2,3}\)[[:space:]-]*|[0-9]{2,3}[[:space:].-]+)[0-9]{3,5}[[:space:].-]+[0-9]{4}($|[^0-9])'
compact_phone_pattern='(^|[^0-9])[0-9]{10,15}($|[^0-9])'
environment_path_pattern='(^|/)\.''env[^/]*$'
shell_artifact_path_pattern='(^|/)(\.zsh_history|\.bash_history|\.fish_history|\.python_history|\.mysql_history|\.psql_history|\.node_repl_history|ConsoleHost_history\.txt|\.zshrc|\.bashrc|\.bash_profile|\.profile|config\.fish|\.gitconfig|\.config/git/config|Microsoft\.PowerShell_profile\.ps1|git-?config\.(txt|dump))$'
backup_path_pattern='(^|/)[^/]*[Bb]ackups?[^/]*(/|$)|(^|/)[^/]+\.(bak|backup|old|orig)$|(^|/)[^/]+~$'
zsh_history_content_pattern='^: [0-9]{9,}:[0-9]+;'
github_noreply_pattern='^[[:alnum:]._%+-]+@users[.]noreply[.]github[.]com$'
local_env_signature='.''env.local'
documentation_windows_home_signature='C:'"\\\\"'Us''ers'"\\\\"
documentation_private_key_signature='BE''GIN ... PRI''VATE K''EY'
documentation_generic_api_key_signature='s''k-'
signature_documentation_exact_line='O teste deve obter arquivos com `git ls-files -co --exclude-standard`, excluir a própria expressão de teste quando necessário e falhar ao encontrar `'
signature_documentation_exact_line+="$mac_home_signature"
signature_documentation_exact_line+='`, `'
signature_documentation_exact_line+="$documentation_windows_home_signature"
signature_documentation_exact_line+='`, `'
signature_documentation_exact_line+="$documentation_private_key_signature"
signature_documentation_exact_line+='`, `'
signature_documentation_exact_line+="$documentation_generic_api_key_signature"
signature_documentation_exact_line+='`, `'
signature_documentation_exact_line+="$classic_github_token_pattern"
signature_documentation_exact_line+='`, `'
signature_documentation_exact_line+="$fine_grained_github_token_pattern"
signature_documentation_exact_line+='`, `'
signature_documentation_exact_line+="$aws_access_key_pattern"
signature_documentation_exact_line+='`, `'
signature_documentation_exact_line+="$slack_token_pattern"
signature_documentation_exact_line+='`, `'
signature_documentation_exact_line+="$local_env_signature"
signature_documentation_exact_line+='` ou o e-mail configurado em `git config user.email`.'

local_username="${MITOLENDA_SECURITY_USERNAME:-$(id -un 2>/dev/null || true)}"
local_hostname="${MITOLENDA_SECURITY_HOSTNAME:-$(hostname 2>/dev/null || true)}"
local_home="${HOME:-}"
if configured_email="$(git -C "$repo_root" config --get user.email 2>/dev/null)"; then
  :
else
  config_status=$?
  [ "$config_status" -eq 1 ] || fatal 'unable to read configured Git email'
  configured_email=''
fi

scan_fixed_content() {
  local label="$1"
  local needle="$2"
  local file="$3"
  local source="$4"

  [ -n "$needle" ] || return 0
  if grep_fixed "$needle" "$file"; then
    report_match "$label" "$source"
  fi
}

scan_regex_content() {
  local label="$1"
  local pattern="$2"
  local file="$3"
  local source="$4"

  if grep_regex "$pattern" "$file"; then
    report_match "$label" "$source"
  fi
}

scan_regex_content_insensitive() {
  local label="$1"
  local pattern="$2"
  local file="$3"
  local source="$4"

  if grep_regex_insensitive "$pattern" "$file"; then
    report_match "$label" "$source"
  fi
}

scan_path() {
  local relative_path="$1"
  local source="$2"

  if [[ $relative_path =~ $environment_path_pattern ]]; then
    report_match 'environment file' "$source"
  fi
  if [[ $relative_path =~ $shell_artifact_path_pattern ]]; then
    report_match 'shell history or configuration dump' "$source"
  fi
  if [[ $relative_path =~ $backup_path_pattern ]]; then
    report_match 'backup artifact' "$source"
  fi
  printf '%s\n' "$relative_path" > "$path_file" || fatal 'unable to prepare repository path for scanning'
  scan_content "$path_file" "$source"
}

scan_content() {
  local file="$1"
  local source="$2"

  scan_regex_content 'absolute personal path' "$unix_personal_path_pattern" "$file" "$source"
  scan_regex_content 'absolute personal path' "$windows_personal_path_pattern" "$file" "$source"
  scan_fixed_content 'absolute personal path' "$local_home" "$file" "$source"
  scan_regex_content_insensitive 'password or secret assignment' "$credential_assignment_pattern" "$file" "$source"
  scan_regex_content_insensitive 'cookie assignment' "$cookie_assignment_pattern" "$file" "$source"
  scan_regex_content 'private email address' "$email_pattern" "$file" "$source"
  scan_regex_content 'phone number' "$international_phone_pattern" "$file" "$source"
  scan_regex_content 'phone number' "$domestic_phone_pattern" "$file" "$source"
  scan_regex_content 'phone number' "$compact_phone_pattern" "$file" "$source"
  scan_regex_content 'shell history or configuration dump' "$zsh_history_content_pattern" "$file" "$source"
  scan_fixed_content 'configured Git email' "$configured_email" "$file" "$source"

  if [ -n "$local_username" ] && [ "$local_username" != 'root' ]; then
    scan_fixed_content 'local username' "$local_username" "$file" "$source"
  fi
  if [ -n "$local_hostname" ] && [ "$local_hostname" != 'localhost' ]; then
    scan_fixed_content 'local hostname' "$local_hostname" "$file" "$source"
    if [[ $local_hostname == *.* ]]; then
      scan_fixed_content 'local hostname' "${local_hostname%%.*}" "$file" "$source"
    fi
  fi

  scan_fixed_content 'absolute personal path signature' "$mac_home_signature" "$file" "$source"
  scan_fixed_content 'absolute personal path signature' "$windows_home_signature" "$file" "$source"
  scan_regex_content 'private key header' "$private_key_pattern" "$file" "$source"
  scan_regex_content 'generic API key prefix' "$generic_api_key_pattern" "$file" "$source"
  scan_fixed_content 'classic GitHub token prefix' "$classic_github_token_pattern" "$file" "$source"
  scan_fixed_content 'fine-grained GitHub token prefix' "$fine_grained_github_token_pattern" "$file" "$source"
  scan_fixed_content 'AWS access key prefix' "$aws_access_key_pattern" "$file" "$source"
  scan_regex_content 'Slack token prefix' "$slack_token_pattern" "$file" "$source"
  scan_fixed_content 'local environment file reference' "$local_env_signature" "$file" "$source"
}

filter_historical_signature_documentation() {
  local line

  : > "$historical_blob_file"
  while IFS= read -r line || [ -n "$line" ]; do
    if [ "$line" = "$signature_documentation_exact_line" ]; then
      continue
    fi
    printf '%s\n' "$line" >> "$historical_blob_file" || fatal 'unable to filter historical signature documentation'
  done < "$blob_file"
}

read_git_blob() {
  local object_id="$1"
  local source="$2"

  if ! git -C "$repo_root" cat-file blob "$object_id" > "$blob_file"; then
    fatal 'unable to read Git blob from repository candidate'
  fi
}

scan_index() {
  local entry
  local metadata
  local relative_path
  local mode
  local object_id
  local stage
  local source

  if ! git -C "$repo_root" ls-files -s -z > "$index_list"; then
    fatal 'unable to enumerate index blobs'
  fi

  while IFS= read -r -d '' entry; do
    metadata="${entry%%$'\t'*}"
    relative_path="${entry#*$'\t'}"
    IFS=' ' read -r mode object_id stage <<< "$metadata"
    [ "$stage" = '0' ] || fatal 'unmerged index entry found'
    source="index:$relative_path"
    scan_path "$relative_path" "$source"
    read_git_blob "$object_id" "$source"
    scan_content "$blob_file" "$source"
  done < "$index_list"
}

scan_commit() {
  local commit_id="$1"
  local entry
  local metadata
  local relative_path
  local mode
  local object_type
  local object_id
  local source
  local header_line
  local metadata_email

  if ! git -C "$repo_root" cat-file commit "$commit_id" > "$commit_file"; then
    fatal "unable to read Git commit $commit_id"
  fi

  while IFS= read -r header_line && [ -n "$header_line" ]; do
    case "$header_line" in
      author\ *\<*\>*|committer\ *\<*\>*)
        metadata_email="${header_line##*<}"
        metadata_email="${metadata_email%%>*}"
        if [[ ! $metadata_email =~ $github_noreply_pattern ]]; then
          report_match 'private email address in Git metadata' "commit:$commit_id"
        fi
        ;;
    esac
  done < "$commit_file"

  awk 'message { print } /^$/ { message = 1 }' "$commit_file" > "$message_file" || fatal "unable to extract Git commit message $commit_id"
  scan_content "$message_file" "commit-message:$commit_id"

  if ! git -C "$repo_root" ls-tree -r -z "$commit_id" > "$tree_list"; then
    fatal "unable to enumerate Git tree $commit_id"
  fi
  while IFS= read -r -d '' entry; do
    metadata="${entry%%$'\t'*}"
    relative_path="${entry#*$'\t'}"
    IFS=' ' read -r mode object_type object_id <<< "$metadata"
    [ "$object_type" = 'blob' ] || fatal "unexpected Git object type in $commit_id: $object_type"
    source="commit:$commit_id:$relative_path"
    scan_path "$relative_path" "$source"
    read_git_blob "$object_id" "$source"
    if [ "$relative_path" = "$signature_documentation_path" ]; then
      filter_historical_signature_documentation
      scan_content "$historical_blob_file" "$source"
    else
      scan_content "$blob_file" "$source"
    fi
  done < "$tree_list"
}

scan_history() {
  local commit_id

  if ! git -C "$repo_root" rev-list HEAD > "$commit_list"; then
    fatal 'unable to enumerate Git history intended for push'
  fi
  [ -s "$commit_list" ] || fatal 'Git history intended for push is empty'
  while IFS= read -r commit_id; do
    scan_commit "$commit_id"
  done < "$commit_list"
}

scan_untracked() {
  local relative_path
  local absolute_path
  local source

  if ! git -C "$repo_root" ls-files -o --exclude-standard -z > "$untracked_list"; then
    fatal 'unable to enumerate untracked worktree candidates'
  fi
  while IFS= read -r -d '' relative_path; do
    absolute_path="$repo_root/$relative_path"
    source="untracked:$relative_path"
    scan_path "$relative_path" "$source"
    if [ -L "$absolute_path" ]; then
      readlink "$absolute_path" > "$blob_file" || fatal 'unable to read untracked symlink'
    elif [ -f "$absolute_path" ]; then
      cp "$absolute_path" "$blob_file" || fatal 'unable to read untracked file'
    else
      fatal 'unsupported untracked candidate'
    fi
    scan_content "$blob_file" "$source"
  done < "$untracked_list"
}

git -C "$repo_root" rev-parse --verify HEAD^{commit} >/dev/null 2>&1 || fatal 'HEAD is not a readable Git commit'
scan_index
scan_history
scan_untracked

if [ "$failures" -ne 0 ]; then
  printf 'FAIL: security audit found %d forbidden match(es)\n' "$failures" >&2
  exit 1
fi

printf 'PASS: index blobs, full push history, and untracked repository candidates are safe for public release\n'
