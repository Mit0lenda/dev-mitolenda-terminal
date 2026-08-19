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

function Get-ProfileFileState {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return [pscustomobject]@{
            Content = ''
            Encoding = New-Object System.Text.UTF8Encoding($true)
            EmitPreamble = $true
        }
    }

    [byte[]]$bytes = [System.IO.File]::ReadAllBytes($Path)
    $encoding = $null
    $preambleLength = 0
    $emitPreamble = $false

    if ($bytes.Length -ge 4 -and $bytes[0] -eq 0x00 -and $bytes[1] -eq 0x00 -and $bytes[2] -eq 0xFE -and $bytes[3] -eq 0xFF) {
        $encoding = New-Object System.Text.UTF32Encoding($true, $true)
        $preambleLength = 4
        $emitPreamble = $true
    }
    elseif ($bytes.Length -ge 4 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE -and $bytes[2] -eq 0x00 -and $bytes[3] -eq 0x00) {
        $encoding = New-Object System.Text.UTF32Encoding($false, $true)
        $preambleLength = 4
        $emitPreamble = $true
    }
    elseif ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        $encoding = New-Object System.Text.UTF8Encoding($true)
        $preambleLength = 3
        $emitPreamble = $true
    }
    elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF) {
        $encoding = New-Object System.Text.UnicodeEncoding($true, $true)
        $preambleLength = 2
        $emitPreamble = $true
    }
    elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) {
        $encoding = New-Object System.Text.UnicodeEncoding($false, $true)
        $preambleLength = 2
        $emitPreamble = $true
    }
    else {
        try {
            $strictUtf8 = New-Object System.Text.UTF8Encoding($false, $true)
            $strictUtf8.GetString($bytes) | Out-Null
            $encoding = New-Object System.Text.UTF8Encoding($false)
        }
        catch [System.Text.DecoderFallbackException] {
            $ansiCodePage = [System.Globalization.CultureInfo]::CurrentCulture.TextInfo.ANSICodePage
            $encoding = [System.Text.Encoding]::GetEncoding($ansiCodePage)
        }
    }

    [pscustomobject]@{
        Content = $encoding.GetString($bytes, $preambleLength, $bytes.Length - $preambleLength)
        Encoding = $encoding
        EmitPreamble = $emitPreamble
    }
}

function Write-ProfileFile {
    param(
        [string]$Path,
        [string]$Content,
        [pscustomobject]$FileState
    )

    [byte[]]$preamble = if ($FileState.EmitPreamble) { $FileState.Encoding.GetPreamble() } else { @() }
    [byte[]]$contentBytes = $FileState.Encoding.GetBytes($Content)
    [byte[]]$bytes = New-Object byte[] ($preamble.Length + $contentBytes.Length)
    [Array]::Copy($preamble, 0, $bytes, 0, $preamble.Length)
    [Array]::Copy($contentBytes, 0, $bytes, $preamble.Length, $contentBytes.Length)
    [System.IO.File]::WriteAllBytes($Path, $bytes)
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

$profileState = Get-ProfileFileState -Path $profilePath
$profileContent = $profileState.Content
Assert-ManagedBlockStructure -Content $profileContent -Path $profilePath

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

Install-Dependencies

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
    Write-ProfileFile -Path $profilePath -Content $updatedProfile -FileState $profileState
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
