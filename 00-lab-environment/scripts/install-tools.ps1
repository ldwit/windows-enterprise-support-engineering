<#
.SYNOPSIS
    Installs the free Microsoft diagnostics toolset used throughout this repo.

.DESCRIPTION
    Run this once inside the Windows 11 lab VM, from an elevated Windows PowerShell
    window (Start > type "PowerShell" > Run as administrator).

    Installs, using winget:
      - PowerShell 7               (Microsoft.PowerShell)
      - WinDbg                     (Microsoft.WinDbg)
      - Git                        (Git.Git)
      - Windows Performance Toolkit, from the Windows ADK, with only the
        "Windows Performance Toolkit" feature selected (Microsoft.WindowsADK)
    Downloads the Sysinternals Suite zip to C:\Tools\Sysinternals and adds it to PATH.
    Then installs the Pester test framework for PowerShell 7 from the PowerShell Gallery.

    The script is safe to run again: packages that are already installed are skipped.
    A transcript is written to C:\LabLogs\install-tools-<timestamp>.log.

.EXAMPLE
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
    .\install-tools.ps1
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

# --- Preconditions -----------------------------------------------------------
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
           ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    throw 'Run this script from an elevated PowerShell window (Run as administrator).'
}

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw 'winget was not found. Open Microsoft Store, update "App Installer", then run this script again.'
}

$logDir = 'C:\LabLogs'
New-Item -ItemType Directory -Path $logDir -Force | Out-Null
Start-Transcript -Path (Join-Path $logDir ("install-tools-{0:yyyyMMdd-HHmmss}.log" -f (Get-Date))) | Out-Null

# --- winget packages ---------------------------------------------------------
# Sysinternals is NOT installed with winget: the winget package is a per-user (MSIX)
# package, and winget refuses to install per-user packages from an elevated window
# (exit code -1978335107). It is downloaded from Microsoft as a zip below instead.
$packages = @(
    @{ Id = 'Microsoft.PowerShell';         Name = 'PowerShell 7' }
    @{ Id = 'Microsoft.WinDbg';             Name = 'WinDbg' }
    @{ Id = 'Git.Git';                      Name = 'Git' }
    # Install only the Windows Performance Toolkit (WPR + WPA) from the ADK, silently.
    @{ Id = 'Microsoft.WindowsADK';         Name = 'Windows Performance Toolkit (ADK)';
       Override = '/quiet /norestart /features OptionId.WindowsPerformanceToolkit' }
)

$results = [System.Collections.Generic.List[object]]::new()

foreach ($pkg in $packages) {
    Write-Host "`n=== $($pkg.Name) ($($pkg.Id)) ===" -ForegroundColor Cyan

    winget list --id $pkg.Id --exact --accept-source-agreements *> $null
    if ($LASTEXITCODE -eq 0) {
        Write-Host 'Already installed, skipping.' -ForegroundColor Yellow
        $results.Add([pscustomobject]@{ Package = $pkg.Name; Result = 'Already installed' })
        continue
    }

    $wingetArgs = @('install', '--id', $pkg.Id, '--exact', '--silent',
                    '--accept-source-agreements', '--accept-package-agreements')
    if ($pkg.Override) { $wingetArgs += @('--override', $pkg.Override) }

    & winget @wingetArgs | Out-Host
    $status = if ($LASTEXITCODE -eq 0) { 'Installed' } else { "FAILED (winget exit code $LASTEXITCODE)" }
    $results.Add([pscustomobject]@{ Package = $pkg.Name; Result = $status })
}

# --- Sysinternals Suite (zip from download.sysinternals.com) -----------------
Write-Host "`n=== Sysinternals Suite ===" -ForegroundColor Cyan
$sysDir = 'C:\Tools\Sysinternals'
try {
    if (Test-Path (Join-Path $sysDir 'procexp64.exe')) {
        Write-Host 'Already installed, skipping.' -ForegroundColor Yellow
        $status = 'Already installed'
    } else {
        New-Item -ItemType Directory -Path $sysDir -Force | Out-Null
        $zip = Join-Path $env:TEMP 'SysinternalsSuite.zip'
        Invoke-WebRequest -Uri 'https://download.sysinternals.com/files/SysinternalsSuite.zip' -OutFile $zip -UseBasicParsing
        Expand-Archive -Path $zip -DestinationPath $sysDir -Force
        Remove-Item $zip
        $status = 'Installed'
    }
    # Add to the machine PATH once.
    $machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    if (($machinePath -split ';') -notcontains $sysDir) {
        [Environment]::SetEnvironmentVariable('Path', "$machinePath;$sysDir", 'Machine')
    }
    # Accept the Sysinternals EULA for this user so tools don't prompt on first run.
    New-Item -Path 'HKCU:\Software\Sysinternals' -Force | Out-Null
    Set-ItemProperty -Path 'HKCU:\Software\Sysinternals' -Name 'EulaAccepted' -Value 1 -Type DWord
} catch {
    $status = "FAILED ($($_.Exception.Message))"
}
$results.Add([pscustomobject]@{ Package = 'Sysinternals Suite'; Result = $status })

# Pick up PATH changes made by the installers without opening a new window.
$env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
            [Environment]::GetEnvironmentVariable('Path', 'User')

# --- Pester (for PowerShell 7) -----------------------------------------------
Write-Host "`n=== Pester ===" -ForegroundColor Cyan
# Depending on the winget manifest, PowerShell 7 is installed as an MSI (Program Files)
# or an MSIX (an app execution alias under WindowsApps). Check both.
$pwsh = @(
    (Join-Path $env:ProgramFiles 'PowerShell\7\pwsh.exe'),
    (Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps\pwsh.exe'),
    (Get-Command pwsh.exe -ErrorAction SilentlyContinue).Source
) | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1

if ($pwsh) {
    Write-Host "Using $pwsh"
    & $pwsh -NoProfile -Command @'
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
Install-Module Pester -Scope CurrentUser -Force -SkipPublisherCheck
"Pester " + (Get-Module Pester -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1).Version
'@ | Out-Host
    $status = if ($LASTEXITCODE -eq 0) { 'Installed' } else { 'FAILED' }
} else {
    $status = 'SKIPPED (pwsh.exe not found; open a new window and run the script again)'
}
$results.Add([pscustomobject]@{ Package = 'Pester'; Result = $status })

# --- Summary -----------------------------------------------------------------
Write-Host "`n=== Summary ===" -ForegroundColor Cyan
$results | Format-Table -AutoSize
Write-Host 'Close this window and open a new one so every tool is on your PATH.'
Stop-Transcript | Out-Null
