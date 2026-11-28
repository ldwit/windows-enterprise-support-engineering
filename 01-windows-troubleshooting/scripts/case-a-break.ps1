#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Project 1, Case A: puts the lab VM into a "slow boot" state.

.DESCRIPTION
    Builds a small but real Windows service, "Contoso Inventory Agent" (ContosoInvAgent),
    with the C# compiler that ships with Windows (.NET Framework 4.x csc.exe), and registers
    it as an Automatic-start service.

    When the service starts, it connects to the Service Control Manager (SCM) normally, then
    hangs inside its start routine for 120 seconds, spinning one CPU core in a "retry loop"
    the way a vendor agent does when its license server is unreachable. It never reports
    RUNNING in time, so the SCM logs a start failure and boot takes longer to settle.

    The service writes a timestamped log to C:\LabCases\CaseA\agent.log so you can line its
    behavior up against Event Viewer.

    Why not just point a service at powershell.exe? We tried that first (see the README):
    powershell.exe never connects to the SCM, so the SCM fails it within seconds and the boot
    is not slowed at all. A real hung agent connects first and then hangs.

    Run this ONLY in the disposable lab VM. Undo it with case-a-fix.ps1 or by restoring the
    'baseline' snapshot.
#>

$ErrorActionPreference = 'Stop'

$caseDir     = 'C:\LabCases\CaseA'
$source      = Join-Path $caseDir 'ContosoInvAgent.cs'
$exe         = Join-Path $caseDir 'ContosoInvAgent.exe'
$serviceName = 'ContosoInvAgent'
$displayName = 'Contoso Inventory Agent'
$csc         = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'

New-Item -ItemType Directory -Path $caseDir -Force | Out-Null

# 1. Remove the first attempt (PowerShell-based service) if it is still registered.
if (Get-Service -Name $serviceName -ErrorAction SilentlyContinue) {
    sc.exe stop $serviceName 2>$null | Out-Null
    sc.exe delete $serviceName | Out-Null
    Start-Sleep -Seconds 2
    Write-Host "Removed existing $serviceName service." -ForegroundColor Yellow
}
Remove-Item (Join-Path $caseDir 'inventory-agent.ps1') -ErrorAction SilentlyContinue

# 2. Source code for the simulated agent.
Set-Content -Path $source -Encoding ascii -Value @'
using System;
using System.Diagnostics;
using System.IO;
using System.ServiceProcess;

public class ContosoInvAgent : ServiceBase
{
    const string LogPath = @"C:\LabCases\CaseA\agent.log";

    public ContosoInvAgent()
    {
        ServiceName = "ContosoInvAgent";
        CanStop = true;
        CanShutdown = true;
    }

    static void Log(string msg)
    {
        File.AppendAllText(LogPath, DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss.fff") + "  " + msg + Environment.NewLine);
    }

    protected override void OnStart(string[] args)
    {
        Log("OnStart called. Contacting license server...");
        // Simulated bug: retry an unreachable license server in a tight loop for 120 s.
        Stopwatch sw = Stopwatch.StartNew();
        double x = 0;
        while (sw.Elapsed.TotalSeconds < 120)
        {
            x += Math.Sqrt(sw.ElapsedTicks % 1000);
        }
        Log("Gave up on license server after " + sw.Elapsed.TotalSeconds.ToString("0.0") + " s. Reporting RUNNING.");
    }

    protected override void OnStop()     { Log("OnStop called."); }
    protected override void OnShutdown() { Log("OnShutdown called."); }

    public static void Main()
    {
        Log("Process started (PID " + Process.GetCurrentProcess().Id + ").");
        ServiceBase.Run(new ContosoInvAgent());
    }
}
'@

# 3. Compile it with the in-box C# compiler.
if (-not (Test-Path $csc)) { throw "C# compiler not found at $csc" }
& $csc /nologo /target:exe /out:$exe /reference:System.ServiceProcess.dll $source
if ($LASTEXITCODE -ne 0 -or -not (Test-Path $exe)) { throw "Compile failed." }
Write-Host "Compiled $exe" -ForegroundColor Green

# 4. Register it as an Automatic service.
New-Service -Name $serviceName -DisplayName $displayName -BinaryPathName "`"$exe`"" `
    -StartupType Automatic -Description 'Simulated third-party agent for Project 1, Case A.' | Out-Null
Write-Host "Created service $serviceName." -ForegroundColor Green

# 5. Show what was configured.
sc.exe qc $serviceName
Write-Host "`nReboot the VM now (Restart-Computer) to reproduce the slow boot." -ForegroundColor Cyan
