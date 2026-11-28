#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Project 1, Case B: installs (or repairs) "Contoso Inventory Viewer", a small working app.

.DESCRIPTION
    Builds two files with the C# compiler that ships with Windows (.NET Framework 4.x csc.exe):

      C:\Program Files\Contoso\InventoryViewer\ContosoCore.dll      shared component (counts files)
      C:\Program Files\Contoso\InventoryViewer\InventoryViewer.exe  the app (a Windows GUI app)

    It also creates the app's configuration in the registry:

      HKLM\SOFTWARE\Contoso\InventoryViewer   DataFolder = C:\ProgramData\Contoso\Inventory

    and drops three sample .csv files into that data folder.

    When it works, the app shows "Loaded 3 inventory items ...". case-b-break.ps1 then breaks
    it with a missing DLL or a bad registry value. Running this script again repairs the app,
    the same way "Repair" or a reinstall does on a real machine.
#>

$ErrorActionPreference = 'Stop'

$installDir = 'C:\Program Files\Contoso\InventoryViewer'
$dataDir    = 'C:\ProgramData\Contoso\Inventory'
$regKey     = 'HKLM:\SOFTWARE\Contoso\InventoryViewer'
$buildDir   = 'C:\LabCases\CaseB\src'
$csc        = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'

New-Item -ItemType Directory -Path $installDir, $dataDir, $buildDir -Force | Out-Null

# 1. Source code.
Set-Content -Path "$buildDir\ContosoCore.cs" -Encoding ascii -Value @'
using System.IO;
namespace Contoso.Core
{
    public static class Inventory
    {
        public static int CountItems(string folder)
        {
            return Directory.GetFiles(folder, "*.csv").Length;
        }
    }
}
'@

Set-Content -Path "$buildDir\InventoryViewer.cs" -Encoding ascii -Value @'
using System;
using System.Windows.Forms;
using Microsoft.Win32;

static class Program
{
    [STAThread]
    static void Main()
    {
        string dataFolder = (string)Registry.GetValue(
            @"HKEY_LOCAL_MACHINE\SOFTWARE\Contoso\InventoryViewer", "DataFolder", null);
        Run(dataFolder);
    }

    // Kept in its own method so ContosoCore.dll is loaded when Run is JIT-compiled.
    static void Run(string dataFolder)
    {
        int count = Contoso.Core.Inventory.CountItems(dataFolder);
        MessageBox.Show("Loaded " + count + " inventory items from " + dataFolder,
                        "Contoso Inventory Viewer");
    }
}
'@

# 2. Compile.
if (-not (Test-Path $csc)) { throw "C# compiler not found at $csc" }
& $csc /nologo /target:library /out:"$installDir\ContosoCore.dll" "$buildDir\ContosoCore.cs"
if ($LASTEXITCODE -ne 0) { throw 'ContosoCore.dll failed to compile.' }
& $csc /nologo /target:winexe /out:"$installDir\InventoryViewer.exe" `
    /reference:"$installDir\ContosoCore.dll" /reference:System.Windows.Forms.dll "$buildDir\InventoryViewer.cs"
if ($LASTEXITCODE -ne 0) { throw 'InventoryViewer.exe failed to compile.' }

# 3. Configuration and sample data.
New-Item -Path $regKey -Force | Out-Null
Set-ItemProperty -Path $regKey -Name DataFolder -Value $dataDir
'sku,qty' | Set-Content "$dataDir\laptops.csv"
'sku,qty' | Set-Content "$dataDir\monitors.csv"
'sku,qty' | Set-Content "$dataDir\docks.csv"

Write-Host "Installed Contoso Inventory Viewer:" -ForegroundColor Green
Get-ChildItem $installDir | Select-Object Name, Length, LastWriteTime | Format-Table -AutoSize
Get-ItemProperty $regKey | Select-Object DataFolder | Format-List
Write-Host "Test it: & '$installDir\InventoryViewer.exe'" -ForegroundColor Cyan
