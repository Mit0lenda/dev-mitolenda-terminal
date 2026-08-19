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

function Get-BytesBase64 {
    param([string]$Path)

    [Convert]::ToBase64String([System.IO.File]::ReadAllBytes($Path))
}

function Write-EncodedFile {
    param(
        [string]$Path,
        [string]$Content,
        [System.Text.Encoding]$Encoding,
        [bool]$EmitPreamble
    )

    $parent = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    $preamble = if ($EmitPreamble) { $Encoding.GetPreamble() } else { [byte[]]@() }
    $contentBytes = $Encoding.GetBytes($Content)
    $bytes = New-Object byte[] ($preamble.Length + $contentBytes.Length)
    [Array]::Copy($preamble, 0, $bytes, 0, $preamble.Length)
    [Array]::Copy($contentBytes, 0, $bytes, $preamble.Length, $contentBytes.Length)
    [System.IO.File]::WriteAllBytes($Path, $bytes)
}

function Assert-ProfileEncodingRoundTrip {
    param(
        [string]$Name,
        [System.Text.Encoding]$Encoding,
        [bool]$EmitPreamble
    )

    $caseHome = Join-Path $testRoot "encoding-$Name"
    $caseProfile = Get-TestProfilePath $caseHome
    $caseBackupRoot = Join-Path $caseHome '.config/dev-mitolenda-terminal-backups'
    $caseContent = "# SENTINEL café $Name`r`n`$Global:EncodingSetting = 'ação'`r`n"
    Write-EncodedFile -Path $caseProfile -Content $caseContent -Encoding $Encoding -EmitPreamble $EmitPreamble
    $originalBytes = Get-BytesBase64 $caseProfile
    $expectedPreamble = if ($EmitPreamble) { $Encoding.GetPreamble() } else { [byte[]]@() }

    $env:MITOLENDA_TEST_HOME = $caseHome
    & $installScript
    $firstInstallBytes = Get-BytesBase64 $caseProfile
    & $installScript
    Should -Condition ((Get-BytesBase64 $caseProfile) -ceq $firstInstallBytes) -Message "repeated install preserves $Name bytes"

    $installedBytes = [System.IO.File]::ReadAllBytes($caseProfile)
    if ($expectedPreamble.Length -gt 0) {
        $actualPreamble = New-Object byte[] $expectedPreamble.Length
        [Array]::Copy($installedBytes, 0, $actualPreamble, 0, $actualPreamble.Length)
        Should -Condition ([Convert]::ToBase64String($actualPreamble) -ceq [Convert]::ToBase64String($expectedPreamble)) -Message "installer preserves $Name BOM"
    }
    $installedText = $Encoding.GetString($installedBytes, $expectedPreamble.Length, $installedBytes.Length - $expectedPreamble.Length)
    Should -Condition $installedText.Contains("# SENTINEL café $Name") -Message "installer preserves $Name profile text"

    $backupProfiles = @(Get-ChildItem -LiteralPath $caseBackupRoot -Recurse -File | Where-Object { $_.Name -eq 'Microsoft.PowerShell_profile.ps1' })
    Should -Condition ($backupProfiles.Count -ge 1) -Message "installer creates a backup for $Name profile"
    $matchingBackups = @($backupProfiles | Where-Object { (Get-BytesBase64 $_.FullName) -ceq $originalBytes })
    Should -Condition ($matchingBackups.Count -ge 1) -Message "backup preserves original $Name bytes"

    & $uninstallScript
    Should -Condition ((Get-BytesBase64 $caseProfile) -ceq $originalBytes) -Message "uninstall restores exact $Name bytes"
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

function Assert-StarshipPrevalidationPreservesFiles {
    $caseHome = Join-Path $testRoot 'starship-prevalidation-failure'
    $caseProfile = Get-TestProfilePath $caseHome
    $caseConfig = Join-Path $caseHome '.config/dev-mitolenda-terminal'
    $profileContent = "# STARSHIP FAILURE SENTINEL`r`n`$Global:ExistingSetting = 1`r`n"
    Write-Utf8File -Path $caseProfile -Content $profileContent
    Write-Utf8File -Path (Join-Path $caseConfig 'starship.toml') -Content 'existing config must survive'
    Write-Utf8File -Path (Join-Path $caseConfig 'mitolenda.ps1') -Content 'existing helper must survive'
    $originalProfile = Get-BytesBase64 $caseProfile
    $originalConfig = Get-BytesBase64 (Join-Path $caseConfig 'starship.toml')
    $originalHelper = Get-BytesBase64 (Join-Path $caseConfig 'mitolenda.ps1')

    $env:MITOLENDA_TEST_HOME = $caseHome
    function global:starship { throw 'forced Starship validation failure' }
    try {
        $installThrew = $false
        try {
            & $installScript
        }
        catch {
            $installThrew = $true
            Should -Condition ($_.Exception.Message -match 'before changing the profile or managed configuration') -Message 'Starship failure is reported as pre-mutation validation'
        }
        Should -Condition $installThrew -Message 'installer stops when Starship rejects the source configuration'
    }
    finally {
        Remove-Item Function:\starship -ErrorAction SilentlyContinue
    }

    Should -Condition ((Get-BytesBase64 $caseProfile) -ceq $originalProfile) -Message 'Starship prevalidation failure preserves the profile'
    Should -Condition ((Get-BytesBase64 (Join-Path $caseConfig 'starship.toml')) -ceq $originalConfig) -Message 'Starship prevalidation failure preserves the managed configuration'
    Should -Condition ((Get-BytesBase64 (Join-Path $caseConfig 'mitolenda.ps1')) -ceq $originalHelper) -Message 'Starship prevalidation failure preserves the managed helper'
}

function Assert-CopiedHelperUsesIsolatedValidation {
    $fixtureRoot = Join-Path $testRoot 'isolated-helper-fixture'
    $caseHome = Join-Path $testRoot 'isolated-helper-home'
    $caseProfile = Get-TestProfilePath $caseHome
    New-Item -ItemType Directory -Path (Join-Path $fixtureRoot 'config') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $fixtureRoot 'shell') -Force | Out-Null
    Copy-Item -LiteralPath $installScript -Destination (Join-Path $fixtureRoot 'install.ps1')
    Copy-Item -LiteralPath (Join-Path $repoRoot 'config/starship.toml') -Destination (Join-Path $fixtureRoot 'config/starship.toml')
    $fixtureHelper = @'
# DEV_MITOLENDA // Terminal helpers for PowerShell
if (Get-Command Should -ErrorAction SilentlyContinue) {
    function global:mt { 'DEV_MITOLENDA Terminal 1.0.0' }
}
else {
    function global:mt { 'wrong isolated version' }
}
'@
    Write-Utf8File -Path (Join-Path $fixtureRoot 'shell/mitolenda.ps1') -Content $fixtureHelper
    Write-Utf8File -Path $caseProfile -Content "# ISOLATION SENTINEL`r`n"
    $originalProfile = Get-BytesBase64 $caseProfile
    $env:MITOLENDA_TEST_HOME = $caseHome

    $installThrew = $false
    try {
        & (Join-Path $fixtureRoot 'install.ps1')
    }
    catch {
        $installThrew = $true
        Should -Condition ($_.Exception.Message -match 'isolated PowerShell process') -Message 'installer reports isolated helper validation failure'
    }
    Should -Condition $installThrew -Message 'installer rejects a copied helper that only passes in the parent process'
    Should -Condition ((Get-BytesBase64 $caseProfile) -ceq $originalProfile) -Message 'isolated helper validation runs before the profile is changed'
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

    $firstInstallOutput = (& $installScript) -join "`n"
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
    Should -Condition ($firstInstallOutput -match 'Windows Terminal detected') -Message 'installer reports Windows Terminal detection'
    Should -Condition ([System.IO.File]::ReadAllText($terminalSettings) -ceq $terminalSettingsBefore) -Message 'installer does not edit Windows Terminal JSON'

    . (Join-Path $configDir 'mitolenda.ps1')
    Should -Condition (((mt version) -join "`n") -eq 'DEV_MITOLENDA Terminal 1.0.0') -Message 'mt version reports the installed version'
    Should -Condition (((mt help) -join "`n") -match 'doctor\s+Check optional tools') -Message 'mt help lists the doctor command'
    Should -Condition (((mt status) -join "`n") -match 'PROMPT: configured') -Message 'mt status finds the copied prompt configuration'

    $savedPath = $env:PATH
    try {
        $env:PATH = ''
        $missingDoctorOutput = (mt doctor) -join "`n"
        Should -Condition ($missingDoctorOutput -match 'STARSHIP: missing') -Message 'mt doctor reports missing Starship'
        Should -Condition ($missingDoctorOutput -match 'GIT: missing') -Message 'mt doctor reports missing Git'
        Should -Condition ($Global:LASTEXITCODE -eq 2) -Message 'mt doctor reports two missing tools through LASTEXITCODE'
        $missingGitOutput = (& { mt git } 2>&1) -join "`n"
        Should -Condition ($missingGitOutput -match 'Git is not installed') -Message 'mt git reports a missing Git command'
        Should -Condition ($Global:LASTEXITCODE -eq 1) -Message 'mt git sets LASTEXITCODE when Git is missing'
    }
    finally {
        $env:PATH = $savedPath
    }

    function global:starship { Write-Output 'starship 1.0.0' }
    try {
        if (Get-Command git -ErrorAction SilentlyContinue) {
            $doctorOutput = (mt doctor) -join "`n"
            Should -Condition ($doctorOutput -match 'CONFIG: ok') -Message 'mt doctor reports installed configuration'
            Should -Condition ($Global:LASTEXITCODE -eq 0) -Message 'mt doctor clears LASTEXITCODE when checks pass'

            $gitRepo = Join-Path $testRoot 'git-repo'
            New-Item -ItemType Directory -Path $gitRepo -Force | Out-Null
            & git -C $gitRepo init --quiet
            Push-Location $gitRepo
            try {
                $gitOutput = (mt git) -join "`n"
                Should -Condition ($gitOutput -match 'WORKTREE: clean') -Message 'mt git reports a clean repository'
                Should -Condition ($Global:LASTEXITCODE -eq 0) -Message 'mt git clears LASTEXITCODE after success'
                Write-Utf8File -Path (Join-Path $gitRepo 'untracked.txt') -Content 'change'
                $changedGitOutput = (mt git) -join "`n"
                Should -Condition ($changedGitOutput -match '\?\? untracked\.txt') -Message 'mt git reports porcelain working-tree changes'
            }
            finally {
                Pop-Location
            }

            Push-Location $testRoot
            try {
                $outsideGitOutput = (& { mt git } 2>&1) -join "`n"
                Should -Condition ($outsideGitOutput -match 'Not a Git repository') -Message 'mt git reports a non-repository directory'
                Should -Condition ($Global:LASTEXITCODE -eq 1) -Message 'mt git sets LASTEXITCODE outside a repository'
            }
            finally {
                Pop-Location
            }
        }
    }
    finally {
        Remove-Item Function:\starship -ErrorAction SilentlyContinue
    }

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

    Assert-StarshipPrevalidationPreservesFiles
    Assert-CopiedHelperUsesIsolatedValidation

    $originalCulture = [System.Threading.Thread]::CurrentThread.CurrentCulture
    try {
        [System.Threading.Thread]::CurrentThread.CurrentCulture = [System.Globalization.CultureInfo]::GetCultureInfo('en-US')
        $ansiEncoding = [System.Text.Encoding]::GetEncoding(1252)
        Assert-ProfileEncodingRoundTrip -Name 'ansi' -Encoding $ansiEncoding -EmitPreamble $false
    }
    finally {
        [System.Threading.Thread]::CurrentThread.CurrentCulture = $originalCulture
    }
    Assert-ProfileEncodingRoundTrip -Name 'utf8-bom' -Encoding (New-Object System.Text.UTF8Encoding($true)) -EmitPreamble $true
    Assert-ProfileEncodingRoundTrip -Name 'utf16-le' -Encoding (New-Object System.Text.UnicodeEncoding($false, $true)) -EmitPreamble $true

    $newProfileHome = Join-Path $testRoot 'new-profile'
    $newProfilePath = Get-TestProfilePath $newProfileHome
    $env:MITOLENDA_TEST_HOME = $newProfileHome
    & $installScript
    $newProfileBytes = [System.IO.File]::ReadAllBytes($newProfilePath)
    Should -Condition ($newProfileBytes.Length -ge 3 -and $newProfileBytes[0] -eq 0xEF -and $newProfileBytes[1] -eq 0xBB -and $newProfileBytes[2] -eq 0xBF) -Message 'new profiles use a Windows PowerShell 5.1-safe UTF-8 BOM'
    & $uninstallScript

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
