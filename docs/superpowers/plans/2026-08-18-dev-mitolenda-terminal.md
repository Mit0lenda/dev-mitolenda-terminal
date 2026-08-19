# DEV_MITOLENDA Terminal Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Publicar um terminal DEV_MITOLENDA seguro, idempotente e reversível para macOS/Zsh e Windows/PowerShell, acompanhado de documentação autoral e uma pauta de produção no Linear.

**Architecture:** Um `config/starship.toml` compartilhado define a aparência e os módulos. Instaladores e módulos de shell específicos por plataforma cuidam de dependências, backups, blocos gerenciados, diagnóstico e restauração sem copiar configurações pessoais para o repositório.

**Tech Stack:** Bash 3.2+, Zsh, PowerShell 7/Windows PowerShell 5.1, Starship, TOML, Homebrew, winget, GitHub e Linear.

**Spec:** `docs/superpowers/specs/2026-08-18-dev-mitolenda-terminal-design.md`

## Global Constraints

- Suporte oficial inicial: macOS com Zsh e Windows com PowerShell dentro do Windows Terminal.
- Fonte recomendada: Space Mono Nerd Font. O macOS pode instalá-la pelo cask estável; no Windows, instalação e seleção permanecem manuais porque nenhum ID WinGet estável foi adotado.
- Paleta: fundo `#080808`, superfície `#181818`, laranja `#F24A00`, azul `#00AEEF`, verde `#00F5A0`, texto `#F7F2E8`, secundário `#A1A1AA`.
- Nenhum token, senha, chave, e-mail privado, telefone, hostname, histórico ou caminho absoluto pessoal pode entrar no repositório.
- Instaladores devem ser idempotentes, criar backup antes de alterações e gerenciar somente blocos delimitados.
- Desinstaladores não removem Starship nem fontes compartilhadas.
- O repositório será público no GitHub com branch `main` e licença MIT.

---

### Task 1: Configuração compartilhada e contrato do prompt

**Files:**
- Create: `config/starship.toml`
- Create: `tests/test-starship-config.sh`
- Create: `.gitignore`

**Interfaces:**
- Consumes: executável `starship` quando disponível.
- Produces: `config/starship.toml`, copiado pelos dois instaladores; teste estático executável por `bash tests/test-starship-config.sh`.

- [ ] **Step 1: Escrever o teste que define o contrato visual**

O teste deve usar `set -euo pipefail`, resolver a raiz do repositório e verificar com `grep -F` a presença de `palette = "mitolenda"`, `DEV_MITOLENDA`, `#F24A00`, `[git_branch]`, `[git_status]`, `[status]`, `[cmd_duration]`, `[custom.year]` e `[custom.ssh]`. Se `starship` existir, deve executar:

```bash
STARSHIP_CONFIG="$repo_root/config/starship.toml" starship prompt >/dev/null
```

- [ ] **Step 2: Executar o teste e confirmar a falha inicial**

Run: `bash tests/test-starship-config.sh`

Expected: FAIL porque `config/starship.toml` ainda não existe.

- [ ] **Step 3: Criar a configuração mínima completa**

Implementar a paleta e o formato especificados, incluindo os módulos `directory`, `git_branch`, `git_state`, `git_status`, `nodejs`, `bun`, `python`, `package`, `status`, `cmd_duration`, `jobs`, `character`, `custom.year` e `custom.ssh`. O SSH deve ler `$USER` e `hostname` apenas em tempo de execução:

```toml
[custom.ssh]
command = 'printf "%s@%s" "$USER" "$(hostname -s)"'
when = 'test -n "$SSH_CONNECTION"'
shell = ["sh"]
format = "[ SSH:$output](bold blue)"
```

- [ ] **Step 4: Criar proteção inicial de arquivos**

Adicionar ao `.gitignore` padrões para `.env`, `.env.*`, `!.env.example`, `*.pem`, `*.key`, `*.p12`, `*.log`, `backups/`, `.DS_Store`, `Thumbs.db` e arquivos temporários de editores.

