# DEV_MITOLENDA // TERMINAL

Seu terminal pode ter a sua cara — e ainda deixar Git, erros, versões e comandos demorados mais fáceis de ler.

Este projeto leva a identidade DEV_MITOLENDA para um prompt compartilhado entre macOS e Windows. O visual é direto: fundo escuro, cor com função, rótulos curtos e nenhum ícone obrigatório para entender o que está acontecendo.

Conheça o trabalho em [mitolenda.dev](https://mitolenda.dev/).

## 01 // O QUE VOCÊ RECEBE

// Um prompt Starship único para as duas plataformas.

// Instaladores idempotentes: rodar novamente atualiza o bloco gerenciado sem duplicá-lo.

// Backup antes de mudar seu `.zshrc`, seu `$PROFILE` ou uma configuração já gerenciada.

// Comando `mt` para ajuda, status, Git, diagnóstico e versão.

// Desinstaladores que preservam Starship, fontes e backups.

O mapa abaixo é ilustrativo. Os módulos aparecem somente quando têm algo útil para mostrar.

```text
DEV_MITOLENDA //2026
projeto GIT:main NODE:v22.0.0
ERR:1 TIME:2s //
```

| Sinal | O que mostra |
| --- | --- |
| `DEV_MITOLENDA //2026` | Marca e ano atual |
| diretório | Pasta de trabalho, limitada aos últimos segmentos |
| `GIT:` | Branch, operações em andamento, mudanças e distância do remoto |
| `NODE:` | Versão do Node.js quando o projeto usa Node |
| `BUN:` | Versão do Bun quando relevante |
| `PY:` | Versão do Python quando relevante |
| `PKG:` | Versão do pacote do projeto quando disponível |
| `ERR:` | Código de saída de um comando que falhou |
| `TIME:` | Duração de comandos com pelo menos um segundo |
| `JOBS:` | Quantidade de processos em segundo plano |
| `SSH:user@host` | Identificação exibida somente durante uma sessão SSH |
| `//` | Prompt pronto; verde no sucesso e laranja depois de um erro |

## 02 // ANTES DE INSTALAR

Leia o script público antes de executar. É uma boa prática para este e para qualquer projeto que altere arquivos do seu shell.

```sh
git clone https://github.com/Mit0lenda/dev-mitolenda-terminal.git
cd dev-mitolenda-terminal
```

O projeto usa:

// macOS com Zsh e Homebrew.

// Windows com PowerShell dentro do Windows Terminal.

// Git para clonar o repositório e alimentar os sinais do prompt.

// Starship como mecanismo do prompt.

// Space Mono Nerd Font como fonte recomendada.

## 03 // INSTALAÇÃO NO macOS

Revise e execute o instalador:

```sh
less ./install.sh
bash ./install.sh
```

O script exige macOS, Zsh e Homebrew. Quando necessário, o Homebrew instala `starship` e o cask `font-space-mono-nerd-font`. Depois, abra as preferências do seu aplicativo de terminal, selecione **Space Mono Nerd Font** e inicie uma nova sessão de Zsh.

O instalador:

// salva backups em `~/.config/dev-mitolenda-terminal-backups/<DATA>/`;

// copia os arquivos para `~/.config/dev-mitolenda-terminal/`;

// adiciona um bloco delimitado ao `~/.zshrc`;

// valida o prompt com o Starship quando o comando está disponível.

Se o Homebrew ainda não estiver instalado, o script para e aponta para [brew.sh](https://brew.sh/).

## 04 // INSTALAÇÃO NO Windows

Abra o PowerShell, clone o projeto e entre na pasta:

```powershell
git clone https://github.com/Mit0lenda/dev-mitolenda-terminal.git
Set-Location .\dev-mitolenda-terminal
```

Revise e execute o instalador:

```powershell
Get-Content .\install.ps1
.\install.ps1
```

Quando o WinGet está disponível, o script instala o Starship pelo pacote `Starship.Starship` se ele estiver ausente. Sem WinGet, o script avisa que as dependências precisam ser instaladas manualmente e continua com a integração protegida por detecção do comando.

A **Space Mono Nerd Font é manual no Windows porque nenhum ID estável de pacote no WinGet foi usado como dependência deste projeto**. Baixe a fonte em [Nerd Fonts](https://www.nerdfonts.com/font-downloads), instale-a e escolha **SpaceMono Nerd Font** em **Windows Terminal > Settings > Defaults > Appearance**.

O instalador não edita o `settings.json` do Windows Terminal. Ele:

// salva backups em `$HOME/.config/dev-mitolenda-terminal-backups/<DATA>/`;

// copia os arquivos para `$HOME/.config/dev-mitolenda-terminal/`;

// adiciona um bloco delimitado ao arquivo indicado por `$PROFILE`;

// preserva a codificação e o BOM de perfis existentes.

## 05 // COMANDOS `mt`

Abra uma nova sessão depois da instalação.

```text
mt help
mt status
mt git
mt doctor
mt version
```

| Comando | Uso |
| --- | --- |
| `mt help` | Lista os comandos disponíveis |
| `mt status` | Mostra diretório atual, estado do prompt e versão do Starship |
| `mt git` | Resume branch e mudanças do repositório atual |
| `mt doctor` | Verifica shell, ferramentas e arquivos instalados |
| `mt version` | Mostra a versão do DEV_MITOLENDA Terminal |

No PowerShell, `mt status` também informa a quantidade total de jobs e `mt doctor` coloca a contagem de itens ausentes em `$LASTEXITCODE`. No Zsh, `mt doctor` retorna zero quando tudo está certo e um valor diferente de zero quando algo está ausente. Rode-o primeiro quando algo não aparecer.

## 06 // PERSONALIZAÇÃO

A identidade mora em `config/starship.toml`. Você pode trocar cores, marca, rótulos e módulos sem editar os instaladores.

Para uma mudança que sobreviva a reinstalações:

1. altere o arquivo `config/starship.toml` dentro do seu clone;
2. mantenha a primeira linha de assinatura do arquivo;
3. execute novamente o instalador da sua plataforma;
4. abra uma nova sessão e rode `mt doctor`.

O guia [docs/PERSONALIZACAO.md](docs/PERSONALIZACAO.md) explica cada token e como criar uma identidade própria sem copiar a Mitolenda.

## 07 // Segurança

Os scripts são locais e públicos. Eles não enviam telemetria, não leem histórico do shell, não coletam credenciais e não editam a configuração completa do Windows Terminal.

Eles leem somente o necessário para validar e preservar os arquivos envolvidos. Chamadas externas ficam limitadas aos gerenciadores de pacotes usados para instalar dependências e aos links que você decide abrir.

Antes de executar:

// revise `install.sh` ou `install.ps1`;

// confira seus arquivos de perfil;

// não coloque arquivos pessoais em `~/.config/dev-mitolenda-terminal/`;

// mantenha os backups até confirmar que a nova sessão funciona.

No macOS, o desinstalador remove a pasta gerenciada inteira quando reconhece a assinatura do `starship.toml`. No Windows, ele remove individualmente apenas os dois arquivos com as assinaturas esperadas. Em qualquer plataforma, trate o diretório do projeto como gerenciado e não como armazenamento pessoal.

Leia o inventário completo em [docs/SEGURANCA.md](docs/SEGURANCA.md).

## 08 // DESINSTALAÇÃO

Revise o desinstalador e execute a versão da sua plataforma a partir do clone do projeto.

### macOS

```sh
less ./uninstall.sh
bash ./uninstall.sh
```

### Windows

```powershell
Get-Content .\uninstall.ps1
.\uninstall.ps1
```

A Desinstalação remove a integração identificada do shell e os arquivos reconhecidos do projeto. Ela preserva backups, Starship, fontes e configurações do Windows Terminal. Ela não restaura automaticamente um perfil antigo.

Para recuperar manualmente uma versão anterior, localize o backup desejado em `~/.config/dev-mitolenda-terminal-backups/` ou em `$HOME/.config/dev-mitolenda-terminal-backups/` e copie o arquivo de perfil de volta somente depois de revisá-lo.

## 09 // LIMITAÇÕES VERIFICADAS

// A versão 1.0 cobre macOS com Zsh e Windows com PowerShell. Linux, Bash, Fish e outros shells não têm suporte oficial.

// O projeto personaliza o prompt; ele não troca automaticamente a paleta completa do aplicativo de terminal.

// A seleção da Space Mono Nerd Font é manual nos aplicativos de terminal. No Windows, a instalação da fonte também é manual porque nenhum ID estável de pacote no WinGet foi adotado.

// Os arquivos PowerShell receberam **validação estática no macOS**, mas **não foram testados em execução neste host sob Windows PowerShell 5.1 nem PowerShell 7**. Antes de uma release, execute `tests/Test-InstallWindows.ps1` nas duas versões em um host Windows.

// O teste do instalador macOS simula o Homebrew para os fluxos de pacote; ele não reinstala dependências reais no computador de desenvolvimento.

## 10 // CONTRIBUA SEM PERDER SUA IDENTIDADE

Abra uma issue ou um pull request com um caso reproduzível. Explique a plataforma, o shell, o comando executado e a saída de `mt doctor` — remova caminhos, usuário, hostname e qualquer dado privado antes de publicar.

Quer usar a estrutura com outra marca? Faça um fork, escolha suas próprias cores e mantenha a lógica compartilhada. Identidade boa não é copiar um tema; é fazer cada sinal ter uma função.

## 11 // LICENÇA

MIT. Veja [LICENSE](LICENSE).
