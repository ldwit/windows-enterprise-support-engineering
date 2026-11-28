#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Project 1, Case A: puts the lab VM into a "slow boot" state.

.DESCRIPTION
    Creates an Automatic-start service named ContosoInvAgent ("Contoso Inventory Agent")
    whose binary is powershell.exe running a script that sleeps for 120 seconds.
    powershell.exe is not a real service, so it never reports "running" to the
    Service Control Manager (SCM). The SCM waits for it during every boot, times out,
    and logs Event IDs 7009 and 7000 in the System log.

    Run this ONLY in the disposable lab VM. Undo it with case-a-fix.ps1 or by
    restoring the 'baseline' snapshot.
#>

$ErrorActionPreference = 'Stop'

$caseDir     = 'C:\LabCases\CaseA'
$hangScript  = Join-Path $caseDir 'inventory-agent.ps1'
$serviceName = 'ContosoInvAgent'
$displayName = 'Contoso Inventory Agent'

# 1. The "agent": a script that just sleeps, like a vendor agent stuck waiting on a network share.
New-Item -ItemType Directory -Path $caseDir -Force | Out-Null
Set-Content -Path $hangScript -Encoding ascii -Value @'
# Simulated vendor agent that hangs at startup.
Start-Sleep -Seconds 120
'@

# 2. Register it as an Automatic service so it runs on every boot.
$binPath = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$hangScript`""

if (Get-Service -Name $serviceName -ErrorAction SilentlyContinue) {
    Write-Host "$serviceName already exists. Nothing to do." -ForegroundColor Yellow
} else {
    New-Service -Name $serviceName -DisplayName $displayName -BinaryPathName $binPath `
        -StartupType Automatic -Description 'Simulated third-party agent for Project 1, Case A.' | Out-Null
    Write-Host "Created service $serviceName." -ForegroundColor Green
}

# 3. Show what was configured.
sc.exe qc $serviceName
Write-Host "`nReboot the VM now (Restart-Computer) to reproduce the slow boot." -ForegroundColor Cyan