- [ ] **Step 5: Executar o teste**

Run: `bash tests/test-starship-config.sh`

Expected: PASS; quando Starship existir, o TOML também deve ser aceito pelo binário.

- [ ] **Step 6: Commit**

```bash
git add config/starship.toml tests/test-starship-config.sh .gitignore
git commit -m "feat: add shared Mitolenda prompt"
```

### Task 2: Ferramentas e instalador do macOS

**Files:**
- Create: `shell/mitolenda.zsh`
- Create: `install.sh`
- Create: `uninstall.sh`
- Create: `tests/test-install-macos.sh`

**Interfaces:**
- Consumes: `config/starship.toml` da Task 1, Homebrew, Zsh e diretório temporário injetado por `MITOLENDA_TEST_HOME` nos testes.
- Produces: função `mt`, subcomandos `help`, `status`, `git`, `doctor`, `version`; bloco `# >>> DEV_MITOLENDA TERMINAL >>>`; backup e remoção segura.

- [ ] **Step 1: Escrever testes de idempotência em HOME temporário**

O teste deve criar `test_home="$(mktemp -d)"`, registrar `trap 'rm -rf "$test_home"' EXIT`, criar um `.zshrc` sentinela e executar duas vezes:

```bash
MITOLENDA_TEST_HOME="$test_home" MITOLENDA_SKIP_PACKAGES=1 bash ./install.sh
MITOLENDA_TEST_HOME="$test_home" MITOLENDA_SKIP_PACKAGES=1 bash ./install.sh
```

Deve afirmar que a sentinela permanece, que existe exatamente um marcador inicial e um final, que `starship.toml` e `mitolenda.zsh` foram copiados, que há backup, e que `uninstall.sh` remove somente o bloco gerenciado.

- [ ] **Step 2: Executar e confirmar a falha inicial**

Run: `bash tests/test-install-macos.sh`

Expected: FAIL porque os scripts ainda não existem.

- [ ] **Step 3: Implementar `shell/mitolenda.zsh`**

Definir `DEV_MITOLENDA_TERMINAL_VERSION="1.0.0"` e `mt()` com os cinco subcomandos. Toda consulta opcional deve testar `command -v` ou a existência do arquivo; erros de Git fora de repositórios devem resultar em mensagem útil, não em encerramento do shell.

- [ ] **Step 4: Implementar `install.sh`**

Usar `set -euo pipefail`; calcular a raiz por `SCRIPT_DIR`; usar `${MITOLENDA_TEST_HOME:-$HOME}` como home efetivo; recusar sistemas não Darwin somente quando `MITOLENDA_SKIP_PLATFORM_CHECK` não for `1`; pular instalações quando `MITOLENDA_SKIP_PACKAGES=1`; validar Starship antes das mutações; criar backup datado; copiar arquivos; remover bloco anterior com `awk`; acrescentar exatamente um bloco. Um `.zshrc` que seja link simbólico válido deve continuar sendo link e ter seu alvo regular editado; links quebrados ou não regulares devem ser recusados claramente.

- [ ] **Step 5: Implementar `uninstall.sh`**

Remover somente o bloco delimitado do `.zshrc`. Verificar `starship.toml` e `mitolenda.zsh` individualmente contra os arquivos distribuídos, apagar apenas cópias inalteradas e executar `rmdir` somente quando o diretório ficar vazio. Preservar arquivos modificados, desconhecidos ou não relacionados, além de backups, Starship e fonte.

- [ ] **Step 6: Executar testes e análise sintática**

