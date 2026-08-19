#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
scanner="$repo_root/tests/test-security.sh"
test_root="$(mktemp -d)"
fixture_git_email='113867356+Mit0lenda@users''.''noreply.github.com'
real_git="$(command -v git)"
trap 'rm -rf "$test_root"' EXIT

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

decode_base64() {
  local encoded="$1"
  local decoded

  if decoded="$(printf '%s' "$encoded" | base64 --decode 2>/dev/null)"; then
    printf '%s' "$decoded"
    return 0
  fi
  if decoded="$(printf '%s' "$encoded" | base64 -D 2>/dev/null)"; then
    printf '%s' "$decoded"
    return 0
  fi
  fail 'base64 decoder unavailable'
}

initialize_case() {
  local name="$1"

  case_repo="$test_root/$name"
  mkdir -p "$case_repo/tests"
  git -C "$case_repo" init --quiet
  git -C "$case_repo" config user.name 'Nicollas Freitas'
  git -C "$case_repo" config user.email "$fixture_git_email"
  cp "$scanner" "$case_repo/tests/test-security.sh"
  git -C "$case_repo" add tests/test-security.sh
  git -C "$case_repo" commit --quiet -m 'base fixture'
  git -C "$case_repo" branch -M main
  git -C "$case_repo" switch --quiet -c feature
}

assert_rejected() {
  local name="$1"
  local expected="$2"
  shift 2
  local output_file="$test_root/$name.output"

  if "$@" >"$output_file" 2>&1; then
    fail "$name fixture was accepted"
  fi
  grep -Fq -- "$expected" "$output_file" || fail "$name failed for the wrong reason"
  printf 'PASS fixture: %s\n' "$name"
}

assert_rejected_without_value() {
  local name="$1"
  local expected="$2"
  local forbidden_value="$3"
  shift 3
  local output_file="$test_root/$name.output"

  if "$@" >"$output_file" 2>&1; then
    fail "$name fixture was accepted"
  fi
  grep -Fq -- "$expected" "$output_file" || fail "$name failed for the wrong reason"
  if grep -Fq -- "$forbidden_value" "$output_file"; then
    fail "$name leaked the configured private value"
  fi
  printf 'PASS fixture: %s\n' "$name"
}

assert_content_rejected() {
  local name="$1"
  local expected="$2"
  local payload="$3"

  initialize_case "$name"
  printf '%s\n' "$payload" > "$case_repo/candidate.txt"
  git -C "$case_repo" add candidate.txt
  git -C "$case_repo" commit --quiet -m "add $name fixture"
  assert_rejected "$name" "$expected" bash "$case_repo/tests/test-security.sh"
}

assert_content_rejected_with_identity() {
  local name="$1"
  local expected="$2"
  local payload="$3"
  local fixture_username="$4"
  local fixture_hostname="$5"

  initialize_case "$name"
  printf '%s\n' "$payload" > "$case_repo/candidate.txt"
  git -C "$case_repo" add candidate.txt
  git -C "$case_repo" commit --quiet -m "add $name fixture"
  assert_rejected "$name" "$expected" env \
    MITOLENDA_SECURITY_USERNAME="$fixture_username" \
    MITOLENDA_SECURITY_HOSTNAME="$fixture_hostname" \
    bash "$case_repo/tests/test-security.sh"
}

assert_path_rejected() {
  local name="$1"
  local expected="$2"
  local relative_path="$3"

  initialize_case "$name"
  mkdir -p "$(dirname "$case_repo/$relative_path")"
  printf 'safe fixture content\n' > "$case_repo/$relative_path"
  git -C "$case_repo" add "$relative_path"
  git -C "$case_repo" commit --quiet -m "add $name fixture"
  assert_rejected "$name" "$expected" bash "$case_repo/tests/test-security.sh"
}

assert_content_rejected \
  password-assignment \
  'password or secret assignment' \
  'pass''word = "fixture-value"'
assert_content_rejected \
  generic-token-assignment \
  'password or secret assignment' \
  'to''ken = fixture-value'
assert_content_rejected \
  cookie-assignment \
  'cookie assignment' \
  'Coo''kie: session=fixture-value'
