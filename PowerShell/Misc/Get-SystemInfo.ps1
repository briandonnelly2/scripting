Function Get-SystemInfo {
    [cmdletbinding()]
    Param([string]$Computername = $env:COMPUTERNAME)

    $cs = Get-CimInstance -ClassName Win32_computersystem -ComputerName $Computername  
    #this assumes a single processor
    $proc = Get-CimInstance -ClassName win32_processor -ComputerName $Computername 
 
    $data = [ordered]@{
    'Hostname' = $cs.DNSHostName
    'Domain' = $cs.Domain
    'System Type' = $cs.PCSystemType
    'Total RAM (GB)' = $cs.TotalPhysicalMemory/1GB -as [int]
    'Physical CPU Count' = $cs.NumberOfProcessors
    'Logical CPU Count' = $cs.NumberOfLogicalProcessors
    'CPU Name' = $proc.Name
    'Clock Speed' = $proc.MaxClockSpeed
    }

    $Data | Out-Host
}

$Servername = "UKVMUAPP1012"

Get-SystemInfo -Computername $Servername