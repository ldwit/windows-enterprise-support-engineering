<#
.SYNOPSIS
    Installs the free diagnostics toolset used in this repo.
.DESCRIPTION
    Run in an elevated PowerShell window inside the Windows 11 lab VM.
    Windows Performance Toolkit is installed separately from the Windows ADK installer
    (select only "Windows Performance Toolkit").
#>
$packages = @(
    'Microsoft.PowerShell',
    'Microsoft.Sysinternals.Suite',
    'Microsoft.WinDbg',
    'Git.Git'
)
foreach ($id in $packages) {
    Write-Host "Installing $id..."
    winget install --id $id --exact --accept-source-agreements --accept-package-agreements
}
Install-Module Pester -Scope CurrentUser -Force -SkipPublisherCheck
Write-Host "Done. Install Windows Performance Toolkit from the Windows ADK next."
