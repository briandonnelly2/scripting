[CmdletBinding()]
Param(
    [Parameter(Mandatory, HelpMessage="Full Path to the backup being restored")]
    [string]$BackupPath,

    [Parameter(Mandatory, HelpMessage="The name of the server we are restoring to")]
    [string]$RestoreServer
)

#requires -runasadministrator

#region 1. Declare required variables

#Path to the temp location for the current restore
[string]$RestoreLTempLocation = $ENV:Temp + '\' + (Get-Date -Format yy.MMdd)

#Path to the AlteryxService.exe file
[string]$AlteryxAppPath

#Rumtime Settings file location
[string]$RumtimeSettingsLocation = "$ENV:ProgramData\Alteryx"

#Name of the Event log we are writing to
[string]$LogName = "Alteryx Maintenance"

#This is the log source and is simply the name of the calling script of method
[string]$LogSource = "Database Restore"

#To store messages that are written to the event logs
[String]$Message

$ErrorActionPreference = "SilentlyContinue"

#endregion 1. Declare required variables

#region 2. Create Event Log (needs runasadmin)
New-EventLog -LogName $LogName -Source $LogSource

#Write an entry to say the script was run and by whom
Write-Verbose "Write a log entry to show who ran this code"
$Message = "This restore was executed by " + $env:USERNAME
Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 31 -Message $Message

#endregion 2. Create Event Log (needs runasadmin)

