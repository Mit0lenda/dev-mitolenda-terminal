# PERSONALIZAÇÃO // FAÇA O TERMINAL SER SEU

Este projeto é uma base, não uma fantasia obrigatória. Use a arquitetura, troque a identidade e mantenha cada cor trabalhando por uma razão.

## 01 // ONDE A IDENTIDADE VIVE

O arquivo `config/starship.toml` é a fonte única do prompt no macOS e no Windows. Os instaladores só copiam esse arquivo e conectam o Starship ao shell.

Para uma alteração permanente:

1. edite `config/starship.toml` no clone do projeto;
2. mantenha a primeira linha `# DEV_MITOLENDA // TERMINAL`, usada para reconhecer o arquivo gerenciado;
3. rode novamente `bash ./install.sh` no macOS ou `.\install.ps1` no Windows;
4. abra uma nova sessão;
5. rode `mt doctor`.

Editar diretamente `~/.config/dev-mitolenda-terminal/starship.toml` permite experimentar rápido, mas uma reinstalação substitui esse arquivo pela cópia do repositório.

## 02 // TROQUE AS CORES

A paleta atual está em `[palettes.mitolenda]`:

| Token | Valor original | Função atual |
| --- | --- | --- |
| `background` | `#080808` | Referência do fundo visual |
| `surface` | `#181818` | Referência de superfície |
| `orange` | `#F24A00` | Git, erros e atenção |
| `blue` | `#00AEEF` | Python, jobs e SSH |
| `green` | `#00F5A0` | sucesso e runtimes JavaScript |
| `text` | `#F7F2E8` | caminho principal |
| `secondary` | `#A1A1AA` | pacote e duração |

`background` e `surface` documentam a direção visual, mas o Starship não altera o fundo do seu aplicativo. Ajuste essa parte nas preferências do terminal.

Comece com cinco decisões simples:

// uma cor para sucesso;

// uma cor para falha ou atenção;

// uma cor para contexto técnico;

// um texto principal legível;

// um texto secundário que não dispute atenção.

Depois troque os valores hexadecimais e mantenha os nomes dos tokens. Assim, os módulos continuam funcionando sem alterar os instaladores.

## 03 // TROQUE A MARCA

A marca visível fica em `[time]`:

```toml
[time]
disabled = false
time_format = "%Y"
format = "[ SUA_MARCA //$time ](bold orange)"
```

O módulo usa o ano atual como parte da assinatura. Você pode trocar `%Y` por outro formato aceito pelo Starship ou remover a data.

Os textos do comando `mt` vivem em `shell/mitolenda.zsh` e `shell/mitolenda.ps1`. Se criar uma distribuição própria, altere esses textos no repositório e preserve a primeira linha de assinatura de cada arquivo enquanto quiser usar a desinstalação original.

## 04 // ESCOLHA OS SINAIS

A propriedade `format` no topo define a ordem dos módulos:

```toml
format = """
$time$username$hostname
$directory$git_branch$git_state$git_status$nodejs$bun$python$package
$status$cmd_duration$jobs$character"""
```

Para remover um sinal, retire o módulo dessa lista. Para adicionar outro, consulte a documentação do Starship e inclua o nome no ponto em que ele deve aparecer.

Módulos atuais:

// `git_branch`, `git_state` e `git_status` mostram o estado do trabalho;

// `nodejs`, `bun`, `python` e `package` mostram contexto do projeto;

// `status` aparece depois de falhas;

// `cmd_duration` aparece a partir de um segundo;

// `jobs` mostra processos em segundo plano;

// `username` e `hostname` aparecem somente em SSH;

// `character` encerra o prompt com `//`.

Não adicione informação só porque ela existe. Um prompt útil responde rápido: onde estou, em que estado está meu trabalho e o último comando funcionou?

## 05 // TROQUE OS RÓTULOS

Os formatos usam palavras curtas como `GIT:`, `ERR:`, `TIME:` e `NODE:`. Troque o texto dentro de cada `format`, sem apagar variáveis como `$branch`, `$status` ou `$duration`.

Exemplo:

```toml
[git_branch]
symbol = ""
format = "[ BRANCH:$symbol$branch ](bold orange)"
```

Ícones são opcionais. Este projeto funciona sem depender deles para comunicar significado.

## 06 // ESCOLHA A FONTE

A Space Mono Nerd Font é recomendada por combinar com a identidade e deixar espaço para extensões futuras.

No macOS, o instalador tenta instalar o cask `font-space-mono-nerd-font`. A seleção da fonte ainda é manual no aplicativo de terminal.

No Windows, baixe a fonte em [Nerd Fonts](https://www.nerdfonts.com/font-downloads), instale-a e selecione **SpaceMono Nerd Font** em **Windows Terminal > Settings > Defaults > Appearance**. O projeto não depende de um ID instável do WinGet e não edita `settings.json`.

Você também pode escolher outra fonte monoespaçada. Como os sinais principais são texto, o prompt continua compreensível sem glifos especiais.

## 07 // VALIDE ANTES DE COMPARTILHAR

Depois de personalizar:

```sh
STARSHIP_CONFIG=./config/starship.toml starship prompt
```

No PowerShell:

```powershell
$env:STARSHIP_CONFIG = Join-Path (Get-Location) 'config/starship.toml'
starship prompt
```

Confira também:

// contraste em fundo claro e escuro;

// um repositório Git limpo e outro com mudanças;

// um comando que termina com erro;

// um comando com mais de um segundo;

// uma pasta fora de um repositório;

// `mt doctor` em uma nova sessão.

Antes de publicar seu fork, remova dados locais e leia [SEGURANCA.md](SEGURANCA.md).
