$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$installScript = Join-Path $repoRoot 'install.ps1'
$uninstallScript = Join-Path $repoRoot 'uninstall.ps1'
$startMarker = '# >>> DEV_MITOLENDA TERMINAL >>>'
$endMarker = '# <<< DEV_MITOLENDA TERMINAL <<<'
$originalTestHome = $env:MITOLENDA_TEST_HOME
$originalSkipPackages = $env:MITOLENDA_SKIP_PACKAGES
$testRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("dev-mitolenda-terminal-{0}" -f [guid]::NewGuid())

function Should {
    param(
        [bool]$Condition,
        [string]$Message
    )

    if (-not $Condition) {
        throw "FAIL: $Message"
    }
}

function Write-Utf8File {
    param(
        [string]$Path,
        [string]$Content
    )

    $parent = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    [System.IO.File]::WriteAllText($Path, $Content, (New-Object System.Text.UTF8Encoding($false)))
}

function Get-TestProfilePath {
    param([string]$TestHome)

    Join-Path $TestHome 'Documents/PowerShell/Microsoft.PowerShell_profile.ps1'
}

function Assert-ThrowsWithoutChangingProfile {
    param(
        [string]$Name,
        [string]$ProfileContent
    )

    $caseHome = Join-Path $testRoot "malformed-$Name"
    $caseProfile = Get-TestProfilePath $caseHome
    $caseConfig = Join-Path $caseHome '.config/dev-mitolenda-terminal'
    Write-Utf8File -Path $caseProfile -Content $ProfileContent
    New-Item -ItemType Directory -Path $caseConfig -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $repoRoot 'config/starship.toml') -Destination (Join-Path $caseConfig 'starship.toml')
    Copy-Item -LiteralPath (Join-Path $repoRoot 'shell/mitolenda.ps1') -Destination (Join-Path $caseConfig 'mitolenda.ps1')

    $env:MITOLENDA_TEST_HOME = $caseHome
    $before = [System.IO.File]::ReadAllText($caseProfile)

    $installThrew = $false
    try {
        & $installScript
    }
    catch {
        $installThrew = $true
        Should -Condition ($_.Exception.Message -match 'invalid managed block') -Message "install reports malformed $Name markers"
    }
    Should -Condition $installThrew -Message "install rejects malformed $Name markers"
    Should -Condition ([System.IO.File]::ReadAllText($caseProfile) -ceq $before) -Message "install preserves malformed $Name profile"

    $uninstallThrew = $false
    try {
        & $uninstallScript
    }
    catch {
        $uninstallThrew = $true
        Should -Condition ($_.Exception.Message -match 'invalid managed block') -Message "uninstall reports malformed $Name markers"
    }
    Should -Condition $uninstallThrew -Message "uninstall rejects malformed $Name markers"
    Should -Condition ([System.IO.File]::ReadAllText($caseProfile) -ceq $before) -Message "uninstall preserves malformed $Name profile"
    Should -Condition (Test-Path -LiteralPath (Join-Path $caseConfig 'starship.toml')) -Message "uninstall preserves files after malformed $Name markers"
}

