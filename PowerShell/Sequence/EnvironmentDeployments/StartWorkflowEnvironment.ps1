Set-Location -Path $PSScriptRoot | Out-Null

if (-Not (Test-Path "Logs")) {
    New-Item -ItemType directory -Path "Logs" | Out-Null
}

$runTime = (Get-Date -format "yyyy-MM-dd_HH-mm-ss")

.\Scripts\PrepareWorkflowEnvironment.ps1 -Mode Start | tee (".\Logs\" + $runTime + "_StartWorkflowEnvironment.txt")