Run: `bash -n install.sh uninstall.sh tests/test-install-macos.sh && zsh -n shell/mitolenda.zsh && bash tests/test-install-macos.sh`

Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add shell/mitolenda.zsh install.sh uninstall.sh tests/test-install-macos.sh
git commit -m "feat: add macOS installer and tools"
```

### Task 3: Ferramentas e instalador do Windows

**Files:**
- Create: `shell/mitolenda.ps1`
- Create: `install.ps1`
- Create: `uninstall.ps1`
- Create: `tests/Test-InstallWindows.ps1`

**Interfaces:**
- Consumes: `config/starship.toml`, `$PROFILE`, winget opcional e `MITOLENDA_TEST_HOME`/`MITOLENDA_SKIP_PACKAGES`.
- Produces: função PowerShell `mt`, bloco gerenciado no perfil, backup, instalação e remoção idempotentes.

- [ ] **Step 1: Escrever teste PowerShell com diretório temporário**

O teste deve criar uma pasta por `[System.IO.Path]::GetTempPath()` e GUID, definir variáveis de ambiente de teste, criar um perfil com `SENTINEL`, executar `install.ps1` duas vezes e verificar com `Should` manual (`if (-not $condition) { throw ... }`) que há um único bloco, arquivos copiados e sentinela preservada. Depois deve executar `uninstall.ps1` e confirmar que apenas o bloco foi removido.

- [ ] **Step 2: Executar e confirmar a falha inicial quando PowerShell estiver disponível**

Run: `pwsh -NoProfile -File tests/Test-InstallWindows.ps1`

Expected: FAIL porque os scripts ainda não existem. Se `pwsh` não existir no host, registrar o teste como não executado e continuar com análise estática.

- [ ] **Step 3: Implementar `shell/mitolenda.ps1`**

Definir `$Global:DevMitolendaTerminalVersion = '1.0.0'` e `function global:mt { param([string]$Command = 'help') ... }`. Os subcomandos devem corresponder aos do Zsh e usar `Get-Command`, `git status --porcelain`, `$LASTEXITCODE` e `Get-Job` com tratamento explícito para comandos ausentes.

- [ ] **Step 4: Implementar `install.ps1`**

Usar `$ErrorActionPreference = 'Stop'`; resolver a raiz por `$PSScriptRoot`; usar `$env:MITOLENDA_TEST_HOME` quando definido; instalar apenas Starship via `winget` fora do modo de teste; manter a fonte manual no Windows; criar backup; detectar Windows Terminal sem ler ou alterar JSON; validar Starship antes das mutações; copiar os artefatos para uma área temporária e validar o helper com `Get-Command mt` e `mt version` em outro processo PowerShell; só então copiar a configuração final, remover o bloco anterior e acrescentar um bloco que inicializa Starship e importa `mitolenda.ps1`.

- [ ] **Step 5: Implementar `uninstall.ps1`**

Remover somente o bloco gerenciado e os arquivos identificados pelo projeto. Não chamar `winget uninstall` e não alterar o JSON do Windows Terminal.

- [ ] **Step 6: Executar validações disponíveis**

Run when available: `pwsh -NoProfile -Command '$ErrorActionPreference="Stop"; [scriptblock]::Create((Get-Content ./install.ps1 -Raw)) | Out-Null; [scriptblock]::Create((Get-Content ./uninstall.ps1 -Raw)) | Out-Null; [scriptblock]::Create((Get-Content ./shell/mitolenda.ps1 -Raw)) | Out-Null'`

Run when available: `pwsh -NoProfile -File tests/Test-InstallWindows.ps1`

Expected: PASS, incluindo falha forçada do Starship antes de qualquer mutação, validação isolada do helper copiado e preservação do JSON sentinela do Windows Terminal. Sem `pwsh`, a limitação deve ser registrada no README e no handoff.

- [ ] **Step 7: Commit**

```bash
git add shell/mitolenda.ps1 install.ps1 uninstall.ps1 tests/Test-InstallWindows.ps1
git commit -m "feat: add Windows installer and tools"
```

### Task 4: Documentação e conteúdo autoral

**Files:**
- Create: `README.md`
- Create: `docs/PERSONALIZACAO.md`
- Create: `docs/SEGURANCA.md`
- Create: `docs/CONTEUDO.md`
- Create: `LICENSE`

**Interfaces:**
- Consumes: comandos, caminhos e limitações reais das Tasks 1–3.
- Produces: documentação pública, roteiro de Reel de 30–45 segundos e vídeo de 5–8 minutos.

- [ ] **Step 1: Escrever um teste documental**

Adicionar `tests/test-docs.sh` para verificar a existência dos cinco arquivos e procurar no README: `DEV_MITOLENDA`, `macOS`, `Windows`, `Segurança`, `Desinstalação`, `mt doctor` e `https://mitolenda.dev/`. Verificar em `docs/CONTEUDO.md`: `REEL`, `VÍDEO`, `GANCHO`, `CTA` e `SEGURANÇA NA GRAVAÇÃO`.

