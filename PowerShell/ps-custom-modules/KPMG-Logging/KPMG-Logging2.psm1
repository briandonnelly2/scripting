Set-StrictMode -Version 1.0
$ErrorActionPreference = "Stop"
Function New-KPMGLog {
<#
    .SYNOPSIS
        This function creates a new log file.
    .DESCRIPTION
        Creates a log file with the path and name specified in the parameters. Checks if log file exists, and if it does deletes it and creates a new one.
        Then adds a header with the date and time the file was created along with other initial logging data..
    .PARAMETER LogFileDir
        MANDATORY: The folder path the file is to be created at.
    .PARAMETER LogFileName
        MANDATORY: The name of the file to be created.
    .PARAMETER JobGUID
        MANDATORY: The purpose of the log.  SHould be simple, such as: 'App Deployment Log'
    .PARAMETER ToConsole
        OPTIONAL: Switch that outouts the current log entry to the console if true.
    .NOTES
        Version:                1.0
        Author:                 Brian Donnelly
        Creation Date:          29 March 2019
        Modified Date:          N/A
        Revfiew Date:           29 June 2019
        Future Enhancements:    N/A
    .EXAMPLE
        Creates a new logfile

            New-KPMGLog -LogFileDir $LogFileDir -LogFileName "$StaticTimeStamp.log"
    .EXAMPLE
        New-KPMGLog -LogFileDir $LogFileDir -LogFileName "$StaticTimeStamp.log"
#>

    [CmdletBinding()]
    Param(
        [Parameter( Mandatory, Position = 0,
        HelpMessage = "Please provide the logs directory" )]
        [ValidateScript({
            If ( !( Test-Path -Path $_ -PathType Container ) ) {
                Throw "The log file directory supplied does not exist! Please check this directory."
            } Else { $True }
        })]
        [string]$LogFileDir,

        [Parameter( Mandatory, Position = 1,
        HelpMessage = "Please provide the log file name" )]
        [string]$LogFileName,

        [Parameter( Position = 2,
        HelpMessage = "A GUID should be supplied for this Job" )]
        [ValidateLength(1,60)]
        [string]$JobGUID,

        [Parameter( Position = 3,
        HelpMessage = "If true, outputs log entry to the console." )]
        [switch]$ToConsole
    )

    process {
        #Stores the full logfile path.
        [string]$LogFilePath = Join-Path -Path $LogFileDir -ChildPath "$LogFileName.txt"

        #Removes any logfile with the same name
        If ( Test-Path -Path $LogFilePath ) {
            Remove-Item -Path $LogFilePath -Force
        }

        Try {
            #Creates the logfile
            New-Item -Path $LogFilePath -ItemType File -Force -ErrorAction SilentlyContinue | Out-Null

            If( !( Test-Path $LogFilePath ) ) {
                Throw "Error when creating log file at [$($LogFilePath)] - Check you have permissions to create files here"
            }

            #Adds a header to the logfile
            Add-Content -Path $LogFilePath -Value "***************************************************************************************************"
            Add-Content -Path $LogFilePath -Value "KPMG Logfile - Created $(Get-Date -format D) at $(Get-Date -format T)"
            Add-Content -Path $LogFilePath -Value "***************************************************************************************************"
            Add-Content -Path $LogFilePath -Value ""
            Add-Content -Path $LogFilePath -Value "Job GUID: $JobGUID"
            Add-Content -Path $LogFilePath -Value ""
            Add-Content -Path $LogFilePath -Value "***************************************************************************************************"
            Add-Content -Path $LogFilePath -Value ""

            #Write to screen for debug mode
            Write-Debug "***************************************************************************************************"
            Write-Debug "KPMG Logfile - Created $(Get-Date -format D) at $(Get-Date -format T)"
            Write-Debug "***************************************************************************************************"
            Write-Debug ""
            Write-Debug "Job GUID: $JobGUID"
            Write-Debug ""
            Write-Debug "***************************************************************************************************"
            Write-Debug ""

            #Write to screen for ToConsole mode
            If ( !( $false -eq $ToConsole ) ) {
                Write-Verbose "ToConsole flag is set to true, writing to the console"

                Write-Output "***************************************************************************************************"
                Write-Output "KPMG Logfile - Created $(Get-Date -format D) at $(Get-Date -format T)"
                Write-Output "***************************************************************************************************"
                Write-Output ""
                Write-Output "Job GUID: $JobGUID"
                Write-Output ""
                Write-Output "***************************************************************************************************"
                Write-Output ""

                return $LogFilePath
            }
            #Otherwise, returns the logfile path
            Else { return $LogFilePath }      
        }
        Catch {
            Write-Error "ERROR: $($_.Exception.message)"
        }
    }
}