assert_content_rejected \
  private-email \
  'private email address' \
  'private.person@exa''mple.test'
assert_content_rejected \
  international-phone \
  'phone number' \
  '+55 11 9''8765-4321'
assert_content_rejected \
  domestic-phone \
  'phone number' \
  '(11) 9''8765-4321'
assert_content_rejected \
  compact-phone \
  'phone number' \
  '11987''654321'
assert_content_rejected_with_identity \
  local-username \
  'local username' \
  'fixture-local-user' \
  'fixture-local-user' \
  'safe-host.example'
assert_content_rejected_with_identity \
  local-hostname \
  'local hostname' \
  'fixture-host.local' \
  'safe-local-user' \
  'fixture-host.local'
assert_content_rejected \
  macos-home-path \
  'absolute personal path' \
  '/'"Us"'ers/fixture-user/project'
assert_content_rejected \
  macos-home-signature \
  'absolute personal path signature' \
  '/'"Us"'ers/'
assert_content_rejected \
  windows-home-path \
  'absolute personal path' \
  'D:'"\\"'Us''ers'"\\"'fixture-user'"\\"'project'
assert_content_rejected \
  windows-home-signature \
  'absolute personal path signature' \
  'C:'"\\"'Us''ers'"\\"
assert_content_rejected \
  linux-home-path \
  'absolute personal path' \
  '/ho''me/fixture-user/project'
assert_content_rejected \
  root-home-path \
  'absolute personal path' \
  '/ro''ot/private-project'
assert_content_rejected \
  var-home-path \
  'absolute personal path' \
  '/var/ho''me/fixture-user/project'
assert_content_rejected \
  private-key-header \
  'private key header' \
  'BE''GIN OPENSSH PRI''VATE K''EY'
assert_content_rejected \
  generic-api-token \
  'generic API key prefix' \
  's''k-fixture-token'
assert_content_rejected \
  classic-github-token \
  'classic GitHub token prefix' \
  'gh''p_fixture-token'
assert_content_rejected \
  fine-grained-github-token \
  'fine-grained GitHub token prefix' \
  'github''_pat_fixture-token'
assert_content_rejected \
  aws-access-key \
  'AWS access key prefix' \
  'AK''IAFIXTURETOKEN'
assert_content_rejected \
  slack-token \
  'Slack token prefix' \
  'xo''xb-fixture-token'

assert_path_rejected \
  token-in-filename \
  'classic GitHub token prefix' \
  'gh''p_path-secret'
assert_path_rejected \
  credential-in-filename \
  'password or secret assignment' \
  'pass''word=path-secret'
assert_path_rejected \
  cookie-in-filename \
  'cookie assignment' \
  'Coo''kie=session-secret'
assert_path_rejected \
  email-in-filename \
  'private email address' \
  'private.person@exa''mple.test'
assert_path_rejected \
  phone-in-filename \
  'phone number' \
  '+55119''87654321'
assert_path_rejected \
  private-key-in-filename \
  'private key header' \
  'BE''GIN RSA PRI''VATE K''EY'

assert_path_rejected env-file 'environment file' '.''env'
assert_path_rejected env-local-file 'environment file' '.''env.local'
assert_path_rejected env-production-file 'environment file' '.''env.production'
assert_path_rejected envrc-file 'environment file' '.''envrc'
assert_path_rejected env-hyphen-file 'environment file' '.''env-production'
assert_content_rejected \
  env-local-reference \
  'local environment file reference' \
  'source ./''.''env.local'
assert_path_rejected shell-history 'shell history or configuration dump' '.''zsh_history'
assert_path_rejected shell-profile 'shell history or configuration dump' '.''zshrc'
assert_path_rejected fish-profile 'shell history or configuration dump' 'config.fish'
assert_path_rejected git-config-dump 'shell history or configuration dump' '.''gitconfig'
assert_path_rejected nested-git-config-dump 'shell history or configuration dump' '.config/git/config'
assert_path_rejected powershell-history 'shell history or configuration dump' 'ConsoleHost_history.txt'
assert_path_rejected backup-directory 'backup artifact' 'backups/profile.txt'
assert_path_rejected installer-backup-directory 'backup artifact' '.config/dev-terminal-backups/profile.txt'
assert_path_rejected backup-extension 'backup artifact' 'profile.bak'

