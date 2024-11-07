$LogName = "TTG Apps"
$SourceNames = @("Drt.Web", "ExternalServices.Drt.Wcf")


Write-Host "Creating new log: " $LogName " and sources:" $SourceNames
Write-Host "`n"

foreach($logSource in $SourceNames) {

if ([System.Diagnostics.EventLog]::SourceExists($logSource) -eq $false) {
    Write-Host "Creating log source: '$logSource'."
    new-eventlog -source $logSource -logname $LogName 
    Write-Host "Source and log created."
}
else
{
    Write-Host "Source '$logSource' already exist." 
}
Write-Host "`n"
}