try {
    New-Item -ItemType Directory -Path $testRoot -Force | Out-Null
    $env:MITOLENDA_TEST_HOME = $testRoot
    $env:MITOLENDA_SKIP_PACKAGES = '1'

    $profilePath = Get-TestProfilePath $testRoot
    $configDir = Join-Path $testRoot '.config/dev-mitolenda-terminal'
    $backupRoot = Join-Path $testRoot '.config/dev-mitolenda-terminal-backups'
    $terminalSettings = Join-Path $testRoot 'AppData/Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json'
    $originalProfileContent = "# SENTINEL: keep this setting`r`n`$Global:ExistingSetting = 1`r`n"
    Write-Utf8File -Path $profilePath -Content $originalProfileContent
    Write-Utf8File -Path $terminalSettings -Content '{"sentinel":"do-not-change"}'
    $terminalSettingsBefore = [System.IO.File]::ReadAllText($terminalSettings)

    & $installScript
    $profileAfterFirstInstall = [System.IO.File]::ReadAllText($profilePath)
    & $installScript
    $profileAfterSecondInstall = [System.IO.File]::ReadAllText($profilePath)

    Should -Condition ($profileAfterSecondInstall -match '(?m)^# SENTINEL: keep this setting\r?$') -Message 'installer preserves existing profile content'
    Should -Condition ($profileAfterSecondInstall -ceq $profileAfterFirstInstall) -Message 'repeated install leaves the profile unchanged'
    Should -Condition ([regex]::Matches($profileAfterSecondInstall, "(?m)^$([regex]::Escape($startMarker))\r?$").Count -eq 1) -Message 'installer writes one opening marker'
    Should -Condition ([regex]::Matches($profileAfterSecondInstall, "(?m)^$([regex]::Escape($endMarker))\r?$").Count -eq 1) -Message 'installer writes one closing marker'
    Should -Condition (Test-Path -LiteralPath (Join-Path $configDir 'starship.toml')) -Message 'installer copies the shared Starship configuration'
    Should -Condition (Test-Path -LiteralPath (Join-Path $configDir 'mitolenda.ps1')) -Message 'installer copies the PowerShell helpers'
    Should -Condition ([System.IO.File]::ReadAllText((Join-Path $configDir 'starship.toml')) -ceq [System.IO.File]::ReadAllText((Join-Path $repoRoot 'config/starship.toml'))) -Message 'installer copies the shared Starship configuration without changing it'
    Should -Condition ([System.IO.File]::ReadAllText((Join-Path $configDir 'mitolenda.ps1')) -ceq [System.IO.File]::ReadAllText((Join-Path $repoRoot 'shell/mitolenda.ps1'))) -Message 'installer copies the PowerShell helpers without changing them'
    Should -Condition (@(Get-ChildItem -LiteralPath $backupRoot -Recurse -File | Where-Object { $_.Name -eq 'Microsoft.PowerShell_profile.ps1' }).Count -ge 1) -Message 'installer backs up the existing PowerShell profile'
    Should -Condition ([System.IO.File]::ReadAllText($terminalSettings) -ceq $terminalSettingsBefore) -Message 'installer does not edit Windows Terminal JSON'

    . (Join-Path $configDir 'mitolenda.ps1')
    Should -Condition (((mt version) -join "`n") -eq 'DEV_MITOLENDA Terminal 1.0.0') -Message 'mt version reports the installed version'
    Should -Condition (((mt help) -join "`n") -match 'doctor\s+Check optional tools') -Message 'mt help lists the doctor command'
    Should -Condition (((mt status) -join "`n") -match 'PROMPT: configured') -Message 'mt status finds the copied prompt configuration'

    & $uninstallScript
    $profileAfterUninstall = [System.IO.File]::ReadAllText($profilePath)
    Should -Condition ($profileAfterUninstall -match '(?m)^# SENTINEL: keep this setting\r?$') -Message 'uninstall preserves existing profile content'
    Should -Condition ($profileAfterUninstall -ceq $originalProfileContent) -Message 'uninstall removes only the managed profile block'
    Should -Condition (-not $profileAfterUninstall.Contains($startMarker)) -Message 'uninstall removes the opening marker'
    Should -Condition (-not $profileAfterUninstall.Contains($endMarker)) -Message 'uninstall removes the closing marker'
    Should -Condition (-not (Test-Path -LiteralPath $configDir)) -Message 'uninstall removes recognized project files'
    Should -Condition (Test-Path -LiteralPath $backupRoot) -Message 'uninstall preserves backups'
    Should -Condition ([System.IO.File]::ReadAllText($terminalSettings) -ceq $terminalSettingsBefore) -Message 'uninstall does not edit Windows Terminal JSON'

    & $uninstallScript
    Should -Condition ([System.IO.File]::ReadAllText($profilePath) -ceq $profileAfterUninstall) -Message 'repeated uninstall leaves the profile unchanged'
    Should -Condition (Test-Path -LiteralPath $backupRoot) -Message 'repeated uninstall preserves backups'

    New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    Write-Utf8File -Path (Join-Path $configDir 'starship.toml') -Content '# personal Starship configuration'
    & $uninstallScript
    Should -Condition (Test-Path -LiteralPath (Join-Path $configDir 'starship.toml')) -Message 'uninstall preserves an unrecognized configuration'

    $nestedProfile = (@('# SENTINEL BEFORE', $startMarker, 'managed', $startMarker, 'nested', $endMarker, '# SENTINEL AFTER') -join "`r`n") + "`r`n"
    $unmatchedStartProfile = (@('# SENTINEL BEFORE', $startMarker, 'managed', '# SENTINEL AFTER') -join "`r`n") + "`r`n"
    $unmatchedEndProfile = (@('# SENTINEL BEFORE', $endMarker, '# SENTINEL AFTER') -join "`r`n") + "`r`n"
    Assert-ThrowsWithoutChangingProfile -Name 'nested' -ProfileContent $nestedProfile
    Assert-ThrowsWithoutChangingProfile -Name 'unmatched-start' -ProfileContent $unmatchedStartProfile
    Assert-ThrowsWithoutChangingProfile -Name 'unmatched-end' -ProfileContent $unmatchedEndProfile

    Write-Output 'PASS: Windows installer is idempotent, safe, and reversible'
}
finally {
    $env:MITOLENDA_TEST_HOME = $originalTestHome
    $env:MITOLENDA_SKIP_PACKAGES = $originalSkipPackages
    if (Test-Path -LiteralPath $testRoot) {
        Remove-Item -LiteralPath $testRoot -Recurse -Force
    }
}