assert_content_rejected \
  zsh-history-content \
  'shell history or configuration dump' \
  ': 1690000''000:0;print private-command'

initialize_case private-git-metadata
private_metadata_email='private.person@exa''mple.test'
git -C "$case_repo" config user.email "$private_metadata_email"
printf 'safe fixture content\n' > "$case_repo/metadata.txt"
git -C "$case_repo" add metadata.txt
git -C "$case_repo" commit --quiet -m 'add private metadata fixture'
git -C "$case_repo" config user.email "$fixture_git_email"
assert_rejected \
  private-git-metadata \
  'private email address in Git metadata' \
  bash "$case_repo/tests/test-security.sh"

initialize_case unintended-noreply-metadata
git -C "$case_repo" config user.email 'unintended@users''.''noreply.github.com'
printf 'safe fixture content\n' > "$case_repo/metadata.txt"
git -C "$case_repo" add metadata.txt
git -C "$case_repo" commit --quiet -m 'add unintended noreply metadata fixture'
git -C "$case_repo" config user.email "$fixture_git_email"
assert_rejected \
  unintended-noreply-metadata \
  'unexpected public identity in Git metadata' \
  bash "$case_repo/tests/test-security.sh"

initialize_case unintended-author-name
git -C "$case_repo" config user.name 'Unintended Local Identity'
printf 'safe fixture content\n' > "$case_repo/metadata.txt"
git -C "$case_repo" add metadata.txt
git -C "$case_repo" commit --quiet -m 'add unintended author name fixture'
git -C "$case_repo" config user.name 'Nicollas Freitas'
assert_rejected \
  unintended-author-name \
  'unexpected public identity in Git metadata' \
  bash "$case_repo/tests/test-security.sh"

initialize_case configured-email-content
configured_private_email='owner@local''host'
git -C "$case_repo" config user.email "$configured_private_email"
printf '%s\n' "$configured_private_email" > "$case_repo/configured-email.txt"
git -C "$case_repo" add configured-email.txt
assert_rejected_without_value \
  configured-email-content \
  'configured Git email' \
  "$configured_private_email" \
  bash "$case_repo/tests/test-security.sh"

initialize_case configured-email-filename
configured_private_email='owner@local''host'
git -C "$case_repo" config user.email "$configured_private_email"
printf 'safe fixture content\n' > "$case_repo/$configured_private_email"
git -C "$case_repo" add "$configured_private_email"
assert_rejected_without_value \
  configured-email-filename \
  'configured Git email' \
  "$configured_private_email" \
  bash "$case_repo/tests/test-security.sh"

documentation_path='docs/superpowers/plans/2026-08-18-dev-mitolenda-terminal.md'
historical_contract_line="$(decode_base64 'TyB0ZXN0ZSBkZXZlIG9idGVyIGFycXVpdm9zIGNvbSBgZ2l0IGxzLWZpbGVzIC1jbyAtLWV4Y2x1ZGUtc3RhbmRhcmRgLCBleGNsdWlyIGEgcHLDs3ByaWEgZXhwcmVzc8OjbyBkZSB0ZXN0ZSBxdWFuZG8gbmVjZXNzw6FyaW8gZSBmYWxoYXIgYW8gZW5jb250cmFyIGAvVXNlcnMvYCwgYEM6XFxVc2Vyc1xcYCwgYEJFR0lOIC4uLiBQUklWQVRFIEtFWWAsIGBzay1gLCBgZ2hwX2AsIGBnaXRodWJfcGF0X2AsIGBBS0lBYCwgYHhveFtiYXByc10tYCwgYC5lbnYubG9jYWxgIG91IG8gZS1tYWlsIGNvbmZpZ3VyYWRvIGVtIGBnaXQgY29uZmlnIHVzZXIuZW1haWxgLgo=')"

