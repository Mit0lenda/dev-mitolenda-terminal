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
    $profileContent = [System.IO.File]::ReadAllText($profilePath)
    Assert-ManagedBlockStructure -Content $profileContent -Path $profilePath
    $updatedProfile = Remove-ManagedBlocks -Content $profileContent
    if ($updatedProfile -cne $profileContent) {
        [System.IO.File]::WriteAllText($profilePath, $updatedProfile, (New-Object System.Text.UTF8Encoding($false)))
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
