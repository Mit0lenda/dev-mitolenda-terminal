# DEV_MITOLENDA // TERMINAL

[Português (Brasil)](README.md) · [English](README.en.md) · **[Español](README.es.md)**

```text
┌─ DEV_MITOLENDA // TERMINAL ───────────────────────────────┐
│ IDENTIDAD NO ES ADORNO. ES INFORMACIÓN CON UNA FUNCIÓN.  │
└───────────────────────────────────────────────────────────┘

DEV_MITOLENDA //2026
~/proyectos/terminal GIT:main NODE:v22
→
```

> Tu terminal puede tener tu personalidad y, al mismo tiempo, hacer que Git, los errores, las versiones y los comandos lentos sean más fáciles de leer.

Este proyecto lleva la identidad DEV_MITOLENDA a un prompt compartido entre macOS y Windows. El lenguaje visual es directo: base oscura, color funcional, etiquetas cortas y ningún icono obligatorio para entender lo que ocurre.

Conoce más en [mitolenda.dev](https://mitolenda.dev/).

### // SISTEMA VISUAL

| Token | Color | Función |
| --- | --- | --- |
| `ORANGE` | `#F24A00` | marca, alerta y error |
| `BLUE` | `#00AEEF` | Git, SSH y contexto |
| `GREEN` | `#00F5A0` | éxito y prompt listo |
| `TEXT` | `#F7F2E8` | información principal |
| `SECONDARY` | `#A1A1AA` | versiones e información auxiliar |
| `BACKGROUND` | `#080808` | base del terminal |

## 01 // QUÉ RECIBES

// Un único prompt Starship para las dos plataformas.

// Instaladores idempotentes: puedes ejecutarlos otra vez sin duplicar el bloque administrado.

// Copias de seguridad antes de cambiar `.zshrc`, `$PROFILE` o una configuración ya administrada.

// El comando `mt` para ayuda, estado, Git, diagnóstico y versión.

// Desinstaladores que preservan Starship, fuentes, copias y archivos desconocidos o modificados.

```text
DEV_MITOLENDA //2026
proyecto GIT:main NODE:v22.0.0
ERR:1 TIME:2s //
```

| Señal | Qué muestra |
| --- | --- |
| `DEV_MITOLENDA //2026` | Marca y año actual |
| directorio | Carpeta de trabajo actual |
| `GIT:` | Rama, operaciones, cambios y distancia del remoto |
| `NODE:` / `BUN:` / `PY:` | Versión relevante del entorno |
| `PKG:` | Versión del paquete del proyecto |
| `ERR:` | Código de salida de un comando fallido |
| `TIME:` | Duración de comandos de al menos un segundo |
| `JOBS:` | Cantidad de procesos en segundo plano |
| `SSH:user@host` | Identidad visible solo en sesiones SSH |
| `//` | Prompt listo: verde con éxito y naranja después de un error |

## 02 // ANTES DE INSTALAR

Lee los scripts públicos antes de ejecutarlos. Es una buena práctica para cualquier proyecto que cambie archivos de tu shell.

```sh
git clone https://github.com/Mit0lenda/dev-mitolenda-terminal.git
cd dev-mitolenda-terminal
```

Requisitos:

// macOS con Zsh y Homebrew; o Windows con PowerShell dentro de Windows Terminal.

// Git, Starship y la fuente recomendada Space Mono Nerd Font.

## 03 // INSTALACIÓN EN macOS

Revisa y ejecuta:

```sh
less ./install.sh
bash ./install.sh
```

El script requiere macOS, Zsh y Homebrew. Homebrew instala `starship` y `font-space-mono-nerd-font` cuando sea necesario. Selecciona **Space Mono Nerd Font** en tu aplicación de terminal y abre una nueva sesión Zsh.

El instalador:

// guarda copias en `~/.config/dev-mitolenda-terminal-backups/<FECHA>/`;

// instala los archivos administrados en `~/.config/dev-mitolenda-terminal/`;

// añade un único bloque delimitado a `.zshrc`;

// preserva un `.zshrc` que sea un enlace simbólico válido;

// valida Starship antes de cambiar la configuración administrada.

## 04 // INSTALACIÓN EN Windows

```powershell
git clone https://github.com/Mit0lenda/dev-mitolenda-terminal.git
Set-Location .\dev-mitolenda-terminal
Get-Content .\install.ps1
.\install.ps1
```

Cuando WinGet está disponible, el instalador usa `Starship.Starship`. Si no está disponible, explica qué dependencia debe instalarse manualmente.

**La instalación de Space Mono Nerd Font es manual en Windows porque el proyecto no depende de un ID inestable de WinGet.** Descárgala desde [Nerd Fonts](https://www.nerdfonts.com/font-downloads) y selecciona **SpaceMono Nerd Font** en **Windows Terminal > Settings > Defaults > Appearance**.

La versión 1.0 detecta Windows Terminal, pero nunca lee ni modifica `settings.json`. Preserva la codificación y el BOM del perfil, valida Starship antes de realizar cambios y valida `Get-Command mt` junto con `mt version` en un proceso PowerShell aislado.

## 05 // COMANDOS `mt`

```text
mt help
mt status
mt git
mt doctor
mt version
```

| Comando | Uso |
| --- | --- |
| `mt help` | Lista los comandos disponibles |
| `mt status` | Muestra el directorio, el estado del prompt y la versión de Starship |
| `mt git` | Resume el repositorio actual |
| `mt doctor` | Verifica el shell, las herramientas y los archivos instalados |
| `mt version` | Muestra la versión de DEV_MITOLENDA Terminal |

Ejecuta primero `mt doctor` cuando algo no aparezca.

## 06 // HAZLO TUYO

La identidad vive en `config/starship.toml`. Puedes cambiar colores, marca, etiquetas y módulos sin editar los instaladores.

1. Edita `config/starship.toml` dentro de tu clon.
2. Conserva la firma de la primera línea.
3. Ejecuta otra vez el instalador de tu plataforma.
4. Abre una nueva sesión y ejecuta `mt doctor`.

La guía detallada se mantiene actualmente en PT-BR en [docs/PERSONALIZACAO.md](docs/PERSONALIZACAO.md).

## 07 // SEGURIDAD

Los scripts son locales y públicos. No envían telemetría, no leen el historial del shell, no recopilan credenciales y no editan la configuración completa de Windows Terminal.

Antes de ejecutarlos:

// revisa `install.sh` o `install.ps1`;

// comprueba tus archivos de perfil;

// conserva las copias hasta confirmar que la nueva sesión funciona;

// no uses el directorio administrado para guardar archivos personales.

En macOS, la desinstalación compara cada archivo conocido con la copia del proyecto y elimina solo archivos sin cambios. Los archivos modificados o desconocidos se conservan. En Windows, elimina únicamente archivos reconocidos de forma individual. Consulta [docs/SEGURANCA.md](docs/SEGURANCA.md) para ver el inventario completo en PT-BR.

## 08 // DESINSTALACIÓN

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

La desinstalación elimina la integración identificada del shell y los archivos reconocidos del proyecto. Conserva copias de seguridad, Starship, fuentes, la configuración de Windows Terminal y archivos desconocidos o modificados.

## 09 // LIMITACIONES VERIFICADAS

// La versión 1.0 cubre oficialmente macOS con Zsh y Windows con PowerShell.

// Personaliza el prompt, no toda la paleta de la aplicación de terminal.

// La selección de la fuente es manual. En Windows, su instalación también es manual.

// Los archivos PowerShell recibieron **validación estática en macOS**, pero **no fueron probados en ejecución en este host con Windows PowerShell 5.1 ni PowerShell 7**. Antes de una versión, ejecuta `tests/Test-InstallWindows.ps1` en ambos entornos.

// La prueba del instalador de macOS simula el flujo de Homebrew; no reinstala dependencias reales.

## 10 // CONTRIBUYE SIN PERDER TU IDENTIDAD

Abre un issue o pull request con un caso reproducible. Incluye plataforma, shell, comando y una salida sanitizada de `mt doctor`. Elimina rutas, usuarios, hostnames y datos privados antes de publicar.

¿Quieres la estructura con otra marca? Haz un fork y elige tus propios colores. Una buena identidad no consiste en copiar un tema, sino en dar una función a cada señal.

## 11 // LICENCIA

MIT. Consulta [LICENSE](LICENSE).
