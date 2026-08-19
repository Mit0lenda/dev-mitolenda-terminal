#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

for relative_path in \
  README.md \
  README.en.md \
  README.es.md \
  docs/PERSONALIZACAO.md \
  docs/SEGURANCA.md \
  docs/CONTEUDO.md \
  LICENSE; do
  [ -f "$repo_root/$relative_path" ] || fail "missing $relative_path"
done

for readme in README.md README.en.md README.es.md; do
  for language_link in \
    '[Português (Brasil)](README.md)' \
    '[English](README.en.md)' \
    '[Español](README.es.md)'; do
    grep -Fq -- "$language_link" "$repo_root/$readme" || fail "$readme is missing language link: $language_link"
  done

  grep -Fq -- 'DEV_MITOLENDA // TERMINAL' "$repo_root/$readme" || fail "$readme is missing the branded terminal header"
  grep -Fq -- '#F24A00' "$repo_root/$readme" || fail "$readme is missing the brand palette"
  grep -Fq -- 'mt doctor' "$repo_root/$readme" || fail "$readme is missing mt doctor"
  grep -Fq -- 'Windows PowerShell 5.1' "$repo_root/$readme" || fail "$readme is missing the Windows runtime limitation"
done

first_language_line="$(grep -m1 -F '[Português (Brasil)](README.md)' "$repo_root/README.md")"
case "$first_language_line" in
  *'**[Português (Brasil)](README.md)**'*) ;;
  *) fail 'README.md must emphasize PT-BR as the primary language' ;;
esac

for expected in \
  'DEV_MITOLENDA' \
  'macOS' \
  'Windows' \
  'Segurança' \
  'Desinstalação' \
  'mt doctor' \
  'validação estática no macOS' \
  'Windows PowerShell 5.1' \
  'PowerShell 7' \
  'nenhum ID estável de pacote no WinGet' \
  'https://mitolenda.dev/'; do
  grep -Fq -- "$expected" "$repo_root/README.md" || fail "README.md is missing: $expected"
done

for expected in \
  'REEL' \
  'VÍDEO' \
  'GANCHO' \
  'CTA' \
  'SEGURANÇA NA GRAVAÇÃO'; do
  grep -Fq -- "$expected" "$repo_root/docs/CONTEUDO.md" || fail "docs/CONTEUDO.md is missing: $expected"
done

printf 'PASS: public documentation and content scripts are present\n'
