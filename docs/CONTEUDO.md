# CONTEÚDO // DEV_MITOLENDA TERMINAL

## 01 // TESE CENTRAL

Personalizar o terminal não é enfeitar a ferramenta. É transformar contexto técnico em identidade visual: Git, erro, duração e ambiente aparecem onde o olhar já está.

Público: devs que querem um terminal autoral sem montar tudo do zero e criadores que querem mostrar processo, não só o antes e depois.

Mensagem: use a arquitetura, entenda cada decisão e crie a sua identidade. Não copie a Mitolenda.

## 02 // TRÊS GANCHOS

### GANCHO 01

“Seu terminal parece seu ou parece o padrão de todo mundo?”

### GANCHO 02

“Eu parei de tratar o terminal como uma tela descartável.”

### GANCHO 03

“Essa cor não está aqui por estética: ela me avisa quando o comando falha.”

## 03 // REEL — 30 A 45 SEGUNDOS

Meta: 38 segundos. Corte rápido, texto grande e terminal legível.

| Tempo | Imagem | Fala / texto na tela |
| --- | --- | --- |
| 0–4s | Terminal padrão, enquadramento fechado | **GANCHO:** “Seu terminal parece seu ou parece o padrão de todo mundo?” |
| 4–9s | Comandos e informações sem hierarquia | “Eu usava a ferramenta o dia inteiro, mas ela não dizia nada sobre como eu trabalho.” |
| 9–15s | Corte seco para o prompt DEV_MITOLENDA | “Então eu transformei minha identidade visual em um terminal para macOS e Windows.” |
| 15–25s | Close em `GIT:`, `ERR:` e `TIME:` | “Não é só estética. Eu vejo a branch, as mudanças, o erro e quanto tempo o comando levou.” |
| 25–31s | Alternar Zsh e PowerShell | “O mesmo Starship cuida do visual. Cada sistema só integra o seu shell com segurança.” |
| 31–38s | Repositório e tela final | **CTA:** “O código está no repositório. Usa a estrutura, escolhe suas cores e faz o terminal parecer seu.” |

Texto final na tela:

```text
DEV_MITOLENDA // TERMINAL
macOS + Windows
github.com/Mit0lenda/dev-mitolenda-terminal
```

## 04 // VÍDEO — 5 A 8 MINUTOS

Meta: 6 minutos e 40 segundos.

### 00:00–00:35 // MOTIVAÇÃO

Abrir com o contraste entre terminal padrão e terminal autoral.

Fala-base:

“Eu passo horas no terminal. Se ele é parte do meu trabalho, ele também pode carregar minha identidade e me ajudar a ler o estado do projeto mais rápido. O objetivo não era fazer um tema cheio de ícones. Era dar função para cada sinal.”

### 00:35–01:30 // DECISÕES DE DESIGN

Mostrar o arquivo `config/starship.toml` e a referência visual do prompt.

Pontos:

// fundo quase preto e texto claro para contraste;

// laranja para Git e falha;

// verde para sucesso e runtimes JavaScript;

// azul para contexto técnico;

// rótulos `GIT:`, `ERR:` e `TIME:` compreensíveis sem ícones;

// `//` como assinatura visual;

// módulos que somem quando não têm nada útil para mostrar.

### 01:30–02:20 // ARQUITETURA COMPARTILHADA

Mostrar a árvore do projeto.

Fala-base:

“O visual mora em um arquivo Starship compartilhado. `install.sh` conecta esse arquivo ao Zsh. `install.ps1` conecta o mesmo arquivo ao PowerShell. Os helpers entregam o mesmo comando `mt` nas duas plataformas. Assim eu não mantenho dois temas diferentes.”

Destacar:

// `config/starship.toml` como fonte única;

// `shell/mitolenda.zsh` e `shell/mitolenda.ps1` como helpers;

// blocos delimitados no perfil;

// backups datados;

// desinstalação separada e reversível.

### 02:20–03:20 // DEMONSTRAÇÃO macOS

Mostrar:

1. revisão rápida de `install.sh`;
2. instalação em ambiente de demonstração já preparado;
3. seleção da Space Mono Nerd Font nas preferências;
4. `mt version` e `mt doctor`;
5. repositório limpo e depois com um arquivo novo;
6. comando com erro e comando demorado.

Fala-chave:

“No macOS, o script exige Zsh e Homebrew, instala o que estiver faltando, cria o backup e mexe somente no bloco identificado do `.zshrc`.”

### 03:20–04:20 // DEMONSTRAÇÃO Windows

Gravar esta parte em host Windows depois de executar os testes de PowerShell 5.1 e PowerShell 7.

Mostrar:

1. revisão de `install.ps1`;
2. instalação do Starship pelo WinGet quando necessário;
3. instalação manual da Space Mono Nerd Font;
4. seleção da fonte em Windows Terminal > Settings > Defaults > Appearance;
5. `mt version`, `mt doctor` e `mt git`;
6. confirmação visual de que o `settings.json` não foi editado.

Fala-chave:

“No Windows, eu não arrisco um ID instável do WinGet para a fonte e não reescrevo o JSON do Windows Terminal. A fonte e a aparência são escolhas manuais.”

### 04:20–05:15 // SEGURANÇA E REVERSÃO

Abrir `docs/SEGURANCA.md` e mostrar o backup sem revelar conteúdo pessoal.

Pontos:

// revisar scripts antes de executar;

// backup antes de mutação relevante;

// rejeição de marcadores inválidos;

// preservação do conteúdo fora do bloco;

// nenhum histórico, credencial ou telemetria;

// Starship, fontes e backups preservados na desinstalação;

// diretório gerenciado não deve receber arquivos pessoais;

// limitação honesta: a validação PowerShell precisa ser executada no Windows antes da release.

### 05:15–06:15 // CRIE SUA IDENTIDADE

Abrir `docs/PERSONALIZACAO.md` e trocar uma cor em uma cópia de demonstração.

Fala-base:

“Não quero que você copie a paleta da Mitolenda. Quero que você copie a pergunta: o que cada cor precisa comunicar no seu trabalho? Escolha uma assinatura, dê função às cores, corte informação que não ajuda e mantenha a arquitetura compartilhada.”

Checklist visual:

// trocar marca em `[time]`;

// escolher cores próprias;

// remover módulos desnecessários;

// validar sucesso, erro, Git e duração;

// testar contraste e legibilidade.

### 06:15–06:40 // ENCERRAMENTO

**CTA:**

“O repositório está público. Lê os scripts, testa no seu ambiente e faz um fork com a sua identidade. Se encontrar um caso que eu não cobri, abre uma issue sem incluir nenhum dado privado.”

Tela final: `https://github.com/Mit0lenda/dev-mitolenda-terminal` e `https://mitolenda.dev/`.

## 05 // LISTA DE CENAS

// terminal padrão em plano fechado;

// transformação com o mesmo comando nos dois visuais;

// prompt completo e depois closes em `GIT:`, `ERR:` e `TIME:`;

// `config/starship.toml` com destaques nos tokens;

// árvore curta do repositório;

// revisão dos instaladores antes da execução;

// backup usando nomes de pastas borrados;

// desinstalação em ambiente descartável;

// macOS e Windows lado a lado;

// mudança de uma cor em uma cópia de demonstração;

// tela final com repositório e site.

## 06 // COMANDOS SEGUROS PARA A DEMONSTRAÇÃO

Use uma conta, VM ou pasta de demonstração sem nomes de clientes. Não mostre `mt status` até confirmar que o caminho impresso é neutro.

### macOS / Zsh

```sh
mt version
mt doctor
mkdir -p /tmp/dev-mitolenda-demo
cd /tmp/dev-mitolenda-demo
git init
mt git
touch demo.txt
mt git
false
sleep 2
```

### Windows / PowerShell

```powershell
mt version
mt doctor
$demoPath = Join-Path $env:TEMP 'dev-mitolenda-demo'
New-Item -ItemType Directory -Path $demoPath -Force
Set-Location $demoPath
git init
mt git
New-Item -ItemType File -Path demo.txt
mt git
cmd /c exit 7
Start-Sleep -Seconds 2
```

Apague a pasta de demonstração depois da gravação pelo método normal do sistema, após confirmar o caminho exato.

## 07 // SEGURANÇA NA GRAVAÇÃO

Antes de gravar:

// ative Não Perturbe e feche notificações;

// use um perfil de navegador separado e sem sessões pessoais;

// feche gerenciadores de senha, mensageria, e-mail e painéis de clientes;

// limpe histórico visível e comandos anteriores do terminal;

// use uma conta de demonstração com nome neutro;

// confira prompt, título da janela, abas e barra de caminho;

// não abra `.env`, chaves SSH, configuração Git ou perfis completos;

// não mostre conteúdo real de backups;

// substitua nomes de usuário, hostname, repositórios privados e caminhos locais;

// grave a parte Windows somente depois do teste real em PowerShell 5.1 e 7;

// assista à gravação quadro a quadro antes de publicar.

## 08 // LEGENDA

Seu terminal parece seu ou parece o padrão de todo mundo?

Criei um prompt compartilhado para macOS e Windows com a identidade DEV_MITOLENDA. Git, falhas, versões e duração aparecem com uma hierarquia visual que tem função — sem depender de uma parede de ícones.

O projeto é público, tem backup, desinstalação e um guia para você criar a própria identidade.

Leia os scripts antes de executar. Depois, faz um fork e me mostra como ficou.

## 09 // CTA E CORTES

**CTA principal:** acesse o repositório, revise os scripts e crie sua própria versão.

**CTA secundário:** compartilhe qual sinal do terminal mais ajuda no seu trabalho.

Ideias de cortes:

// “Estética com função: por que erro é laranja”;

// “Um Starship, dois sistemas”;

// “Por que eu não edito o JSON do Windows Terminal”;

// “Três sinais que deixam Git mais legível”;

// “Como criar identidade sem copiar um tema”;

// “O que um instalador seguro precisa preservar”.
