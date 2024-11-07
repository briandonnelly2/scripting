Function Get-ApplicationEventLogs {
    <#
	.SYNOPSIS
	    This function finds all events in all event logs relating to the tax workflow environment.
	.EXAMPLE
		PS> Get-ApplicationEventLogs -Computernames 'UKVMSAPP036','UKVMSAPP062' -StartTimestamp '11-13-19 15:30' -EndTimestamp '11-13-19 17:30' -Logs 'Panam' -LogLevel 'Error'

        PS> Get-ApplicationEventLogs -Computernames 'UKVMSAPP036','UKVMSAPP062' -StartTimestamp '11-13-19 15:30' -EndTimestamp '11-13-19 17:30' -Logs 'Panam' -LogLevel 'Error' | `
          >      Where-Object -Property 'Message' -Like 'WorkflowInstanceId: 9755304*' | Format-Table TimeCreated, LevelDisplayName, Message -Wrap
    .EXAMPLE
        PS> $Computers = @('UKVMSAPP033','UKVMSAPP034','UKVMSAPP035','UKVMSAPP036','UKVMSAPP062','UKVMSWEB014','UKVMSWEB015','UKVMSWEB016','UKVMSWEB017')

        PS> Get-ApplicationEventLogs -Computernames $Computers -StartTimestamp '11-13-19 15:30' -EndTimestamp '11-13-19 17:30' -Logs 'Panam' -LogLevel 'Error' 
    .EXAMPLE
        PS> $Computers = @('UKVMSAPP033','UKVMSAPP034','UKVMSAPP035','UKVMSAPP036','UKVMSAPP062','UKVMSWEB014','UKVMSWEB015','UKVMSWEB016','UKVMSWEB017')

        PS> Get-ApplicationEventLogs -Computernames $Computers -StartTimestamp '11-13-19 15:30' -EndTimestamp '11-13-19 17:30' -Logs 'Panam' -LogLevel 'Error' | `
          >     Out-File -FilePath $HOME\Documents\EventLogOutput.txt -Append -Force | `
          >         notepad.exe $HOME\Documents\EventLogOutput.txt
	.PARAMETER Computernames
        The computer in which you'd like to find event log entries on.  If this is not specified, it will default to all workflow servers.
	.PARAMETER StartTimestamp
        The earlier time of the event you'd like to find an event 
	.PARAMETER EndTimestamp
        The latest time of the event you'd like to find 
    .PARAMETER Logs
        The names of the logs to be searched.  If unspecified, this will default to the System log
    .PARAMETER LogLevelValue
        The Log Level being searched.  Acceptible values are: '1 - Critical', '2 - Error', '3 - Warning', '4 - Information', '5 - Verbose'
    #>
    
    [CmdletBinding()]
    param (
        [string[]]$Computernames = 'Localhost',
        [Parameter(Mandatory)]
        [datetime]$StartTimestamp,
        [Parameter(Mandatory)]
        [datetime]$EndTimestamp,
        [Parameter()]
        [string[]]$Logs,
        [Parameter()]
        [ValidateSet('Critical', 'Error', 'Warning', 'Information', 'Verbose')]
        [string]$LogLevelValue
    )

    process {
        try {
            If($Null -eq $Logs) { $Logs = 'System' }

            [int]$LogLevel
            switch ( $LogLevelValue ) {
                'Critical' { $LogLevel = 1 }
                'Error' { $LogLevel = 2 }
                'Warning' { $LogLevel = 3 }
                'Information' { $LogLevel = 4 }
                'Verbose' { $LogLevel = 5 }
                Default { $LogLevel = 4 }
            }

            $FilterTable = @{
                'StartTime' = $StartTimestamp
                'EndTime'   = $EndTimestamp
                'LogName'   = $Logs
                'Level'     = $LogLevel
            }

            foreach($ComputerName IN $ComputerNames) {                
                Get-WinEvent -ComputerName $ComputerName -FilterHashtable $FilterTable -ErrorAction 'SilentlyContinue' | `
                    Select-Object -Property @{Name='ComputerName';Expression={$ComputerName}}, TimeCreated, LevelDisplayName, Message | `
                        Format-Table -Wrap
            }
        }
        catch {
            Write-Error "$($_.Exception.Message) - Line Number: $($_.InvocationInfo.ScriptLineNumber)"
        }
    }
}

<# $Computers = @('UKVMSWEB024','UKVMSWEB025','UKVMSAPP068','UKVMSAPP069')
Get-ApplicationEventLogs -Computernames $Computers -StartTimestamp '11-15-19 08:00' -EndTimestamp '11-15-19 11:42' -Logs 'TTG Apps' -LogLevel 'error' | `
    Out-File -FilePath $HOME\Documents\PAEventLogOutput.txt -Append -Force | `
        notepad.exe $HOME\Documents\PAEventLogOutput.txt

remove-item $HOME\Documents\PAEventLogOutput.txt -Force #>

$Computers = @('UKVMSWEB065','UKVMSWEB066')
Get-ApplicationEventLogs -Computernames $Computers -StartTimestamp '01-17-20 00:01' -EndTimestamp '01-17-20 10:35' -Logs 'TTG Apps' -LogLevel 'Information' | `
    Out-File -FilePath $HOME\Documents\VaultInformationEventLogOutput.txt -Append -Force | `
        notepad.exe $HOME\Documents\VaultWarningEventLogOutput.txt

<# 
function Get-TextLogEventWithin {
    <#
	.SYNOPSIS
	    This function finds all files matching a specified file extension that have a last write time
        between a specific start and end time.
	.EXAMPLE
		PS> Get-TextLogEventWithin -Computername MYCOMPUTER -StartTimestamp '04-15-15 04:00' -EndTimestamp '04-15-15 08:00' -LogFileExtension 'log'

        This example finds all .log files on all drives on the remote computer MYCOMPUTER from April 15th, 2015 at 4AM to April 15th, 2015 at 8AM.
	.PARAMETER Computername
        The computer name you'd like to search for text log on.  This defaults to localhost.
	.PARAMETER StartTimestamp
        The earliest last write time of a log file you'd like to find
	.PARAMETER EndTimestamp
        The latest last write time of a log file you'd like to find
    	.PARAMETER LogFileExtension
        The file extension you will be limiting your search to. This defaults to 'log'
    
    [CmdletBinding()]
    param (
        [ValidateScript( {Test-Connection -ComputerName $_ -Quiet -Count 1})]
        [string]$Computername = 'localhost',
        [Parameter(Mandatory)]
        [datetime]$StartTimestamp,
        [Parameter(Mandatory)]
        [datetime]$EndTimestamp,
        [ValidateSet('txt', 'log')]
        [string]$LogFileExtension = 'log'
    )
    process {
        try {
            ## Define the drives to look for log files if local or the shares to look for when remote
            if ($ComputerName -eq 'localhost') {
                $Locations = (Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType = '3'").DeviceID
            }
            else {
                ## Enumerate all shares
                $Shares = Get-CimInstance -ComputerName $ComputerName -Class Win32_Share | Where-Object { $_.Path -match '^\w{1}:\\$' }
                [System.Collections.ArrayList]$Locations = @()
                foreach ($Share in $Shares) {
                    $Share = "\\$ComputerName\$($Share.Name)"
                    if (!(Test-Path $Share)) {
                        Write-Warning "Unable to access the '$Share' share on '$Computername'"
                    }
                    else {
                        $Locations.Add($Share) | Out-Null	
                    }
                }
            }

            ## Build the hashtable to perform splatting on Get-ChildItem
            $GciParams = @{
                Path        = $Locations
                Filter      = "*.$LogFileExtension"
                Recurse     = $true
                Force       = $true
                ErrorAction = 'SilentlyContinue'
                File        = $true
            }

            ## Build the Where-Object scriptblock on a separate line due to it's length
            $WhereFilter = {($_.LastWriteTime -ge $StartTimestamp) -and ($_.LastWriteTime -le $EndTimestamp) -and ($_.Length -ne 0)}

            ## Find all interesting log files
            Get-ChildItem @GciParams | Where-Object $WhereFilter
        }
        catch {
            Write-Error "$($_.Exception.Message) - Line Number: $($_.InvocationInfo.ScriptLineNumber)"
        }
    }
}
#>