- [ ] **Step 2: Executar e confirmar falha**

Run: `bash tests/test-docs.sh`

Expected: FAIL porque os documentos não existem.

- [ ] **Step 3: Escrever README e guias**

Usar voz direta, seções numeradas e marcadores `//`. Incluir comandos reais de clone/instalação, aviso para revisar scripts públicos antes de executar, seleção manual da Space Mono Nerd Font, tabela dos sinais do prompt, desinstalação e limitações verificadas.

- [ ] **Step 4: Escrever a pauta de conteúdo**

O Reel deve seguir: gancho “Seu terminal parece seu ou parece o padrão de todo mundo?”, problema, transformação visual, utilidade de Git/erros/tempo, CTA para o repositório. O vídeo longo deve cobrir motivação, decisões de design, arquitetura compartilhada, demonstração macOS/Windows, segurança e como criar uma identidade própria sem copiar a Mitolenda.

- [ ] **Step 5: Adicionar licença MIT sem dados privados**

Usar `Copyright (c) 2026 Nicollas Freitas` e o texto padrão MIT.

- [ ] **Step 6: Executar o teste documental**

Run: `bash tests/test-docs.sh`

Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add README.md docs/PERSONALIZACAO.md docs/SEGURANCA.md docs/CONTEUDO.md LICENSE tests/test-docs.sh
git commit -m "docs: add Mitolenda guides and video scripts"
```

### Task 5: Auditoria integrada e preparação pública

**Files:**
- Create: `tests/test-security.sh`
- Modify: arquivos apontados pelos testes, somente quando necessário.

**Interfaces:**
- Consumes: todos os arquivos rastreados pelo Git.
- Produces: conjunto auditado sem segredos ou caminhos pessoais e suíte única de validação.

- [ ] **Step 1: Criar a auditoria de segurança**

O teste deve auditar os blobs exatos do índice, cada árvore alcançável por `HEAD` e, separadamente, os candidatos retornados por `git ls-files -o --exclude-standard`. Isso inclui blobs de symlinks e deve falhar de forma fechada quando um objeto Git não puder ser lido. Além de senhas, cookies, e-mails privados, telefones, identidade local, caminhos pessoais, arquivos de ambiente, dumps de shell/Git e backups, a regressão deve rejeitar as seguintes assinaturas exatas, documentadas aqui em Base64 UTF-8 para evitar autodetecção: `L1VzZXJzLw==`, `QzpcVXNlcnNc`, `QkVHSU4gLi4uIFBSSVZBVEUgS0VZ`, `c2st`, `Z2hwXw==`, `Z2l0aHViX3BhdF8=`, `QUtJQQ==`, `eG94W2JhcHJzXS0=` e `LmVudi5sb2NhbA==`, além do e-mail configurado no Git. Somente versões históricas deste caminho de plano podem ignorar essas assinaturas documentais literais; todas as demais regras de privacidade continuam obrigatórias. `Mit0lenda`, `Nicollas Freitas` e `https://mitolenda.dev/` são as únicas identidades deliberadamente públicas.

- [ ] **Step 2: Executar toda a suíte**

Run: `bash tests/test-starship-config.sh && bash tests/test-install-macos.sh && bash tests/test-docs.sh && bash tests/test-security.sh`

Run when available: `pwsh -NoProfile -File tests/Test-InstallWindows.ps1`

