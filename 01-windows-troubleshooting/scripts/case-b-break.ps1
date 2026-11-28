#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Project 1, Case B: breaks Contoso Inventory Viewer so it crashes on launch.

.PARAMETER Mode
    Dll       (default) Moves ContosoCore.dll out of the install folder, the way an antivirus
              quarantine or a bad uninstall of a shared component would. The app crashes with
              System.IO.FileNotFoundException.
    Registry  Points the DataFolder registry value at a folder that does not exist, the way a
              bad Group Policy Preference or a botched migration would. The app crashes with
              System.IO.DirectoryNotFoundException.

    Repair either one by running case-b-install.ps1 again.
#>
param([ValidateSet('Dll', 'Registry')][string]$Mode = 'Dll')

$ErrorActionPreference = 'Stop'
$installDir = 'C:\Program Files\Contoso\InventoryViewer'
$regKey     = 'HKLM:\SOFTWARE\Contoso\InventoryViewer'
$quarantine = 'C:\LabCases\CaseB\quarantine'

switch ($Mode) {
    'Dll' {
        New-Item -ItemType Directory -Path $quarantine -Force | Out-Null
        Move-Item "$installDir\ContosoCore.dll" $quarantine -Force
        Write-Host "Moved ContosoCore.dll to $quarantine." -ForegroundColor Yellow
    }
    'Registry' {
        Set-ItemProperty -Path $regKey -Name DataFolder -Value 'D:\ContosoData\Inventory'
        Write-Host "Set DataFolder to D:\ContosoData\Inventory (does not exist)." -ForegroundColor Yellow
    }
}

Get-ChildItem $installDir | Select-Object Name, Length | Format-Table -AutoSize
Get-ItemProperty $regKey | Select-Object DataFolder | Format-List
Write-Host "Now launch: & '$installDir\InventoryViewer.exe'" -ForegroundColor Cyan
