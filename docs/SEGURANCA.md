# SEGURANÇA // SAIBA O QUE MUDA

Instalar uma configuração de shell é executar código no seu computador. A regra é simples: leia primeiro, entenda o escopo e só depois rode.

## 01 // O QUE OS INSTALADORES LEEM

### macOS

// sistema retornado por `uname`;

// disponibilidade de Zsh, Homebrew e Starship;

// seu `~/.zshrc`, se ele existir;

// conteúdo já presente em `~/.config/dev-mitolenda-terminal/`;

// arquivos públicos `config/starship.toml` e `shell/mitolenda.zsh` do clone.

### Windows

// disponibilidade de WinGet e Starship;

// caminho e conteúdo do arquivo indicado por `$PROFILE`;

// codificação e BOM do perfil para preservá-los;

// conteúdo já presente em `$HOME/.config/dev-mitolenda-terminal/`;

// arquivos públicos `config/starship.toml` e `shell/mitolenda.ps1` do clone.

O comando `mt` consulta apenas ferramentas locais e o contexto atual. `mt git` lê o estado do repositório por meio do Git. `mt status` imprime o diretório atual; revise essa saída antes de incluí-la em prints ou vídeos.

## 02 // O QUE OS INSTALADORES ESCREVEM

### macOS

// backup datado em `~/.config/dev-mitolenda-terminal-backups/<DATA>/`;

// `starship.toml` e `mitolenda.zsh` em `~/.config/dev-mitolenda-terminal/`;

// um único bloco entre `# >>> DEV_MITOLENDA TERMINAL >>>` e `# <<< DEV_MITOLENDA TERMINAL <<<` no `~/.zshrc`.

### Windows

// backup datado em `$HOME/.config/dev-mitolenda-terminal-backups/<DATA>/`;

// `starship.toml` e `mitolenda.ps1` em `$HOME/.config/dev-mitolenda-terminal/`;

// um único bloco com os mesmos marcadores no arquivo indicado por `$PROFILE`.

Os instaladores validam a estrutura dos marcadores antes de editar. Marcadores aninhados, abertos sem fechamento ou fechados sem abertura interrompem a operação.

## 03 // DEPENDÊNCIAS E REDE

No macOS, o script chama o Homebrew para instalar Starship e Space Mono Nerd Font quando ausentes. Se o Homebrew não existir, a instalação para com uma mensagem clara.

No Windows, o script usa WinGet para instalar `Starship.Starship` quando WinGet existe e Starship está ausente. A Space Mono Nerd Font é uma instalação manual; nenhum ID instável de fonte do WinGet é executado.

Fora os gerenciadores de pacote, os scripts não fazem requisições de rede. Eles não têm telemetria.

## 04 // O QUE O PROJETO NÃO COLETA

// senhas, tokens, cookies ou chaves privadas;

// conteúdo do histórico do shell;

// arquivos `.env`;

// e-mail, telefone ou dados de clientes;

// conteúdo da configuração Git;

// notificações, abas ou arquivos fora do escopo descrito;

// dados para telemetria.

O prompt pode exibir usuário e hostname durante uma sessão SSH, mas esses valores são lidos em tempo de execução e não ficam gravados no repositório.

## 05 // O QUE É PRESERVADO

// conteúdo fora do bloco gerenciado no `.zshrc` ou `$PROFILE`;

// o próprio link simbólico quando `~/.zshrc` aponta para um arquivo regular válido;

// permissões do `.zshrc` durante a substituição do bloco;

// codificação e BOM de um perfil PowerShell existente;

// backups criados pelo instalador;

// Starship e fontes durante a desinstalação;

// `settings.json` e demais preferências do Windows Terminal.

O Windows cria novos perfis com UTF-8 e BOM para compatibilidade com Windows PowerShell 5.1.

## 06 // DESINSTALAÇÃO E LIMITE DO DIRETÓRIO GERENCIADO

No macOS, `uninstall.sh` remove o bloco do `.zshrc` sem substituir um link simbólico válido. Depois, compara `starship.toml` e `mitolenda.zsh` individualmente com os arquivos do clone usado para desinstalar. Somente cópias inalteradas são apagadas; arquivos modificados ou desconhecidos permanecem, e o diretório é removido apenas se ficar vazio.

No Windows, `uninstall.ps1` remove o bloco do `$PROFILE`, apaga individualmente o `starship.toml` e o `mitolenda.ps1` somente quando cada assinatura corresponde e remove a pasta apenas se ela ficar vazia.

Não guarde arquivos pessoais no diretório gerenciado. As proteções são conservadoras, mas esse caminho continua reservado ao projeto.

Nenhum desinstalador restaura backups automaticamente. Nenhum deles desinstala Starship ou a fonte.

## 07 // COMO REVISAR ANTES DE RODAR

No macOS:

```sh
less ./install.sh
less ./shell/managed-block.sh
less ./shell/mitolenda.zsh
less ./config/starship.toml
```

No Windows:

```powershell
Get-Content .\install.ps1
Get-Content .\shell\mitolenda.ps1
Get-Content .\config\starship.toml
```

Procure pelas operações de escrita, pelos comandos do gerenciador de pacotes e pelos caminhos atingidos. Compare o script local com o repositório público antes de executar uma cópia recebida por outro canal.

## 08 // BACKUP E RECUPERAÇÃO MANUAL

Liste os backups no macOS:

```sh
ls -la ~/.config/dev-mitolenda-terminal-backups/
```

Liste os backups no Windows:

```powershell
Get-ChildItem (Join-Path $HOME '.config/dev-mitolenda-terminal-backups')
```

Cada instalação cria uma nova pasta com data. Revise o conteúdo da versão escolhida antes de copiá-la. Um backup pode conter `.zshrc`, `Microsoft.PowerShell_profile.ps1` e/ou `managed-config`, dependendo do que existia antes da instalação.

Não copie um backup sobre o perfil atual sem entender o que será substituído. A desinstalação já remove o bloco gerenciado; a restauração manual serve para casos em que você quer recuperar exatamente uma versão anterior.

## 09 // LIMITAÇÃO DE VALIDAÇÃO

Os scripts PowerShell e seus testes receberam análise estática no host macOS. Eles não foram executados neste host com Windows PowerShell 5.1 nem PowerShell 7, porque esses runtimes não estavam disponíveis.

Antes de publicar uma release, rode em um host Windows:

```powershell
powershell -NoProfile -File .\tests\Test-InstallWindows.ps1
pwsh -NoProfile -File .\tests\Test-InstallWindows.ps1
```

Uma análise estática não substitui esse teste de runtime.

## 10 // COMO REPORTAR UM PROBLEMA

Inclua plataforma, versão do shell, comando executado e saída relevante. Antes de enviar:

// troque nomes de usuário e hostname por valores neutros;

// remova caminhos de clientes e projetos privados;

// não cole arquivos de perfil completos;

// não publique backups;

// não publique tokens ou arquivos `.env`.
