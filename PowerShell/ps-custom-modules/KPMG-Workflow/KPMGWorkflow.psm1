#Script Name Archive-Files.ps1
#Creator Brian Donnelly
#Date 14/10/2018
#Updated 

#Variables

$DateStamp=Get-date -Format dd-MM-yy-mm-hh-ss
$LogPath='C:\Users\-svc-EfilingWFS\AppData\Local\Digita\Document Management Service'
$LogFileName='Log.xml'
$LogFilePath=Join-Path -Path $LogPath -ChildPath $LogFileName
$BackupPath='E:\TTGAppLogs\-svc-EfilingWFS Digita Document Management Service Log Archive'
$ScriptLog='ps-log.txt'
$ScriptLogPath=Join-Path -Path $BackupPath -ChildPath $ScriptLog

#Checks whether the backup location exists and creates it if not
If(-Not (Test-Path -Path $BackupPath)) {
    #Try-catch statement for permissions error
    Try {
        New-Item -Path $BackupPath -ItemType Directory -Force
        'E-Filing Service Log Backup - Run History' | Out-File -FilePath $ScriptLogPath -Append -Force
    }
    Catch {
        Write-Warning -Message 'Cannot create backup location.  This may be a permissions error.'
        #quit out of script
        #return
    }
}

#First tests to see if the logfile exists in the directory
If(Test-Path -Path $LogFilePath) {
    #Grabs information about the log file
    $LogFileInfo=Get-ChildItem -Path $LogPath | Select-Object name, @{name="LogSize";Expression={($_.Length)/1MB }}
    #add an entry to the log
    $Message=$DateStamp + ' - Current log file size: ' + $LogFileInfo.LogSize
    $Message | Out-File -FilePath $ScriptLogPath -Append -Force

    #Then tests to see of the log file exceeds 3 MB
    If($LogFileInfo.LogSize -gt 3) {
        #Copy log file to the backup location
        Copy-Item -Path $LogFilePath -Destination $BackupPath -Force

        #Sets a name for the archive file and adds a date stamp.
        $ArchiveName='Log' + '-' + $DateStamp + '.zip'

        #Try-catch for errors when zipping the file
        Try {
            Compress-Archive -LiteralPath (Join-Path -Path $BackupPath -ChildPath $LogFileName) `
                -CompressionLevel Optimal -DestinationPath (Join-Path -Path $BackupPath -ChildPath $ArchiveName)
        }
        Catch {
            #Write an entry to the logfile
            $Message=$DateStamp + ' - Something went wrong while zipping the file.'
            $Message | Out-File -FilePath $ScriptLogPath -Append -Force
        }
        finally {
            #Check if the archive has been created
            If(Test-Path -Path (Join-Path -Path $BackupPath -ChildPath $ArchiveName)) {
                #Delete original log file and the copy taken to the backup folder.
                Remove-Item -Path (Join-Path -Path $BackupPath -ChildPath $LogFileName) -Force -ErrorAction SilentlyContinue
                Remove-Item -Path $LogFilePath -Force -ErrorAction SilentlyContinue
                #add an entry to the log
                $Message=$DateStamp + ' - Log file ' + $ArchiveName + ' archived. All copies of log file deleted.'
                $Message | Out-File -FilePath $ScriptLogPath -Append -Force
        }
            else {
                #Delete copy of the log file and leave original in place.
                Remove-Item -Path (Join-Path -Path $BackupPath -ChildPath $LogFileName) -Force -ErrorAction SilentlyContinue
                #add an entry to the log
                $Message=$DateStamp + ' - Copy of log file deleted. Original remains in place'
                $Message | Out-File -FilePath $ScriptLogPath -Append -Force
            }
        }
    }
    #When file is under 3 MB....
    Else {
        #Write an entry to the logfile
        $Message=$DateStamp + ' - Log File is under 3 MB.  Archiving not needed.  Current size: ' + $LogFileInfo.LogSize
        $Message | Out-File -FilePath $ScriptLogPath -Append -Force
        #Quit out of script
        return
    }
}
#When there is no log file to copy...
Else {
    #Write an entry to the logfile
        $Message=$DateStamp + ' - ' + $LogFileName + ' does not exist at location ' + $LogPath
        $Message | Out-File -FilePath $ScriptLogPath -Append -Force
        #Quit out of script
        return
}


<# Each command should be executed in sequence and one at a time #>

# 1. Stores your oper credentials in a variable
$cred=Get-Credential -Message 'Please enter your -oper- account credentials'

# 2. Removes any existing sessions
Get-PSSession | Remove-PSSession

# 3. Opens a session to all four servers above
$sess=New-PSSession -ComputerName UKVMSAPP036, UKVMSAPP062, UKVMSAPP068, UKVMSAPP069 -Credential $cred

# 4. Creates a script blocl of commands to be executed on each server
$sb = {
    Set-Location -Path C:\Scripts\
    .\-svc-EfilingWFSDigitaDMSLogArchive.ps1
    $Search = (Get-Date -Format dd-MM-yy).ToString() + '*'
    Get-Content -Path 'E:\TTGAppLogs\-svc-EfilingWFS Digita Document Management Service Log Archive\ps-log.txt' | Out-Host
}

# 5. Invokes the script block using the sessions we created
Invoke-Command -Session $sess -ScriptBlock $sb 

# 6. Kills all open sessions
Get-PSSession | Remove-PSSession