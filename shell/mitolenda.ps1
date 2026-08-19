# DEV_MITOLENDA // Terminal helpers for PowerShell

$Global:DevMitolendaTerminalVersion = '1.0.0'

function global:mt {
    param([string]$Command = 'help')

    $effectiveHome = if ([string]::IsNullOrWhiteSpace($env:MITOLENDA_TEST_HOME)) {
        $HOME
    }
    else {
        $env:MITOLENDA_TEST_HOME
    }
    $configDir = Join-Path $effectiveHome '.config/dev-mitolenda-terminal'

    switch ($Command.ToLowerInvariant()) {
        'help' {
            @'
DEV_MITOLENDA // Terminal

Usage: mt <command>
  help     Show this help
  status   Show the current project and prompt status
  git      Show Git branch and working-tree changes
  doctor   Check optional tools and installed files
  version  Show the installed version
'@
        }
        'status' {
            Write-Output 'DEV_MITOLENDA // STATUS'
            Write-Output "DIR: $((Get-Location).Path)"
            if (Test-Path -LiteralPath (Join-Path $configDir 'starship.toml') -PathType Leaf) {
                Write-Output 'PROMPT: configured'
            }
            else {
                Write-Output 'PROMPT: configuration not found'
            }

            if (Get-Command starship -ErrorAction SilentlyContinue) {
                $starshipVersion = (& starship --version 2>$null | Select-Object -First 1)
                if ($LASTEXITCODE -eq 0 -and $starshipVersion) {
                    Write-Output "STARSHIP: $starshipVersion"
                }
                else {
                    Write-Output 'STARSHIP: command failed'
                }
            }
            else {
                Write-Output 'STARSHIP: not installed'
            }

            if (Get-Command Get-Job -ErrorAction SilentlyContinue) {
                Write-Output "JOBS: $(@(Get-Job -ErrorAction SilentlyContinue).Count)"
            }
            else {
                Write-Output 'JOBS: unavailable'
            }
        }
        'git' {
            if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
                Write-Error 'Git is not installed. Install Git to use mt git.' -ErrorAction Continue
                return
            }

            & git rev-parse --is-inside-work-tree 2>$null | Out-Null
            if ($LASTEXITCODE -ne 0) {
                Write-Error 'Not a Git repository. Run mt git inside a project repository.' -ErrorAction Continue
                return
            }

            $branch = (& git branch --show-current 2>$null | Select-Object -First 1)
            if ($LASTEXITCODE -ne 0) {
                Write-Error 'Git could not determine the current branch.' -ErrorAction Continue
                return
            }

            $changes = @(& git status --porcelain 2>$null)
            if ($LASTEXITCODE -ne 0) {
                Write-Error 'Git could not read the working-tree status.' -ErrorAction Continue
                return
            }

            if ([string]::IsNullOrWhiteSpace($branch)) {
                Write-Output 'BRANCH: detached HEAD'
            }
            else {
                Write-Output "BRANCH: $branch"
            }
            if ($changes.Count -eq 0) {
                Write-Output 'WORKTREE: clean'
            }
            else {
                Write-Output 'CHANGES:'
                $changes | ForEach-Object { Write-Output "  $_" }
            }
        }
        'doctor' {
            $missing = 0
            Write-Output 'DEV_MITOLENDA // DOCTOR'
            Write-Output "POWERSHELL: $($PSVersionTable.PSVersion)"

            foreach ($tool in @('starship', 'git')) {
                if (Get-Command $tool -ErrorAction SilentlyContinue) {
                    Write-Output "$($tool.ToUpperInvariant()): ok"
                }
                else {
                    Write-Output "$($tool.ToUpperInvariant()): missing"
                    $missing++
                }
            }

            if (Get-Command Get-Job -ErrorAction SilentlyContinue) {
                Write-Output "JOBS: ok ($(@(Get-Job -ErrorAction SilentlyContinue).Count) active)"
            }
            else {
                Write-Output 'JOBS: unavailable'
                $missing++
            }

            if ((Test-Path -LiteralPath (Join-Path $configDir 'starship.toml') -PathType Leaf) -and
                (Test-Path -LiteralPath (Join-Path $configDir 'mitolenda.ps1') -PathType Leaf)) {
                Write-Output 'CONFIG: ok'
            }
            else {
                Write-Output 'CONFIG: missing'
                $missing++
            }

            $Global:LASTEXITCODE = $missing
        }
        'version' {
            Write-Output "DEV_MITOLENDA Terminal $Global:DevMitolendaTerminalVersion"
        }
        default {
            Write-Error "Unknown mt command: $Command" -ErrorAction Continue
            mt help
            $Global:LASTEXITCODE = 1
        }
    }
}
