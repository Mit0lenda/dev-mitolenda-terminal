# DEV_MITOLENDA // Terminal

## 01 // Visão

O `dev-mitolenda-terminal` será um repositório público que transforma a identidade visual DEV_MITOLENDA em uma experiência de terminal consistente no macOS e no Windows.

O projeto terá dois objetivos complementares:

1. entregar uma configuração de terminal útil, segura, reversível e fácil de instalar;
2. servir como projeto demonstrável e material-base para conteúdo sobre identidade, produtividade e personalização do ambiente de desenvolvimento.

## 02 // Público e proposta

O público principal são desenvolvedores que querem personalizar o terminal sem montar toda a configuração manualmente. O projeto deve comunicar que personalização não é apenas estética: ela pode tornar Git, versões do projeto, falhas e comandos demorados mais fáceis de interpretar.

A comunicação será direta, técnica e autoral, usando a linguagem visual do site público `https://mitolenda.dev/`: títulos fortes, seções numeradas, marcadores `//`, frases curtas e explicações sem jargão desnecessário.

## 03 // Escopo da versão 1.0

### Plataformas

- macOS com Zsh;
- Windows com PowerShell dentro do Windows Terminal.

### Dependências

- Starship como mecanismo de prompt compartilhado;
- Space Mono Nerd Font como fonte recomendada;
- Homebrew no macOS;
- winget no Windows, quando disponível.

### Informações exibidas pelo prompt

- marca `DEV_MITOLENDA` e ano atual;
- diretório atual;
- branch, estado e alterações do Git;
- versões de Node.js, Bun e Python quando relevantes;
- versão do pacote do projeto;
- código de saída quando um comando falhar;
- duração de comandos demorados;
- processos em segundo plano, quando suportados;
- indicação de sessão SSH, sem gravar host ou usuário no repositório.

### Comandos auxiliares

As duas plataformas oferecerão equivalentes para:

- ajuda rápida;
- diagnóstico da instalação;
- resumo do projeto atual;
- guia curto de Git;
- versão instalada.

No Zsh, o ponto de entrada será `mt`. No PowerShell, será uma função `mt` com os mesmos subcomandos sempre que a plataforma oferecer os dados necessários.

## 04 // Estrutura

```text
dev-mitolenda-terminal/
├── config/
│   └── starship.toml
├── shell/
│   ├── mitolenda.zsh
│   └── mitolenda.ps1
├── docs/
│   ├── CONTEUDO.md
│   ├── PERSONALIZACAO.md
│   └── SEGURANCA.md
├── tests/
│   ├── test-install-macos.sh
│   └── Test-InstallWindows.ps1
├── install.sh
├── install.ps1
├── uninstall.sh
├── uninstall.ps1
├── README.md
├── LICENSE
└── .gitignore
```

O `config/starship.toml` será a fonte única da identidade visual. Os scripts de cada sistema cuidarão apenas de dependências, caminhos, integração com o shell, backup, restauração e diagnóstico.

## 05 // Instalação no macOS

O `install.sh` será idempotente e executará estas etapas:

1. validar macOS e disponibilidade do Zsh;
2. verificar Homebrew, apresentando instrução clara caso não exista;
3. instalar Starship e Space Mono Nerd Font somente quando ausentes;
4. criar um backup datado das configurações que serão alteradas;
5. copiar os arquivos do projeto para `~/.config/dev-mitolenda-terminal/`;
6. gerenciar um bloco delimitado no `.zshrc`, sem duplicar linhas;
7. validar a configuração do Starship;
8. informar como selecionar a fonte no terminal e ativar a sessão.

O instalador não substituirá silenciosamente configurações completas do usuário. Apenas o bloco identificado como gerenciado pelo projeto poderá ser atualizado automaticamente.

## 06 // Instalação no Windows

O `install.ps1` será idempotente e executará estas etapas:

1. validar PowerShell e detectar Windows Terminal quando possível;
2. verificar `winget` e oferecer instruções manuais quando indisponível;
3. instalar Starship e Space Mono Nerd Font somente quando ausentes;
4. criar backup datado do perfil do PowerShell e das configurações gerenciadas;
5. copiar os arquivos para um diretório de configuração dentro do perfil do usuário;
6. gerenciar um bloco delimitado no `$PROFILE`, sem duplicação;
7. validar o carregamento do Starship e das funções `mt`;
8. orientar a seleção da fonte no Windows Terminal.

O instalador não editará automaticamente o JSON completo do Windows Terminal na versão 1.0. A fonte será aplicada pelo usuário com instruções ilustradas, reduzindo o risco de danificar perfis existentes.

## 07 // Identidade visual

Tokens principais:

- fundo: `#080808`;
- superfície: `#181818`;
- laranja: `#F24A00`;
- azul: `#00AEEF`;
- verde: `#00F5A0`;
- texto: `#F7F2E8`;
- texto secundário: `#A1A1AA`.

