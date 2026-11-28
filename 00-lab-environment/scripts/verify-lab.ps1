<#
.SYNOPSIS
    Verifies the Windows 11 lab VM before taking the baseline snapshot.

.DESCRIPTION
    Run inside the lab VM in a NEW PowerShell window (Windows PowerShell or PowerShell 7)
    after install-tools.ps1. Prints the OS, time zone, Guest Additions status, and the
    location and version of every tool, then a PASS/FAIL table.

.EXAMPLE
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
    .\verify-lab.ps1
#>
[CmdletBinding()]
param()

Write-Host "`n=== Operating system ===" -ForegroundColor Cyan
Get-ComputerInfo | Select-Object OsName, OsVersion, OsBuildNumber, WindowsVersion | Format-List

Write-Host "=== Time zone and clock ===" -ForegroundColor Cyan
"{0}  |  {1}" -f (Get-TimeZone).Id, (Get-Date)

Write-Host "`n=== Firmware security ===" -ForegroundColor Cyan
try   { "Secure Boot enabled: {0}" -f (Confirm-SecureBootUEFI) } catch { "Secure Boot: unable to query (run as administrator)" }
try   { $tpm = Get-Tpm; "TPM present: {0}  ready: {1}" -f $tpm.TpmPresent, $tpm.TpmReady } catch { "TPM: unable to query (run as administrator)" }

$checks = [ordered]@{
    'Guest Additions (VBoxService)' = { (Get-Service VBoxService -ErrorAction Stop).Status -eq 'Running' }
    'PowerShell 7 (pwsh)'           = { [bool](Get-Command pwsh -ErrorAction Stop) }
    'Pester 5+'                     = { [bool](Get-Module Pester -ListAvailable | Where-Object Version -ge '5.0') }
    'Process Explorer'              = { [bool](Get-Command procexp64 -ErrorAction Stop) }
    'Process Monitor'               = { [bool](Get-Command procmon64 -ErrorAction Stop) }
    'Autoruns'                      = { [bool](Get-Command autoruns64 -ErrorAction Stop) }
    'ProcDump'                      = { [bool](Get-Command procdump64 -ErrorAction Stop) }
    'WPR'                           = { [bool](Get-Command wpr -ErrorAction Stop) }
    'WPA'                           = { Test-Path "${env:ProgramFiles(x86)}\Windows Kits\10\Windows Performance Toolkit\wpa.exe" }
    'WinDbg'                        = { [bool](Get-Command WinDbgX -ErrorAction Stop) }
    'Git'                           = { [bool](Get-Command git -ErrorAction Stop) }
}

$results = foreach ($name in $checks.Keys) {
    $ok = try { & $checks[$name] } catch { $false }
    [pscustomobject]@{ Check = $name; Result = if ($ok) { 'PASS' } else { 'FAIL' } }
}

Write-Host "`n=== Tool checks ===" -ForegroundColor Cyan
$results | Format-Table -AutoSize
if ($results.Result -contains 'FAIL') {
    Write-Host 'Fix every FAIL before taking the baseline snapshot.' -ForegroundColor Yellow
} else {
    Write-Host 'All checks passed. Ready for the baseline snapshot.' -ForegroundColor Green
}
