#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Project 1, Case A: fixes the slow boot caused by ContosoInvAgent.

.DESCRIPTION
    Default (customer-safe workaround): stops the service and sets it to Disabled, leaving
    the files in place so the vendor can investigate. This is what you'd do on a real
    machine while waiting for a fixed agent build.

    -Remove: also deletes the service and C:\LabCases\CaseA (full lab cleanup).

.EXAMPLE
    pwsh -File C:\LabSetup\case-a-fix.ps1
.EXAMPLE
    pwsh -File C:\LabSetup\case-a-fix.ps1 -Remove
#>
param([switch]$Remove)

$ErrorActionPreference = 'Stop'
$serviceName = 'ContosoInvAgent'

$svc = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
if (-not $svc) { Write-Host "$serviceName is not installed. Nothing to fix." -ForegroundColor Yellow; return }

# Stop it (the agent may still be in its start loop; give it a moment).
if ($svc.Status -ne 'Stopped') {
    Stop-Service -Name $serviceName -Force -ErrorAction SilentlyContinue
    $svc.WaitForStatus('Stopped', [TimeSpan]::FromSeconds(30))
}
Set-Service -Name $serviceName -StartupType Disabled
Write-Host "Stopped and disabled $serviceName." -ForegroundColor Green

if ($Remove) {
    sc.exe delete $serviceName | Out-Null
    Remove-Item C:\LabCases\CaseA -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Deleted $serviceName and C:\LabCases\CaseA." -ForegroundColor Green
} else {
    sc.exe qc $serviceName
}

Write-Host "`nReboot (Restart-Computer), wait 10 minutes, then re-check Diagnostics-Performance ID 100." -ForegroundColor Cyan
