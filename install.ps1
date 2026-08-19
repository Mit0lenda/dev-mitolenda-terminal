$ErrorActionPreference = 'Stop'

$projectRoot = $PSScriptRoot
$startMarker = '# >>> DEV_MITOLENDA TERMINAL >>>'
$endMarker = '# <<< DEV_MITOLENDA TERMINAL <<<'
$isTestMode = -not [string]::IsNullOrWhiteSpace($env:MITOLENDA_TEST_HOME)
$effectiveHome = if ($isTestMode) { $env:MITOLENDA_TEST_HOME } else { $HOME }
$configDir = Join-Path $effectiveHome '.config/dev-mitolenda-terminal'
$backupRoot = Join-Path $effectiveHome '.config/dev-mitolenda-terminal-backups'
$profilePath = if ($isTestMode) {
    Join-Path $effectiveHome 'Documents/PowerShell/Microsoft.PowerShell_profile.ps1'
}
else {
    [string]$PROFILE
}

function Assert-ManagedBlockStructure {
    param(
        [string]$Content,
        [string]$Path
    )

    $inside = $false
    foreach ($line in [regex]::Split($Content, "`r`n|`n|`r")) {
        if ($line -ceq $startMarker) {
            if ($inside) {
                throw "DEV_MITOLENDA installer: invalid managed block in ${Path}: nested opening marker."
            }
            $inside = $true
            continue
        }
        if ($line -ceq $endMarker) {
            if (-not $inside) {
                throw "DEV_MITOLENDA installer: invalid managed block in ${Path}: closing marker without an opening marker."
            }
            $inside = $false
        }
    }

    if ($inside) {
        throw "DEV_MITOLENDA installer: invalid managed block in ${Path}: opening marker without a closing marker."
    }
}

function Remove-ManagedBlocks {
    param([string]$Content)

    $escapedStart = [regex]::Escape($startMarker)
    $escapedEnd = [regex]::Escape($endMarker)
    $pattern = "(?ms)^${escapedStart}`r?`$`r?`n.*?^${escapedEnd}`r?`$(?:`r?`n|`$)"
    [regex]::Replace($Content, $pattern, '')
}

function Write-Utf8File {
    param(
        [string]$Path,
        [string]$Content
    )

    [System.IO.File]::WriteAllText($Path, $Content, (New-Object System.Text.UTF8Encoding($false)))
}

function Install-Dependencies {
    if ($isTestMode -or $env:MITOLENDA_SKIP_PACKAGES -eq '1') {
        return
    }

    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Warning 'WinGet was not found. Install Starship and Space Mono Nerd Font manually, then run this installer again.'
        return
    }

    if (-not (Get-Command starship -ErrorAction SilentlyContinue)) {
        & winget install --id Starship.Starship --exact --source winget --accept-package-agreements --accept-source-agreements
        if ($LASTEXITCODE -ne 0) {
            throw "DEV_MITOLENDA installer: WinGet could not install Starship (exit $LASTEXITCODE)."
        }
    }

    Write-Output 'Install Space Mono Nerd Font from https://www.nerdfonts.com/font-downloads if it is not already installed.'
}

$profileContent = if (Test-Path -LiteralPath $profilePath -PathType Leaf) {
    [System.IO.File]::ReadAllText($profilePath)
}
else {
    ''
}
Assert-ManagedBlockStructure -Content $profileContent -Path $profilePath
Install-Dependencies

$timestamp = Get-Date -Format 'yyyyMMddHHmmssfff'
$backupDir = Join-Path $backupRoot $timestamp
$suffix = 1
while (Test-Path -LiteralPath $backupDir) {
    $backupDir = Join-Path $backupRoot "$timestamp-$suffix"
    $suffix++
}
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

if (Test-Path -LiteralPath $profilePath -PathType Leaf) {
    Copy-Item -LiteralPath $profilePath -Destination (Join-Path $backupDir 'Microsoft.PowerShell_profile.ps1')
}
if (Test-Path -LiteralPath $configDir -PathType Container) {
    $managedBackup = Join-Path $backupDir 'managed-config'
    New-Item -ItemType Directory -Path $managedBackup -Force | Out-Null
    Get-ChildItem -LiteralPath $configDir -Force | Copy-Item -Destination $managedBackup -Recurse -Force
}

New-Item -ItemType Directory -Path $configDir -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $projectRoot 'config/starship.toml') -Destination (Join-Path $configDir 'starship.toml') -Force
Copy-Item -LiteralPath (Join-Path $projectRoot 'shell/mitolenda.ps1') -Destination (Join-Path $configDir 'mitolenda.ps1') -Force

$profileParent = Split-Path -Parent $profilePath
New-Item -ItemType Directory -Path $profileParent -Force | Out-Null
$cleanProfile = Remove-ManagedBlocks -Content $profileContent
$newline = [Environment]::NewLine
$separator = if ($cleanProfile.Length -gt 0 -and -not ($cleanProfile.EndsWith("`n") -or $cleanProfile.EndsWith("`r"))) { $newline } else { '' }
$managedBlock = @(
    '# >>> DEV_MITOLENDA TERMINAL >>>'
    '$env:STARSHIP_CONFIG = Join-Path $HOME ''.config/dev-mitolenda-terminal/starship.toml'''
    '. (Join-Path $HOME ''.config/dev-mitolenda-terminal/mitolenda.ps1'')'
    'if (Get-Command starship -ErrorAction SilentlyContinue) {'
    '    Invoke-Expression (& starship init powershell)'
    '}'
    '# <<< DEV_MITOLENDA TERMINAL <<<'
) -join $newline
$updatedProfile = $cleanProfile + $separator + $managedBlock + $newline
if ($updatedProfile -cne $profileContent) {
    Write-Utf8File -Path $profilePath -Content $updatedProfile
}

if (Get-Command starship -ErrorAction SilentlyContinue) {
    $previousStarshipConfig = $env:STARSHIP_CONFIG
    try {
        $env:STARSHIP_CONFIG = Join-Path $configDir 'starship.toml'
        & starship prompt | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "Starship validation failed with exit $LASTEXITCODE."
        }
    }
    catch {
        throw "DEV_MITOLENDA installer: $($_.Exception.Message) Backup: $backupDir"
    }
    finally {
        $env:STARSHIP_CONFIG = $previousStarshipConfig
    }
}

Write-Output "DEV_MITOLENDA Terminal installed. Backup: $backupDir"
Write-Output 'Select SpaceMono Nerd Font in Windows Terminal Settings > Defaults > Appearance, then start a new PowerShell session.'
