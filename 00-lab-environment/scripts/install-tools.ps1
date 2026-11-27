<#
.SYNOPSIS
    Installs the free Microsoft diagnostics toolset used throughout this repo.

.DESCRIPTION
    Run this once inside the Windows 11 lab VM, from an elevated Windows PowerShell
    window (Start > type "PowerShell" > Run as administrator).

    Installs, using winget:
      - PowerShell 7               (Microsoft.PowerShell)
      - Sysinternals Suite         (Microsoft.Sysinternals.Suite)
      - WinDbg                     (Microsoft.WinDbg)
      - Git                        (Git.Git)
      - Windows Performance Toolkit, from the Windows ADK, with only the
        "Windows Performance Toolkit" feature selected (Microsoft.WindowsADK)
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
$packages = @(
    @{ Id = 'Microsoft.PowerShell';         Name = 'PowerShell 7' }
    @{ Id = 'Microsoft.Sysinternals.Suite'; Name = 'Sysinternals Suite' }
    @{ Id = 'Microsoft.WinDbg';             Name = 'WinDbg' }
    @{ Id = 'Git.Git';                      Name = 'Git' }
    # Install only the Windows Performance Toolkit (WPR + WPA) from the ADK, silently.
    @{ Id = 'Microsoft.WindowsADK';         Name = 'Windows Performance Toolkit (ADK)';
       Override = '/quiet /norestart /features OptionId.WindowsPerformanceToolkit' }
)

$results = foreach ($pkg in $packages) {
    Write-Host "`n=== $($pkg.Name) ($($pkg.Id)) ===" -ForegroundColor Cyan

    winget list --id $pkg.Id --exact --accept-source-agreements *> $null
    if ($LASTEXITCODE -eq 0) {
        Write-Host 'Already installed, skipping.' -ForegroundColor Yellow
        [pscustomobject]@{ Package = $pkg.Name; Result = 'Already installed' }
        continue
    }

    $wingetArgs = @('install', '--id', $pkg.Id, '--exact', '--silent',
                    '--accept-source-agreements', '--accept-package-agreements')
    if ($pkg.Override) { $wingetArgs += @('--override', $pkg.Override) }

    & winget @wingetArgs
    $status = if ($LASTEXITCODE -eq 0) { 'Installed' } else { "FAILED (winget exit code $LASTEXITCODE)" }
    [pscustomobject]@{ Package = $pkg.Name; Result = $status }
}

# Pick up PATH changes made by the installers without opening a new window.
$env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
            [Environment]::GetEnvironmentVariable('Path', 'User')

# --- Pester (for PowerShell 7) -----------------------------------------------
Write-Host "`n=== Pester ===" -ForegroundColor Cyan
$pwsh = Join-Path $env:ProgramFiles 'PowerShell\7\pwsh.exe'
if (Test-Path $pwsh) {
    & $pwsh -NoProfile -Command @'
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
Install-Module Pester -Scope CurrentUser -Force -SkipPublisherCheck
(Get-Module Pester -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1).Version.ToString()
'@
    $status = if ($LASTEXITCODE -eq 0) { 'Installed' } else { 'FAILED' }
} else {
    $status = 'SKIPPED (PowerShell 7 not found)'
}
$results = @($results) + [pscustomobject]@{ Package = 'Pester'; Result = $status }

# --- Summary -----------------------------------------------------------------
Write-Host "`n=== Summary ===" -ForegroundColor Cyan
$results | Format-Table -AutoSize
Write-Host 'Close this window and open a new one so every tool is on your PATH.'
Stop-Transcript | Out-Null
