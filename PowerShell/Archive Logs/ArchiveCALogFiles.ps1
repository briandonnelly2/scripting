#Script Name ArchiveCAlogFiles.ps1
#Creator Brian Donnelly
#Date 14/10/2018
#Updated 03/07/2020

#Variables
$Date = (Get-Date).AddDays(-1) #Gets yesterdays date
$DateStamp = $Date.ToString("yyyyMMdd") #Converts to the correct format
$LogPath = 'G:\TTGAppLogs\Ca.Web' #Specifies the location the log files 
$LogFileName = 'Ca.Web-' + $DateStamp #Specifies the logfile name we are looking for based on the date
$TimeStamp=Get-Date -Format yy-MM-dd_HH-mm-ss

$LogFilePath = $LogPath + '\' + $LogFileName #Full path to logfile being archived
$BackupPath='G:\TTGLogsBackup\Ca.Web' #location where the logfile will be backed up to
$ScriptLog='script-log.txt' #name of the file logging what this scrpt does.
$ScriptLogPath=Join-Path -Path $BackupPath -ChildPath $ScriptLog #Full path to the script logfile

#Checks whether the backup location exists and creates it if not
If(-Not (Test-Path -Path $BackupPath)) {
    #Try-catch statement for permissions error
    Try {
        New-Item -Path $BackupPath -ItemType Directory -Force
        'Ca.Web Log Backup - Run History' | Out-File -FilePath $ScriptLogPath -Append -Force
    }
    Catch {
        Write-Warning -Message 'Cannot create backup location.  This may be a permissions error.'
        #quit out of script
        #return
    }
}

If(!(Test-Path $ScriptLogPath)) {
    'Ca.Web Log Backup - Run History' | Out-File -FilePath $ScriptLogPath -Append -Force
    '_________________________________________' | Out-File -FilePath $ScriptLogPath -Append -Force
    ' ' | Out-File -FilePath $ScriptLogPath -Append -Force
}

#First tests to see if the logfile exists in the directory
If(Test-Path -Path $LogFilePath) {
    #Grabs information about the log file @{name="FileSize";Expression={($_.Length)/1MB }},
    $LogFileInfo=Get-ChildItem -Path $LogPath | Select-Object name, @{name="LogSize";Expression={($_.Length)/1MB }}
    #add an entry to the log
    $Message=$TimeStamp + ' - Current log file size: ' + [math]::Round($LogFileInfo.LogSize, 2)
    $Message | Out-File -FilePath $ScriptLogPath -Append -Force

    #Then tests to see of the log file exceeds 3 MB
    If($LogFileInfo.LogSize -gt 100) {
        #Copy log file to the backup location
        Copy-Item -Path $LogFilePath -Destination $BackupPath -Force

        #Sets a name for the archive file and adds a date stamp.
        $ArchiveName = $LogFileName + '.zip'

        #Try-catch for errors when zipping the file
        Try {
            Compress-Archive -LiteralPath (Join-Path -Path $BackupPath -ChildPath $LogFileName) `
                -CompressionLevel Optimal -DestinationPath (Join-Path -Path $BackupPath -ChildPath $ArchiveName)
        }
        Catch {
            #Write an entry to the logfile
            $Message = $TimeStamp + ' - Something went wrong while zipping the file.'
            $Message | Out-File -FilePath $ScriptLogPath -Append -Force
        }
        finally {
            #Check if the archive has been created
            If(Test-Path -Path (Join-Path -Path $BackupPath -ChildPath $ArchiveName)) {
                #Delete original log file and the copy taken to the backup folder.
                Remove-Item -Path (Join-Path -Path $BackupPath -ChildPath $LogFileName) -Force -ErrorAction SilentlyContinue
                Remove-Item -Path $LogFilePath -Force -ErrorAction SilentlyContinue
                #add an entry to the log
                $Message=$TimeStamp + ' - Log file ' + $ArchiveName + ' archived. All other copies of log file deleted.'
                $Message | Out-File -FilePath $ScriptLogPath -Append -Force
                ' ' | Out-File -FilePath $ScriptLogPath -Append -Force
        }
            else {
                #Delete copy of the log file and leave original in place.
                Remove-Item -Path (Join-Path -Path $BackupPath -ChildPath $LogFileName) -Force -ErrorAction SilentlyContinue
                #add an entry to the log
                $Message=$TimeStamp + ' - Copy of log file deleted. Original remains in place'
                $Message | Out-File -FilePath $ScriptLogPath -Append -Force
                ' ' | Out-File -FilePath $ScriptLogPath -Append -Force
            }
        }
    }
    #When file is under 100 MB....
    Else {
        #Write an entry to the logfile
        $Message=$TimeStamp + ' - Log File is under 100 MB.  Archiving not needed.  Current size: ' + [math]::Round($LogFileInfo.LogSize, 2)
        $Message | Out-File -FilePath $ScriptLogPath -Append -Force
        ' ' | Out-File -FilePath $ScriptLogPath -Append -Force
        #Quit out of script
        return
    }
}
#When there is no log file to copy...
Else {
    #Write an entry to the logfile
        $Message=$TimeStamp + ' - ' + $LogFileName + ' does not exist at location ' + $LogPath
        $Message | Out-File -FilePath $ScriptLogPath -Append -Force
        ' ' | Out-File -FilePath $ScriptLogPath -Append -Force
        #Quit out of script
        return
}


<# Each command should be executed in sequence and one at a time #>

# 1. Stores your oper credentials in a variable
$cred=Get-Credential -UserName UK\-oper-briandonnelly2 -Message 'Please enter your -oper- account credentials'

# 2. Removes any existing sessions
Get-PSSession | Remove-PSSession

# 3. Opens a session to all four servers above
$sess=New-PSSession -ComputerName UKVMSAPP036, UKVMSAPP062, UKVMSAPP068, UKVMSAPP069 -Credential $cred

# 4. Creates a script blocl of commands to be executed on each server
$sb = {
    Set-Location -Path E:\Scripts\
    .\-svc-EfilingWFSDigitaDMSLogArchive.ps1
    #$Search = (Get-Date -Format yy-MM-dd_HH-mm).ToString() + '*'
    Get-Content -Path 'E:\TTGAppLogs\-svc-EfilingWFS Digita Document Management Service Log Archive\script-log.txt' | Out-Host
}

# 5. Invokes the script block using the sessions we created
Invoke-Command -Session $sess -ScriptBlock $sb 

# 6. Kills all open sessions
Get-PSSession | Remove-PSSession