Try {
    #region 3. Locate backup file and expand archive...

    $Message = "Locating backup and expanding archive into temp directory"
    Write-Verbose $Message
    Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 32 -Message $Message

    #Test to see if the backup file exists
    If(Test-Path -Path $BackupPath) {
        #Backup file exists, expand the archive
        Expand-Archive -Path $BackupPath -DestinationPath $RestoreLTempLocation -Force

        #Test that the zip has successfully been expanded
        If(Test-Path -Path $RestoreLTempLocation) {
            $Message = "Archive expand successful"
            Write-Verbose $Message
            Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 33 -Message $Message
        }
        Else {
            $Message = "Archive expand failed, aborting restore"
            Throw $Message
        }
    }
    Else {
        #Backup path supplied does not exist
        $Message = "The backup does not exist, aborting restore"
        Throw $Message
    }

    #endregion 3. Locate backup file and expand archive...

    #region 4. Stop the Alteryx windows service

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
                #Attempt to stop the service
                $Service | Set-Service -StartupType Manual
                $Service | Stop-Service -PassThru:$False

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

    #endregion 4. Stop the Alteryx windows service

    #region 5. Restore critical configs

    $Message = "Restoring Alteryx Runtime Settings File"
    Write-Verbose $Message
    Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 36 -Message $Message

    #Checks to see if the RuntimeSettings.xml file exists
    If(Test-Path -Path ($RestoreLTempLocation + '\RuntimeSettings.xml') -IsValid) {
        Copy-Item -Path ($RestoreLTempLocation + '\RuntimeSettings.xml') -Destination $RumtimeSettingsLocation -Force
    }
    Else{
        $Message = "Alteryx Runtime Settings File did not exist and was not restored. The remaining parts of the restore will need to be completed manually."
        Write-Warning $Message
        Write-EventLog -LogName $LogName -Source $LogSource -EntryType Warning -EventId 37 -Message $Message
    }

    #endregion 5. Restore critical configs

    #region 6. Restore Alteryx encrypted details...

    $Message = "Restoring Alteryx Machine Key"
    Write-Verbose $Message
    Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 38 -Message $Message

    #Checks the machine key is in the backup location
    If(Test-Path -Path "$RestoreLTempLocation\ControllerToken.txt") {
        #Reads the value within the machine key backup file
        $MachineKey = Get-Content -Path "$RestoreLTempLocation\ControllerToken.txt"

        #Alteryx service command to update the machine key in the config
        &($AlteryxAppPath) setserversecret="$MachineKey"

        $Message = 'Machine key was restored successfully'
        Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 39 -Message $Message
    }
    Else {
        $Message = 'Machine key did not exist in the backup location, please restore this manually'
        Write-EventLog -LogName $LogName -Source $LogSource -EntryType Warning -EventId 40 -Message $Message
    }

    #Ask the user executing the restore to enter the details of the 'run as' service account
    $RunAsSACred = Get-Credential -Message 'Please enter the run as account username and password. Username should be prefixed with the windows domain.' -UserName 'UK\'

    #Store the domain name from the entered credentials
    $Domain = ($RunAsSACred.UserName).Split('\')[0]

    #Store the username from the entered credentials
    $Username = ($RunAsSACred.UserName).Split('\')[1]

    #Converts the secure password to plain text and stores
    $PlainPW = $RunAsSACred.GetNetworkCredential().Password

    #Alteryx service command to update the 'run as' user details with the service account provided
    &($AlteryxAppPath) setexecuteuser="$Username","$Domain","$PlainPW"

    #Load the backed up RuntimeSettings.xml file
    [xml]$RuntimeSettingsBackupxml = Get-Content -Path "$RestoreLTempLocation\RuntimeSettings.xml"

    #Retrieve the 'StorageKeysEncrypted' value from the file
    [string]$StorageKeysEncrypted = $RuntimeSettingsBackupxml.SystemSettings.Controller.StorageKeysEncrypted

    #Load the backed up RuntimeSettings.xml file
    [xml]$RuntimeSettingsRestorexml = Get-Content -Path "$RumtimeSettingsLocation\RuntimeSettings.xml"

    #Update the StorageKeysEncrypted in the runtimesettings file on the restoration server
    $RuntimeSettingsRestorexml.SystemSettings.Controller.StorageKeysEncrypted = $StorageKeysEncrypted

    #Update the gallery URL for the new server
    $RuntimeSettingsRestorexml.SystemSettings.Gallery.BaseURI = "https://$RestoreServer/Gallery"

    #Then save the file
    $RuntimeSettingsRestorexml.Save("$RumtimeSettingsLocation\RuntimeSettings.xml")

    #endregion 6. Restore Alteryx encrypted details... 

    #region 7. Restore mongoDB

    #Check temp location for restore files exists
    If(Test-Path -Path $RestoreLTempLocation) {

        $Message = "Beginning database restore of Alteryx MongoDB instance"
        Write-Verbose $Message
        Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 34 -Message $Message

        #Rename the current MongoDB location
        Rename-Item -Path "$ENV:ProgramData\Alteryx\Service\Persistence\MongoDB" -NewName "$ENV:ProgramData\Alteryx\Service\Persistence\MongoDB_OLD" -Force

        #Create an empty folder for the database to be restored to
        New-Item -Path "$ENV:ProgramData\Alteryx\Service\Persistence" -Name "MongoDB" -ItemType "Directory" -Force

        #Alteryx service command to restore the database
        &($AlteryxAppPath) emongorestore="$RestoreLTempLocation","C:\ProgramData\Alteryx\Service\Persistence\MongoDB"

        $Message = "Restore of Alteryx MongoDB instance complete"
        Write-Verbose $Message
        Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 35 -Message $Message

        #Start up the MongoDB database. Leave this window open.
        mongod ––dbpath ”C:\ProgramData\Alteryx\Service\Persistence\MongoDB” ––auth ––port 27018

        #Retrieve the MongoDB connection password
        $MongoPassword = &($AlteryxAppPath) getemongopassword

        #Grab the non-admin password
        $FormattedMongoPasssword = $MongoPassword[1].Replace('Non-Admin: ','')

        #Connect to the MongoDB database
        mongo mongodb://localhost:27018/AlteryxGallery -u user -p "$FormattedMongoPasssword"

        #Remove the records from the locks collection in the AlteryxGallery database
        db.locks.remove({})
    }
    Else {
        $Message = "Restore location does not exist, aborting restore"
        Throw $Message
    }

    #endregion 7. Restore mongoDB

    #region 8. Restart Alteryx windows service

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

    #endregion 8. Restart Alteryx windows service

    #region 9. Remove temporary files

    Get-ChildItem -Path $RestoreLTempLocation | Remove-Item -Recurse -Force

    #endregion 9. Remove temporary files
}

catch {
    Write-Error $Message
    Write-EventLog -LogName $LogName -Source $LogSource -EntryType Error -EventId 30 -Message $Message
}
