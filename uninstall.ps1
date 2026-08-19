$ErrorActionPreference = 'Stop'

$startMarker = '# >>> DEV_MITOLENDA TERMINAL >>>'
$endMarker = '# <<< DEV_MITOLENDA TERMINAL <<<'
$isTestMode = -not [string]::IsNullOrWhiteSpace($env:MITOLENDA_TEST_HOME)
$effectiveHome = if ($isTestMode) { $env:MITOLENDA_TEST_HOME } else { $HOME }
$configDir = Join-Path $effectiveHome '.config/dev-mitolenda-terminal'
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
                throw "DEV_MITOLENDA uninstall: invalid managed block in ${Path}: nested opening marker."
            }
            $inside = $true
            continue
        }
        if ($line -ceq $endMarker) {
            if (-not $inside) {
                throw "DEV_MITOLENDA uninstall: invalid managed block in ${Path}: closing marker without an opening marker."
            }
            $inside = $false
        }
    }

    if ($inside) {
        throw "DEV_MITOLENDA uninstall: invalid managed block in ${Path}: opening marker without a closing marker."
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

function Test-ManagedFile {
    param(
        [string]$Path,
        [string]$Header
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return $false
    }
    $reader = New-Object System.IO.StreamReader($Path)
    try {
        return $reader.ReadLine() -ceq $Header
    }
    finally {
        $reader.Dispose()
    }
}

if (Test-Path -LiteralPath $profilePath -PathType Leaf) {
    $profileState = Get-ProfileFileState -Path $profilePath
    $profileContent = $profileState.Content
    Assert-ManagedBlockStructure -Content $profileContent -Path $profilePath
    $updatedProfile = Remove-ManagedBlocks -Content $profileContent
    if ($updatedProfile -cne $profileContent) {
        Write-ProfileFile -Path $profilePath -Content $updatedProfile -FileState $profileState
    }
}

$starshipPath = Join-Path $configDir 'starship.toml'
$helperPath = Join-Path $configDir 'mitolenda.ps1'
$removedFile = $false
if (Test-ManagedFile -Path $starshipPath -Header '# DEV_MITOLENDA // TERMINAL') {
    Remove-Item -LiteralPath $starshipPath -Force
    $removedFile = $true
}
elseif (Test-Path -LiteralPath $starshipPath -PathType Leaf) {
    Write-Output "Preserved $starshipPath because it is not a recognized DEV_MITOLENDA configuration."
}
if (Test-ManagedFile -Path $helperPath -Header '# DEV_MITOLENDA // Terminal helpers for PowerShell') {
    Remove-Item -LiteralPath $helperPath -Force
    $removedFile = $true
}
elseif (Test-Path -LiteralPath $helperPath -PathType Leaf) {
    Write-Output "Preserved $helperPath because it is not a recognized DEV_MITOLENDA helper."
}

if ((Test-Path -LiteralPath $configDir -PathType Container) -and @(Get-ChildItem -LiteralPath $configDir -Force).Count -eq 0) {
    Remove-Item -LiteralPath $configDir -Force
}
if ($removedFile) {
    Write-Output "Removed DEV_MITOLENDA Terminal files from $configDir"
}
Write-Output 'DEV_MITOLENDA Terminal shell integration removed. Backups, Starship, fonts, and Windows Terminal settings were preserved.'