Function Write-KPMGLogInfo {
<#
    .SYNOPSIS
        Writes information type message to specified log file
    .DESCRIPTION
        Appends a new information type message to the specified log file
    .PARAMETER LogFilePath
        MANDATORY: The full path to the logfile
    .PARAMETER Message
        OPTIONAL: The message to be recorded.
    .PARAMETER ToConsole
        OPTIONAL: Switch that outputs the current log entry to the console if needed.
    .INPUTS
        [System.String] 
    .OUTPUTS
        [System.Object]
    .NOTES
        Version:                1.0
        Author:                 Brian Donnelly
        Creation Date:          29 March 2019
        Modified Date:          N/A
        Revfiew Date:           29 June 2019
        Future Enhancements:    N/A   
    .EXAMPLE
        Writes a new information type log message to a new line in the specified log file

            Write-LogInfo -LogFilePath "C:\Windows\Temp\Test_Script.log" -Message "This is a info message."
    .EXAMPLE
        Writes a new information type log message to a new line in the specified log file and outputs to the console

            Write-LogInfo -LogFilePath "C:\Windows\Temp\Test_Script.log" -Message "This is a info message." -ToConsole:$True  
#>
    
    [CmdletBinding()]
    Param(
        [Parameter( Mandatory, Position = 0,
        HelpMessage = "Please provide the logs directory" )]
        [ValidateScript({
            If ( !( Test-Path -Path $_ -PathType Leaf ) ) {
                Throw "The log file directory supplied does not exist! Please check this directory."
            } Else { $True }
        })]
        [string]$LogFilePath,

        [Parameter( ValueFromPipeline, Position = 1,
        HelpMessage = "Please provide a message to be written" )]
        [string]$Message,

        [Parameter( Position = 2,
        HelpMessage = "If true, outputs log entry to the console." )]
        [switch]$ToConsole
    )

    Process {
        Try {
            #Defines the message to be written
            $Message = "[$(Get-Date -Format T)]$Message"

            #Adds message to the logfile
            Add-Content -Path $LogFilePath -Value $Message

            #Write to screen for debug mode
            Write-Debug $Message

            #Write to screen for ToConsole mode
            If ( !( $False -eq $ToConsole ) ) {
                Write-Output $Message
            }
        } Catch {
            Write-Error "ERROR: $($_.Exception.message)"
        }
    }
}

