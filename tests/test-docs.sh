#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

for relative_path in \
  README.md \
  docs/PERSONALIZACAO.md \
  docs/SEGURANCA.md \
  docs/CONTEUDO.md \
  LICENSE; do
  [ -f "$repo_root/$relative_path" ] || fail "missing $relative_path"
done

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