initialize_case documentation-path-index
mkdir -p "$(dirname "$case_repo/$documentation_path")"
printf '%s\n' 'gh''p_index-documentation-secret' > "$case_repo/$documentation_path"
git -C "$case_repo" add "$documentation_path"
assert_rejected \
  documentation-path-index \
  'classic GitHub token prefix' \
  bash "$case_repo/tests/test-security.sh"

initialize_case documentation-path-untracked
mkdir -p "$(dirname "$case_repo/$documentation_path")"
printf '%s\n' 'gh''p_untracked-documentation-secret' > "$case_repo/$documentation_path"
assert_rejected \
  documentation-path-untracked \
  'classic GitHub token prefix' \
  bash "$case_repo/tests/test-security.sh"

initialize_case historical-documentation-signature
mkdir -p "$(dirname "$case_repo/$documentation_path")"
printf '%s\n' "$historical_contract_line" > "$case_repo/$documentation_path"
git -C "$case_repo" add "$documentation_path"
git -C "$case_repo" commit --quiet -m 'add historical documentation signature'
printf 'Encoded historical signature documentation\n' > "$case_repo/$documentation_path"
git -C "$case_repo" add "$documentation_path"
git -C "$case_repo" commit --quiet -m 'encode historical documentation signature'
bash "$case_repo/tests/test-security.sh" >/dev/null || fail 'historical documentation signature was rejected'
printf 'PASS fixture: historical-documentation-signature\n'

initialize_case historical-documentation-appended-secret
mkdir -p "$(dirname "$case_repo/$documentation_path")"
appended_secret='gh''p_appended-secret'
printf '%s\n' "$historical_contract_line $appended_secret" > "$case_repo/$documentation_path"
git -C "$case_repo" add "$documentation_path"
git -C "$case_repo" commit --quiet -m 'append secret after historical contract'
printf 'Encoded historical signature documentation\n' > "$case_repo/$documentation_path"
git -C "$case_repo" add "$documentation_path"
git -C "$case_repo" commit --quiet -m 'remove appended historical secret'
assert_rejected \
  historical-documentation-appended-secret \
  'classic GitHub token prefix' \
  bash "$case_repo/tests/test-security.sh"

initialize_case historical-documentation-embedded-secret
mkdir -p "$(dirname "$case_repo/$documentation_path")"
embedded_secret='gh''p_embedded-secret'
historical_embedded_line="${historical_contract_line/ e falhar / $embedded_secret e falhar }"
printf '%s\n' "$historical_embedded_line" > "$case_repo/$documentation_path"
git -C "$case_repo" add "$documentation_path"
git -C "$case_repo" commit --quiet -m 'embed secret in historical contract'
printf 'Encoded historical signature documentation\n' > "$case_repo/$documentation_path"
git -C "$case_repo" add "$documentation_path"
git -C "$case_repo" commit --quiet -m 'remove embedded historical secret'
assert_rejected \
  historical-documentation-embedded-secret \
  'classic GitHub token prefix' \
  bash "$case_repo/tests/test-security.sh"

initialize_case historical-documentation-prefix-only
mkdir -p "$(dirname "$case_repo/$documentation_path")"
printf '%s\n' \
  'O teste deve obter arquivos com `git ls-files -co --exclude-standard` e conter gh''p_ fora do contrato completo.' \
  > "$case_repo/$documentation_path"
git -C "$case_repo" add "$documentation_path"
git -C "$case_repo" commit --quiet -m 'add incomplete historical documentation context'
printf 'Encoded historical signature documentation\n' > "$case_repo/$documentation_path"
git -C "$case_repo" add "$documentation_path"
git -C "$case_repo" commit --quiet -m 'remove incomplete historical documentation context'
assert_rejected \
  historical-documentation-prefix-only \
  'classic GitHub token prefix' \
  bash "$case_repo/tests/test-security.sh"

initialize_case historical-documentation-other-line
mkdir -p "$(dirname "$case_repo/$documentation_path")"
printf '%s\n' \
  'O teste deve obter arquivos com `git ls-files -co --exclude-standard` e documentar assinaturas.' \
  'gh''p_unrelated-historical-secret' \
  > "$case_repo/$documentation_path"