Function Write-KPMGLogWarning {
<#
    .SYNOPSIS
        Writes warning message to specified log file
    .DESCRIPTION
        Appends a new warning message to the specified log file
    .PARAMETER LogFilePath
        MANDATORY: The full path to the logfile
    .PARAMETER Message
        OPTIONAL: The message to be recorded.
    .PARAMETER ToConsole
        OPTIONAL: Switch that outputs the current log entry to the console if true.
    .INPUTS
        [System.String] 
    .OUTPUTS
        [System.Object]
    .NOTES
        Version:                1.0
        Author:                 Brian Donnelly
        Creation Date:          29 March 2019
        Modified Date:          N/A
        Revfiew Date:           29 June 2019
        Future Enhancements:    N/A   
    .EXAMPLE
        Writes a new warning log message to a new line in the specified log file
        
            Write-LogWarning -LogFilePath "C:\Windows\Temp\Test_Script.log" -Message "This is a warning message."
    .EXAMPLE
        Writes a new warning log message to a new line in the specified log file and outputs to the console
        
            Write-LogWarning -LogFilePath "C:\Windows\Temp\Test_Script.log" -Message "This is a warning message." -ToConsole:$True  
#>
    
    [CmdletBinding()]
    Param(
        [Parameter( Mandatory, Position = 0,
        HelpMessage = "Please provide the logs directory" )]
        [ValidateScript({
            If ( !( Test-Path -Path $_ -PathType Leaf ) ) {
                Throw "The log file directory supplied does not exist! Please check this directory."
            } Else { $True }
        })]
        [string]$LogFilePath,

        [Parameter( ValueFromPipeline, Position = 1,
        HelpMessage = "Please provide a message to be written" )]
        [string]$Message,

        [Parameter( Position = 2,
        HelpMessage = "If true, outputs log entry to the console." )]
        [switch]$ToConsole
    )

    Process {
        Try {
            #Defines the message to be written
            $Message = "[$(Get-Date -Format T)]WARNING: $Message"

            #Adds message to the logfile
            Add-Content -Path $LogFilePath -Value $Message

            #Write to screen for debug mode
            Write-Debug $Message

            #Write to screen for ToConsole mode
            If ( !( $False -eq $ToConsole ) ) {
                Write-Output $Message
            }
        } Catch {
            Write-Error "ERROR: $($_.Exception.message)"
        }
    }
}

Function Write-KPMGLogError {
<#
    .SYNOPSIS
        Writes error message to specified log file
    .DESCRIPTION
        Appends a new warning message to the specified log file
    .PARAMETER LogFilePath
        MANDATORY: The full path to the logfile
    .PARAMETER Message
        OPTIONAL: The message to be recorded.
    .PARAMETER ExitGracefully
        OPTIONAL: If true, runs the Stop-Log function and then exits script
    .PARAMETER ToConsole
        OPTIONAL: Switch that outputs the current log entry to the console if true.
    .INPUTS
        [System.String] 
    .OUTPUTS
        [System.Object]
    .NOTES
        Version:                1.0
        Author:                 Brian Donnelly
        Creation Date:          24 January 2019
        Modified Date:          N/A
        Revfiew Date:           24 April 2019
        Future Enhancements:    
    .EXAMPLE
        Writes a new error log message to a new line in the specified log file. Once the error has been written,
        the Stop-Log function is executed and the calling script is exited.
        
            Write-LogError -LogFilePath "C:\Windows\Temp\Test_Script.log" -Message "This is a error message." -ExitGracefully
    .EXAMPLE
        Writes a new error log message to a new line in the specified log file, but does not execute the Stop-Log
        function, nor does it exit the calling script. In other words, the only thing that occurs is an error message
        is written to the log file.

        Note: If you don't specify the -ExitGracefully parameter, then the script will not exit on error.
        
            Write-LogError -LogFilePath "C:\Windows\Temp\Test_Script.log" -Message "This is a error message."
    .EXAMPLE
        Writes a new error log message to a new line in the specified log file and outputs to the console
        
            Write-LogError -LogFilePath "C:\Windows\Temp\Test_Script.log" -Message "This is a error message." -ToConsole:$True  
#>
    
    [CmdletBinding()]
    Param(
        [Parameter( Mandatory, Position = 0,
        HelpMessage = "Please provide the logs directory" )]
        [ValidateScript({
            If ( !( Test-Path -Path $_ -PathType Leaf ) ) {
                Throw "The log file directory supplied does not exist! Please check this directory."
            } Else { $True }
        })]
        [string]$LogFilePath,

        [Parameter( ValueFromPipeline, Position = 1,
        HelpMessage = "Please provide a message to be written" )]
        [string]$Message,

        [Parameter( Position = 2,
        HelpMessage = "If true, allows the script to quit in an ordered manner" )]
        [switch]$ExitGracefully,

        [Parameter( Position = 3,
        HelpMessage = "If true, outputs log entry to the console." )]
        [switch]$ToConsole
    )

    Process {
        Try {
            #Defines the message to be written
            $Message = "[$(Get-Date -Format T)]ERROR: $Message"

            #Adds message to the logfile
            Add-Content -Path $LogFilePath -Value $Message

            #Write to screen for debug mode
            Write-Debug $Message

            #Write to screen for ToConsole mode
            If ( !( $False -eq $ToConsole ) ) {
                Write-Output $Message
            }

            #If $ExitGracefully = True then run Log-Finish and exit script
            If ( $ExitGracefully -eq $True ){
                Add-Content -Path $LogFilePath -Value " "
                Stop-KPMGLog -LogFilePath $LogFilePath
                Break
            }
        } Catch {
            Write-Error "ERROR: $($_.Exception.message)"
        }
    }
}

