[string]$Description = "These functions are used to create, update and end logging sessions for any number of powershell activities. "
[string]$Path = "C:\Users\briandonnelly2\OneDrive - KPMG\Scripts\Backup\scripts\ps\old - 6-5-18\powershell\ps-kpmg\ps-custom-modules\KPMG-Logging\KPMG-Logging.psd1" 
[string]$Company = "KPMG LLC"
[string]$Author = "Brian Donnelly"

<# Creates a new module manifest #>
New-ModuleManifest -Path $Path -Author $Author -PowerShellVersion 4.0 -CompanyName $Company `
    -Description $Description -Copyright $Company