Expected: todos os testes disponíveis passam; qualquer teste de plataforma indisponível é explicitamente documentado.

- [ ] **Step 3: Inspecionar o conteúdo exato do primeiro push**

Run: `git status --short && git diff --check && git ls-files && git log --oneline --decorate -10`

Expected: somente arquivos do projeto, sem configuração pessoal ou artefatos locais.

- [ ] **Step 4: Commit da auditoria**

```bash
git add tests/test-security.sh
git commit -m "test: add public repository safety checks"
```

### Task 6: Publicação pública no GitHub

**Files:**
- Modify: `README.md` apenas se a URL final precisar substituir a URL de clone provisória.

**Interfaces:**
- Consumes: repositório Git limpo, autenticação GitHub e nome `dev-mitolenda-terminal`.
- Produces: repositório GitHub público com branch `main`.

- [ ] **Step 1: Confirmar ausência de remoto e autenticação**

Run: `git remote -v && gh auth status`

Expected: nenhum remoto e conta GitHub autenticada. Se já houver remoto, parar sem substituí-lo.

- [ ] **Step 2: Fazer verificação final antes da criação externa**

Run: `git status --short && bash tests/test-security.sh`

Expected: árvore limpa e PASS.

- [ ] **Step 3: Criar e publicar**

Run: `gh repo create dev-mitolenda-terminal --public --source=. --remote=origin --push --description "Um terminal com a identidade DEV_MITOLENDA para macOS e Windows."`

Expected: repositório público criado e `main` enviada.

- [ ] **Step 4: Verificar publicação**

Run: `gh repo view --json nameWithOwner,url,visibility,defaultBranchRef`

Expected: `visibility` igual a `PUBLIC` e branch padrão `main`.

### Task 7: Issue de produção no Linear

**Files:**
- No repository files.

**Interfaces:**
- Consumes: URL pública final, workspace conectado e projeto existente `Mitolenda`.
- Produces: uma issue de produção de vídeo vinculada ao projeto correto.

- [ ] **Step 1: Ler workspace, equipes, projeto e taxonomia**

Listar equipes, buscar o projeto `Mitolenda`, listar status e labels da equipe correspondente. Não criar campos novos se já houver equivalentes.

- [ ] **Step 2: Criar a issue**

Título: `Produzir vídeo e Reels — Terminal DEV_MITOLENDA`

Descrição: objetivo, mensagem central, URL pública, roteiro de 5–8 minutos, Reel de 30–45 segundos, checklist de gravação/edição/revisão/publicação/cortes, critérios de conclusão e checklist de segurança para ocultar notificações, caminhos, chaves, abas e dados de clientes.

- [ ] **Step 3: Aplicar metadados existentes**

Vincular ao projeto `Mitolenda`; usar prioridade e label de conteúdo/vídeo apenas se já existirem de forma inequívoca. Não inventar data de entrega.

- [ ] **Step 4: Verificar a issue**

Ler a issue criada e confirmar título, projeto, URL do repositório e checklist.

### Task 8: Verificação final e entrega

**Files:**
- Modify: nenhum arquivo, salvo correções exigidas pela verificação.

**Interfaces:**
- Consumes: GitHub publicado, issue Linear e suíte de testes.
- Produces: handoff com URLs, testes executados e limitações honestas.

- [ ] **Step 1: Rodar verificações finais do repositório**

Run: `git status --short && git diff --check && bash tests/test-starship-config.sh && bash tests/test-install-macos.sh && bash tests/test-docs.sh && bash tests/test-security.sh`

Expected: árvore limpa e todos os testes disponíveis passam.

- [ ] **Step 2: Confirmar remoto e issue**

Confirmar URL pública pelo GitHub e identificador/URL da issue pelo Linear.

- [ ] **Step 3: Entregar resumo**

Informar arquivos principais, URL do repositório, issue criada, comandos de instalação, validações executadas e qualquer teste do Windows que não tenha sido possível executar localmente.