Function Write-KPMGLogObject {
<#
    .SYNOPSIS
        Writes object data to the specified logfile.
    .DESCRIPTION
        Appends object data to the specified log file. This is for the purpose
        of recording lists of data we may wish to record in the logfile. The formatting
        of the data recorded cannot be fully predicted as it cannot be known what object 
        will be passed to this function.
    .PARAMETER LogFilePath
        MANDATORY: The full path to the logfile
    .PARAMETER Object
        OPTIONAL: The object to be recorded
    .PARAMETER ToConsole
        OPTIONAL: Switch that outputs the current log entry to the console if true.
    .INPUTS
        [System.String]
        [System.Object] 
    .OUTPUTS
        [System.Object]
    .NOTES
        Version:                1.0
        Author:                 Brian Donnelly
        Creation Date:          29 March 2019
        Modified Date:          N/A
        Revfiew Date:           29 June 2019
        Future Enhancements:    N/A   
    .EXAMPLE
        Writes new object data to the specified log file
        
            Write-LogObject -LogFilePath "C:\Windows\Temp\Test_Script.log" -Object $UserData
    .EXAMPLE
        Writes new error object data to the specified log file
        
            Write-LogObject -LogFilePath "C:\Windows\Temp\Test_Script.log" -Object $Error
#>
    
    [CmdletBinding()]
    Param(
        [Parameter( Mandatory, Position = 0,
        HelpMessage = "Please provide the logs directory" )]
        [ValidateScript({
            If ( !( Test-Path -Path $_ -PathType Leaf ) ) {
                Throw "The log file directory supplied does not exist! Please check this directory."
            } Else { $True }
        })]
        [string]$LogFilePath,

        [Parameter( ValueFromPipeline, Position = 1,
        HelpMessage = "Please provide a message to be written" )]
        [System.Object]$Object,

        [Parameter( Position = 2,
        HelpMessage = "If true, outputs log entry to the console." )]
        [switch]$ToConsole
    )

    Process {
        Try {
            #Defines the message to be written
            $Message = "[$(Get-Date -Format T)]Object Data: 
                        $($Object.ToString())"

            #Adds message to the logfile
            Add-Content -Path $LogFilePath -Value $Message

            #Write to screen for debug mode
            Write-Debug $Message

            #Write to screen for ToConsole mode
            If ( !( $False -eq $ToConsole ) ) {
                Write-Output $Message
            }
        } Catch {
            Write-Error "ERROR: $($_.Exception.message)"
        }
    }
}