O prompt evitará faixas Powerline multicoloridas. A hierarquia virá de texto monoespaçado, rótulos curtos, cor funcional e sinais como `//`, `GIT:`, `ERR:` e `TIME:`. Ícones não serão necessários para compreender o prompt; a Nerd Font será recomendada para consistência tipográfica e futuras extensões.

## 08 // Segurança e privacidade

Antes da publicação, o repositório será inspecionado para impedir a inclusão de:

- tokens, senhas, cookies, chaves privadas ou credenciais;
- arquivos `.env` ou variantes locais;
- nomes de usuário, hostname ou caminhos absolutos da máquina;
- e-mail privado, número de telefone ou dados pessoais não necessários;
- conteúdo real do `.zshrc`, `$PROFILE`, histórico do shell ou configuração Git;
- backups produzidos pelos instaladores.

O `.gitignore` bloqueará arquivos de ambiente, chaves, backups, logs e artefatos locais comuns. Exemplos usarão nomes neutros. A marca `DEV_MITOLENDA`, o nome público do autor e o link `https://mitolenda.dev/` poderão aparecer porque já são elementos públicos e deliberados do projeto.

Os scripts não enviarão telemetria nem realizarão chamadas externas além dos gerenciadores de pacotes necessários para instalar dependências. Toda alteração relevante terá backup e caminho de desinstalação.

## 09 // Recuperação e erros

Os instaladores usarão modo estrito, mensagens legíveis e códigos de saída diferentes de zero em falhas. Se uma validação falhar depois de alterar um arquivo, o script informará a localização do backup e o comando de restauração.

Os desinstaladores removerão apenas blocos e arquivos reconhecidos como pertencentes ao projeto. Dependências compartilhadas, como Starship e a fonte, não serão removidas automaticamente.

## 10 // Documentação pública

### README.md

O README terá:

- manifesto curto: por que um terminal pode ter a sua cara;
- demonstração visual do prompt;
- recursos e informações exibidas;
- instalação separada para macOS e Windows;
- comandos `mt`;
- personalização por tokens;
- segurança, backup e desinstalação;
- limitações da versão 1.0;
- convite para contribuição;
- link para o site Mitolenda.

### docs/PERSONALIZACAO.md

Explicará como trocar marca, cores, módulos e fonte sem editar os instaladores.

### docs/SEGURANCA.md

Explicará exatamente o que os scripts leem, escrevem, preservam e não coletam.

### docs/CONTEUDO.md

Será uma pauta pronta para produção:

- tese central e público;
- três ganchos para Reels;
- roteiro de Reel de 30–45 segundos;
- roteiro de vídeo de 5–8 minutos;
- lista de cenas e gravações de tela;
- comandos seguros para demonstração;
- legenda, CTA e ideias de cortes;
- pontos sobre estética, identidade e utilidade prática.

## 11 // Linear

Será criada uma issue no projeto `Mitolenda` para produzir e publicar o conteúdo. A issue conterá:

- objetivo e mensagem central;
- link do repositório público;
- checklist de roteiro, preparação do terminal, gravação, edição, revisão, publicação e cortes;
- entregáveis para vídeo principal e Reels;
- critérios de conclusão;
- observação de segurança para ocultar notificações, caminhos pessoais, chaves, abas e dados de clientes durante a gravação.

Equipe, status, prioridade, labels e prazo serão preenchidos usando os valores já existentes no workspace do Linear. Se não houver correspondência inequívoca, a issue será criada no projeto correto com os campos opcionais omitidos, sem inventar taxonomia.

## 12 // Testes e validação

Antes da publicação:

- análise sintática de Bash e PowerShell;
- validação do TOML pelo Starship;
- testes de instalação repetida para confirmar idempotência;
- testes de remoção apenas dos blocos gerenciados;
- simulação com arquivos de perfil preexistentes;
- varredura por segredos e caminhos locais;
- inspeção do conjunto exato de arquivos antes do commit;
- revisão manual do README e dos comandos publicados.

Testes que exigirem macOS ou Windows reais serão separados dos testes estáticos. O README indicará claramente qualquer cenário não executado no sistema oposto antes da primeira versão.

## 13 // Publicação

O repositório será público no GitHub, com branch principal `main` e licença MIT. O primeiro release poderá ser marcado como `v1.0.0` somente após a validação dos dois instaladores. A publicação inicial não incluirá configurações pessoais do computador usado para desenvolver o projeto.

## 14 // Fora do escopo da versão 1.0

- suporte oficial a Linux, Fish, Bash ou shells alternativos;
- alteração automática de todas as cores do emulador de terminal;
- sincronização em nuvem;
- telemetria;
- instalador gráfico;
- atualização automática em segundo plano.
