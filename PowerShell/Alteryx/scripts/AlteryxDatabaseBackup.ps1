[CmdletBinding()]
Param(
    [Parameter(Mandatory, HelpMessage="Path to the backup location")]
    [string]$BackupLocation,

    [Parameter(HelpMessage="Defines whether this is a scheduled backup, or manually triggered")]
    [ValidateSet("Schedule","Manual")]
    [string]$InitiatedBy="Manual"
)

#requires -runasadministrator

#region 1. Declare required variables

#Path to the AlteryxService.exe file
[string]$AlteryxAppPath

#Important config files to be backed up
[string[]]$ConfigsLocations = @('C:\ProgramData\Alteryx\RuntimeSettings.xml',
                                'C:\ProgramData\Alteryx\Engine\SystemAlias.xml',
                                'C:\ProgramData\Alteryx\Engine\SystemConnections.xml')

#Name of the Event log we are writing to
[string]$LogName = "Alteryx Maintenance"

#This is the log source and is simply the name of the calling script of method
[string]$LogSource = "Database Backup"

#To store messages that are written to the event logs
[String]$Message

$ErrorActionPreference = "SilentlyContinue"

#endregion 1. Declare required variables

#region 2. Create Event Log (needs runasadmin)
New-EventLog -LogName $LogName -Source $LogSource

#Write an entry to say the script was run and by whom
Write-Verbose "Write a log entry to show who ran this code"
$Message = "This backup was executed by " + $env:USERNAME
Write-Verbose $Message
Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message

#endregion 2. Create Event Log (needs runasadmin)