Function Stop-KPMGLog {
<#
    .SYNOPSIS
        Write closing data to log file & exits the calling script
    .DESCRIPTION
        Writes finishing logging data to specified log file and then exits the calling script 
    .PARAMETER LogFileDir
        MANDATORY: The folder path the file is to be created at.
    .PARAMETER NoExit
        OPTIONAL: If parameter specified, then the function will not exit the calling script, so that further execution can occur (like Send-Log)
    .PARAMETER ToConsole
        OPTIONAL: Switch that outouts the current log entry to the console if true.
    .INPUTS
        [System.String] 
    .OUTPUTS
        [System.Object]
    .NOTES
        Version:                1.0
        Author:                 Brian Donnelly
        Creation Date:          24 January 2019
        Modified Date:          N/A
        Revfiew Date:           24 April 2019
        Future Enhancements:    
    .EXAMPLE
        Writes the closing logging information to the log file and then exits the calling script.

        Note: If you don't specify the -NoExit parameter, then the script will exit the calling script.

            Stop-Log -LogFilePath "C:\Windows\Temp\Test_Script.log"
    .EXAMPLE
        Writes the closing logging information to the log file but does not exit the calling script. This then
        allows you to continue executing additional functionality in the calling script (such as calling the
        Send-Log function to email the created log to users).

            Stop-Log -LogFilePath "C:\Windows\Temp\Test_Script.log" -NoExit
#>
    
    [CmdletBinding()]
    Param(
        [Parameter( Mandatory, Position = 0,
        HelpMessage = "Please provide the logs directory" )]
        [ValidateScript({
            If ( !( Test-Path -Path $_ -PathType Leaf ) ) {
                Throw "The log file directory supplied does not exist! Please check this directory."
            } Else { $True }
        })]
        [string]$LogFilePath,

        [Parameter( Position = 1,
        HelpMessage = "If true, does not exit the calling script." )]
        [switch]$NoExit,

        [Parameter( Position = 2,
        HelpMessage = "If true, outputs log entry to the console." )]
        [switch]$ToConsole
    )

    Process {
        Try {
            Add-Content -Path $LogFilePath -Value ""
            Add-Content -Path $LogFilePath -Value "***************************************************************************************************"
            Add-Content -Path $LogFilePath -Value "Finished processing at  $(Get-Date -format D) at $(Get-Date -format T)."
            Add-Content -Path $LogFilePath -Value "***************************************************************************************************"

            #Write to screen for debug mode
            Write-Debug ""
            Write-Debug "***************************************************************************************************"
            Write-Debug "Finished processing at  $(Get-Date -format D) at $(Get-Date -format T)."
            Write-Debug "***************************************************************************************************"

            #Write to scren for ToConsole mode
            If ( !( $false -eq $ToConsole ) ) {
            Write-Output ""
            Write-Output "***************************************************************************************************"
            Write-Output "Finished processing at  $(Get-Date -format D) at $(Get-Date -format T)."
            Write-Output "***************************************************************************************************"
            }

            #Exit calling script if NoExit has not been specified or is set to False
            If( !($NoExit) -or ($NoExit -eq $False) ){
                Exit
            }          
        } Catch {
            Write-Error "ERROR: $($_.Exception.message)"
        }
    }
}

Function Send-KPMGLog {#Not yet defined
<#
    .SYNOPSIS
        High level, what the fucntion is for.
    .DESCRIPTION
        More detailed description of purpose and function
    .PARAMETER LogFileDir
        MANDATORY: The folder path the file is to be created at.
    .PARAMETER parameter
        Describes a parameter that can be passed in to the script
    .PARAMETER parameter
        Describes a parameter that can be passed in to the script
    .PARAMETER parameter
        Describes a parameter that can be passed in to the script
    .INPUTS
        [System.String] 
    .OUTPUTS
        [System.Object]
    .NOTES
        Version:                1.0
        Author:                 Brian Donnelly
        Creation Date:          24 January 2019
        Modified Date:          N/A
        Revfiew Date:           24 April 2019
        Future Enhancements:    
    .EXAMPLE
        Example of a way in which this command can be used.
        Example of a way in which this command can be used.
    .EXAMPLE
        Example of a way in which this command can be used.
        Example of a way in which this command can be used.
    .EXAMPLE
        Example of a way in which this command can be used.
        Example of a way in which this command can be used.
    .EXAMPLE
        Example of a way in which this command can be used.
        Example of a way in which this command can be used.
#>
    
    [CmdletBinding()]
    Param(
        [Parameter(HelpMessage="")]
        [System.Object]$ParameterName
    )

    Process {
        Try {

        } Catch {
            Write-Error "ERROR: $($_.Exception.message)"
        }
    }
}