git -C "$case_repo" add "$documentation_path"
git -C "$case_repo" commit --quiet -m 'add unrelated historical secret'
printf 'Encoded historical signature documentation\n' > "$case_repo/$documentation_path"
git -C "$case_repo" add "$documentation_path"
git -C "$case_repo" commit --quiet -m 'remove unrelated historical secret'
assert_rejected \
  historical-documentation-other-line \
  'classic GitHub token prefix' \
  bash "$case_repo/tests/test-security.sh"

initialize_case staged-index-blob
printf '%s\n' 'gh''p_staged-index-token' > "$case_repo/staged-secret.txt"
git -C "$case_repo" add staged-secret.txt
unlink "$case_repo/staged-secret.txt"
assert_rejected \
  staged-index-blob \
  'classic GitHub token prefix' \
  bash "$case_repo/tests/test-security.sh"

initialize_case removed-history
printf '%s\n' 'gh''p_removed-history-token' > "$case_repo/removed-secret.txt"
git -C "$case_repo" add removed-secret.txt
git -C "$case_repo" commit --quiet -m 'add historical fixture'
git -C "$case_repo" rm --quiet removed-secret.txt
git -C "$case_repo" commit --quiet -m 'remove historical fixture'
assert_rejected \
  removed-history \
  'classic GitHub token prefix' \
  bash "$case_repo/tests/test-security.sh"

initialize_case symlink-blob
ln -s '/'"Us"'ers/fixture-user/private-target' "$case_repo/personal-link"
git -C "$case_repo" add personal-link
git -C "$case_repo" commit --quiet -m 'add symlink fixture'
unlink "$case_repo/personal-link"
assert_rejected \
  symlink-blob \
  'absolute personal path' \
  bash "$case_repo/tests/test-security.sh"

initialize_case untracked-candidate
printf '%s\n' 'pass''word=untracked-fixture' > "$case_repo/untracked.txt"
assert_rejected \
  untracked-candidate \
  'password or secret assignment' \
  bash "$case_repo/tests/test-security.sh"

initialize_case git-read-failure
shim_dir="$case_repo/git-shim"
mkdir -p "$shim_dir"
cat > "$shim_dir/git" <<'EOF'
#!/usr/bin/env bash
if [[ " $* " == *' cat-file blob '* ]]; then
  exit 86
fi
exec "${SECURITY_REAL_GIT:?}" "$@"
EOF
chmod +x "$shim_dir/git"
assert_rejected \
  git-read-failure \
  'unable to read Git blob' \
  env PATH="$shim_dir:$PATH" SECURITY_REAL_GIT="$real_git" \
  bash "$case_repo/tests/test-security.sh"

initialize_case public-and-encoded-signatures
cat > "$case_repo/public.txt" <<'EOF'
Mit0lenda
Nicollas Freitas
https://mitolenda.dev/
Encoded regression signatures:
L1VzZXJzLw==
QzpcVXNlcnNc
QkVHSU4gLi4uIFBSSVZBVEUgS0VZ
c2st
Z2hwXw==
Z2l0aHViX3BhdF8=
QUtJQQ==
eG94W2JhcHJzXS0=
LmVudi5sb2NhbA==
EOF
git -C "$case_repo" add public.txt
git -C "$case_repo" commit --quiet -m 'add approved public fixture'
bash "$case_repo/tests/test-security.sh" >/dev/null || fail 'public identity or encoded signatures were rejected'
printf 'PASS fixture: intended public identity and encoded signature documentation\n'

initialize_case github-merge-committer
printf 'safe merge content\n' > "$case_repo/merge.txt"
git -C "$case_repo" add merge.txt
github_merge_email='noreply@github'
github_merge_email+='.com'
GIT_COMMITTER_NAME='GitHub' \
GIT_COMMITTER_EMAIL="$github_merge_email" \
  git -C "$case_repo" commit --quiet -m 'simulate GitHub merge commit'
bash "$case_repo/tests/test-security.sh" >/dev/null || fail 'public GitHub merge committer was rejected'
printf 'PASS fixture: public GitHub merge committer\n'

printf 'PASS: security scanner fixture matrix\n'
