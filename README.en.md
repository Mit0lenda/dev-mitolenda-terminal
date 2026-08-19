# DEV_MITOLENDA // TERMINAL

[Português (Brasil)](README.md) · **[English](README.en.md)** · [Español](README.es.md)

```text
┌─ DEV_MITOLENDA // TERMINAL ───────────────────────────────┐
│ IDENTITY IS NOT DECORATION. IT IS INFORMATION WITH PURPOSE.│
└────────────────────────────────────────────────────────────┘

DEV_MITOLENDA //2026
~/projects/terminal GIT:main NODE:v22
→
```

> Your terminal can look like you—and make Git, errors, versions, and slow commands easier to read.

This project brings the DEV_MITOLENDA identity to one shared prompt for macOS and Windows. The visual language is direct: a dark base, functional color, short labels, and no icons required to understand what is happening.

See more at [mitolenda.dev](https://mitolenda.dev/).

### // VISUAL SYSTEM

| Token | Color | Purpose |
| --- | --- | --- |
| `ORANGE` | `#F24A00` | brand, warning, and error |
| `BLUE` | `#00AEEF` | Git, SSH, and context |
| `GREEN` | `#00F5A0` | success and ready prompt |
| `TEXT` | `#F7F2E8` | primary information |
| `SECONDARY` | `#A1A1AA` | versions and supporting information |
| `BACKGROUND` | `#080808` | terminal foundation |

## 01 // WHAT YOU GET

// One Starship prompt shared by both platforms.

// Idempotent installers: run them again to update the managed block without duplication.

// Backups before changing `.zshrc`, `$PROFILE`, or an existing managed configuration.

// The `mt` command for help, status, Git, diagnostics, and version information.

// Uninstallers that preserve Starship, fonts, backups, and unknown or modified files.

```text
DEV_MITOLENDA //2026
project GIT:main NODE:v22.0.0
ERR:1 TIME:2s //
```

| Signal | Meaning |
| --- | --- |
| `DEV_MITOLENDA //2026` | Brand and current year |
| directory | Current working directory |
| `GIT:` | Branch, operations, changes, and remote distance |
| `NODE:` / `BUN:` / `PY:` | Relevant runtime version |
| `PKG:` | Project package version |
| `ERR:` | Failed command exit code |
| `TIME:` | Duration of commands taking at least one second |
| `JOBS:` | Background process count |
| `SSH:user@host` | Identity shown only in SSH sessions |
| `//` | Ready prompt: green after success, orange after failure |

## 02 // BEFORE INSTALLING

Read public scripts before running them. This is a good practice for any project that changes shell files.

```sh
git clone https://github.com/Mit0lenda/dev-mitolenda-terminal.git
cd dev-mitolenda-terminal
```

Requirements:

// macOS with Zsh and Homebrew; or Windows with PowerShell inside Windows Terminal.

// Git, Starship, and the recommended Space Mono Nerd Font.

## 03 // INSTALL ON macOS

Review and run:

```sh
less ./install.sh
bash ./install.sh
```

The script requires macOS, Zsh, and Homebrew. Homebrew installs `starship` and `font-space-mono-nerd-font` when needed. Select **Space Mono Nerd Font** in your terminal application and start a new Zsh session.

The installer:

// stores backups in `~/.config/dev-mitolenda-terminal-backups/<DATE>/`;

// installs managed files in `~/.config/dev-mitolenda-terminal/`;

// adds one delimited block to `.zshrc`;

// preserves a valid symlinked `.zshrc` by editing its target;

// validates Starship before changing managed configuration.

## 04 // INSTALL ON Windows

```powershell
git clone https://github.com/Mit0lenda/dev-mitolenda-terminal.git
Set-Location .\dev-mitolenda-terminal
Get-Content .\install.ps1
.\install.ps1
```

When WinGet is available, the installer uses `Starship.Starship`. Otherwise it explains which dependency must be installed manually.

**Space Mono Nerd Font installation is manual on Windows because the project does not rely on an unstable WinGet package ID.** Download it from [Nerd Fonts](https://www.nerdfonts.com/font-downloads), then choose **SpaceMono Nerd Font** under **Windows Terminal > Settings > Defaults > Appearance**.

Version 1.0 detects Windows Terminal but never reads or modifies `settings.json`. It preserves profile encoding and BOM, validates Starship before mutation, and validates `Get-Command mt` plus `mt version` in an isolated PowerShell process.

## 05 // `mt` COMMANDS

```text
mt help
mt status
mt git
mt doctor
mt version
```

| Command | Purpose |
| --- | --- |
| `mt help` | List available commands |
| `mt status` | Show directory, prompt state, and Starship version |
| `mt git` | Summarize the current repository |
| `mt doctor` | Verify shell, tools, and installed files |
| `mt version` | Show the DEV_MITOLENDA Terminal version |

Run `mt doctor` first when something does not appear.

## 06 // MAKE IT YOURS

The identity lives in `config/starship.toml`. Change colors, brand, labels, and modules without editing the installers.

1. Edit `config/starship.toml` in your clone.
2. Keep the signature on the first line.
3. Run your platform installer again.
4. Start a new session and run `mt doctor`.

The detailed customization guide is currently maintained in PT-BR at [docs/PERSONALIZACAO.md](docs/PERSONALIZACAO.md).

## 07 // SECURITY

The scripts are local and public. They do not send telemetry, read shell history, collect credentials, or edit the complete Windows Terminal configuration.

Before running them:

// review `install.sh` or `install.ps1`;

// inspect your profile files;

// keep backups until the new session works;

// do not use the managed directory for personal storage.

On macOS, uninstall compares each known file with the project copy and removes only unchanged files; modified and unknown files remain. On Windows, it removes only individually recognized files. See [docs/SEGURANCA.md](docs/SEGURANCA.md) for the full inventory in PT-BR.

## 08 // UNINSTALL

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

Uninstall removes the identified shell integration and recognized project files. It preserves backups, Starship, fonts, Windows Terminal settings, and unknown or modified files.

## 09 // VERIFIED LIMITATIONS

// Version 1.0 officially covers macOS with Zsh and Windows with PowerShell.

// It customizes the prompt, not the terminal application's complete palette.

// Font selection is manual. Font installation is also manual on Windows.

// PowerShell files received **static validation on macOS**, but were **not runtime-tested on this host with Windows PowerShell 5.1 or PowerShell 7**. Run `tests/Test-InstallWindows.ps1` under both versions before a release.

// The macOS installer test simulates Homebrew package flows; it does not reinstall real dependencies.

## 10 // CONTRIBUTE WITHOUT LOSING YOUR IDENTITY

Open an issue or pull request with a reproducible case. Include the platform, shell, command, and sanitized `mt doctor` output. Remove paths, usernames, hostnames, and private data before publishing.

Want the structure with another brand? Fork it and choose your own colors. Good identity is not copying a theme; it is giving every signal a purpose.

## 11 // LICENSE

MIT. See [LICENSE](LICENSE).