Function Backup-KPMGLog {#Not yet defined
<#
    .SYNOPSIS
        High level, what the fucntion is for.
    .DESCRIPTION
        More detailed description of purpose and function
    .PARAMETER parameter
        Describes a parameter that can be passed in to the script
    .PARAMETER parameter
        Describes a parameter that can be passed in to the script
    .PARAMETER parameter
        Describes a parameter that can be passed in to the script
    .PARAMETER parameter
        Describes a parameter that can be passed in to the script
    .INPUTS
        [System.String] 
    .OUTPUTS
        [System.Object]
    .NOTES
        Version:                1.0
        Author:                 Brian Donnelly
        Creation Date:          24 January 2019
        Modified Date:          N/A
        Revfiew Date:           24 April 2019
        Future Enhancements:    
    .EXAMPLE
        Example of a way in which this command can be used.
        Example of a way in which this command can be used.
    .EXAMPLE
        Example of a way in which this command can be used.
        Example of a way in which this command can be used.
    .EXAMPLE
        Example of a way in which this command can be used.
        Example of a way in which this command can be used.
    .EXAMPLE
        Example of a way in which this command can be used.
        Example of a way in which this command can be used.
#>
    
    [CmdletBinding()]
    Param(
        [Parameter(HelpMessage="")]
        [System.Object]$ParameterName
    )

    Process {
        Try {

        } Catch {
            Write-Error "ERROR: $($_.Exception.message)"
        }
    }
}

Function New-KPMGEventLog {
    <#
    .SYNOPSIS
        This function creates a new Windows event log file.
    .DESCRIPTION
        Creates a windows event log  with source name(s) specified in the parameters. Checks if log file exists, 
        and if it does displays a suitable message.
    .PARAMETER LogName
        MANDATORY: The name of the event log to be created.
    .PARAMETER SourceNames
        MANDATORY: The names of the sources of the error messages as an array.
    .NOTES
        Version:                1.0
        Author:                 Brian Donnelly
        Creation Date:          27 Feb 2020
        Modified Date:          N/A
        Revfiew Date:           27 May 2020
        Future Enhancements:    N/A
    .EXAMPLE
        Example 1:  Creates a new Windows event log file

        New-KPMGEventLog -LogName "TTG Apps" -SourceNames @("Ca.Web", "Srt.Web")
    .EXAMPLE
        Example 2:  Creates a new Windows event log file using defined variables
        $LogName = "TTG Apps"
        $SourceNames = @("Ca.Web", "Srt.Web")

        New-KPMGEventLog -LogName $LogName -SourceNames $SourceNames
#>

    [CmdletBinding()]
    Param(
        [Parameter( Mandatory, Position = 0,
        HelpMessage = "Please provide the log file name" )]
        [string]$LogName,

        [Parameter( Mandatory, Position = 1,
        HelpMessage = "Please provide the event source(s)" )]
        [string[]]$SourceNames
    )

    process {

    Write-Verbose "Creating new log: " $LogName " and sources:" $SourceNames

        Try {
            foreach($logSource in $SourceNames) {

                if ([System.Diagnostics.EventLog]::SourceExists($logSource) -eq $false) {
                    Write-Verbose "Creating log source: '$logSource'."
                    New-EventLog -source $logSource -logname $LogName 
                    Write-Verbose "Source and log created."
                }
                else {
                    Write-Verbose "Source '$logSource' already exist." 
                }
            }
        }
        Catch {
            Write-Error "ERROR: $($_.Exception.message)"
        }
    }
}