#Begin try...
try {
    #region 3. Stop the Alteryx windows service

    #Look for the Alteryx windows service and store as a variable
    $Service = Get-Service | Where-Object -Property Name -Like 'Alteryx*'

    #Stores the full path to the executable for calling the service manually
    $AlteryxAppPath = (Get-WmiObject win32_service | Where-Object -Property Name -like $Service.name | Select-Object -ExpandProperty PathName).Replace('"','')

    #Check we have a service to work with
    If(!($null -eq $Service)) {
        $Message = "Stopping Alteryx windows service"
        Write-Verbose $Message
        Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 3 -Message $Message

        #Switch statement based on service status
        switch ($Service.Status) {
            "Stopped" {
                #Service is already stopped.  Note this in the logs
                $Message = "Alteryx service was already stopped before the sctipt was run"
                Write-Warning $Message
                Write-EventLog -LogName $LogName -Source $LogSource -EntryType Warning -EventId 21 -Message $Message
            }
            "Running" {
                #Set service startup type to manaul
                $Service | Set-Service -StartupType Manual

                #Stop the service (doesn't always work)
                #$Service | Stop-Service -Force -PassThru:$False

                #get the process ID
                $ProcessID = Get-CimInstance -Class Win32_Service -Filter "Name LIKE 'AlteryxService'" | Select-Object -ExpandProperty ProcessId

                #Kill the process
                $status = "taskkill /pid $ProcessID /f" | cmd.exe

                #Checks if service was stopped OK
                If("Stopped" -eq $Service.Status) {
                    $Message = "The Alteryx windows service has been stopped successfully"
                    Write-Verbose $Message
                    Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 4 -Message $Message
                }
                Else {
                    $Message = "The Alteryx windows service was not stopped successfully, aborting backup"
                    Throw $Message
                }
            }
            Default {
                #Service in unknown state, abort backup
                $Message = "The service is not in a suitable state for the backup to continue, aborting"
                Throw $Message
            }
        }
    }
    Else {
        $Message = "No service with name beginning 'Alteryx' was found on this machine.  Check the service exists and try again"
        Throw $Message
    }

    #endregion 3. Stop the Alteryx windows service

    #region 4. Backup mongoDB

    #Check backup temp location exists
    If(!(Test-Path -Path "$BackupLocation\temp")) {

        New-Item -Path "$BackupLocation\temp" -ItemType Directory -Force | Out-Null

        $Message = "Beginning database backup of Alteryx MongoDB instance"
        Write-Verbose $Message
        Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 4 -Message $Message

        &($AlteryxAppPath) emongodump="$BackupLocation\temp"

        $Message = "Backup of Alteryx MongoDB instance complete"
        Write-Verbose $Message
        Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 5 -Message $Message
    }
    Else {
        $Message = "Beginning database backup of Alteryx MongoDB instance"
        Write-Verbose $Message
        Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 4 -Message $Message

        &($AlteryxAppPath) emongodump="$BackupLocation\temp"

        $Message = "Backup of Alteryx MongoDB instance complete"
        Write-Verbose $Message
        Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 5 -Message $Message
    }

    #endregion 4. Backup mongoDB

    #region 5. Backup critical configs

    $Message = "Backing up Alteryx Config Files"
    Write-Verbose $Message
    Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 6 -Message $Message

    Foreach($Backup in $ConfigsLocations) {
        If(Test-Path -Path $Backup -IsValid) {
            Copy-Item -Path $Backup -Destination "$BackupLocation\temp" -Force
        }
    }

    #endregion 5. Backup critical configs

    #region 6. Backup alteryx machine key

    $Message = "Backing up Alteryx Machine Key"
    Write-Verbose $Message
    Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 7 -Message $Message

    &($AlteryxAppPath) getserversecret |  Out-File -FilePath "$BackupLocation\temp\ControllerToken.txt" -Force

    If(Test-Path -Path "$BackupLocation\temp\ControllerToken.txt") {
        $Message = 'Machine key was backed up successfully'
        Write-Verbose $Message
        Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 8 -Message $Message
    }
    Else {
        $Message = 'Machine key was not backed up successfully'
        Write-Warning $Message
        Write-EventLog -LogName $LogName -Source $LogSource -EntryType Warning -EventId 22 -Message $Message
    }

    #endregion 6. Backup alteryx machine key

    #region 7. Restart Alteryx windows service

    #Check we have a service to work with
    If(!($null -eq $Service)) {
        $Message = "Starting Alteryx windows service"
        Write-Verbose $Message
        Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 9 -Message $Message

        #Switch statement based on service status
        switch ($Service.Status) {
            "Running" {
                #Service is already running.  Note this in the logs
                $Message = "Alteryx service was already running"
                Write-Warning $Message
                Write-EventLog -LogName $LogName -Source $LogSource -EntryType Warning -EventId 23 -Message $Message
            }
            "Stopped" {
                #Attempt to start the service
                $Service | Set-Service -StartupType Automatic
                $Service | Start-Service -PassThru:$false

                #Checks if service was started OK
                If("Running" -eq $Service.Status) {
                    $Message = "The Alteryx windows service has been started successfully"
                    Write-Verbose $Message
                    Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 10 -Message $Message
                }
                Else {
                    $Message = "The Alteryx windows service was not started successfully, please check on this"
                    Throw $Message
                }
            }
            Default {
                #Service in unknown state, abort backup
                $Message = "The service is not in a suitable state for starting, aborting script"
                Throw $Message
            }
        }
    }
    Else {
        $Message = "No service with name beginning 'Alteryx' was found on this machine.  Check the service exists and try again"
        Throw $Message
    }

    #endregion 7. Restart Alteryx windows service

    #region 8. Archive the backup and dispose of the local files

    $Message = "Archiving backup and disposing of local copies"
    Write-Verbose $Message
    Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 11 -Message $Message

    New-Item -Path "$BackupLocation\archive" -ItemType Directory -Force | Out-Null

    If("Schedule" -eq $InitiatedBy) {
        New-Item -Path "$BackupLocation\archive\scheduled" -ItemType Directory -Force | Out-Null

        $ZipSuffix = (Get-Date -Format yy.MMdd.hhmmss) + '.zip'

        #Compress-Archive -Path "$BackupLocation\temp\*" -DestinationPath "$BackupLocation\archive\scheduled\$ZipSuffix" -CompressionLevel Optimal

        If(Test-Path -Path "$BackupLocation\archive\scheduled\$ZipSuffix") {
            $Message = "Archiving successful, removing local files"
            Write-Verbose $Message
            Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 16 -Message $Message

            Get-ChildItem -Path "$BackupLocation\temp\" | Remove-Item -Recurse -Force
        }
        Else {
            $Message = "Archiving failed, review local files"
            Write-Verbose $Message
            Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 12 -Message $Message
        }
    }
    Else {
        New-Item -Path "$BackupLocation\archive\manual" -ItemType Directory -Force | Out-Null

        $ZipSuffix = (Get-Date -Format yy.MMdd.hhmmss) + '.zip'

        Compress-Archive -Path "$BackupLocation\temp\*" -DestinationPath "$BackupLocation\archive\manual\$ZipSuffix" -CompressionLevel Optimal

        If(Test-Path -Path "$BackupLocation\archive\manual\$ZipSuffix") {
            $Message = "Archiving successful, removing local files"
            Write-Verbose $Message
            Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 16 -Message $Message

            Get-ChildItem -Path "$BackupLocation\temp\" | Remove-Item -Recurse -Force
        }
        Else {
            $Message = "Archiving failed, review local files"
            Write-Verbose $Message
            Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 12 -Message $Message
        }
    }

    #endregion 8. Archive the backup and dispose of the local files
}
#Any errors are thrown to the catch block
catch {
    Write-Error $Message
    Write-EventLog -LogName $LogName -Source $LogSource -EntryType Error -EventId 30 -Message $Message
}