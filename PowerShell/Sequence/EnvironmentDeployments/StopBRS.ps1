Set-Location -Path $PSScriptRoot | Out-Null

if (-Not (Test-Path "Logs")) {
    New-Item -ItemType directory -Path "Logs" | Out-Null
}

$runTime = (Get-Date -format "yyyy-MM-dd_HH-mm-ss")

.\Scripts\BRSStartandStop.ps1 -Mode Stop | tee (".\Logs\" + $runTime + "_StopBRS.txt")
.\Scripts\BRSStartandStop2.ps1 -Mode Stop | tee (".\Logs\" + $runTime + "_StopBRS.txt")
