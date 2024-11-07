::-----------------------------------------------------------------------------
::
:: AlteryxServer Backup Script v.2.0.2 - 01/04/19
:: Created By: Kevin Powney
::
:: Service start and stop checks adapted from example code by Eric Falsken
::
::-----------------------------------------------------------------------------

@echo off

::-----------------------------------------------------------------------------
:: Set variables for Log, Temp, Network, and Application Paths
::
:: Please update these values as appropriate for your environment. Note
:: that spaces should be avoided in the LogDir, TempDir, and NetworkDir paths.
:: The trailing slash is also required for these paths.
::-----------------------------------------------------------------------------

SET LogDir=C:\ProgramData\Alteryx\BackupLog\
SET TempDir=C:\Temp\
SET NetworkDir="G:\Backups\Alteryx\Database\"
SET AlteryxService="C:\Program Files\Alteryx\bin\AlteryxService.exe"
SET ZipUtil="C:\Program Files\7-Zip\7z.exe"
%25TempDir%25ServerBackup_%25datetime%25.7z %25TempDir%25ServerBackup_%25datetime%25 >> %25LogDir%25BackupLog%25datetime%25.log

powershell Compress-Archive -LiteralPath 'C:\mypath\testfile.txt' -DestinationPath "C:\mypath\Test.zip"

:: Set the maximium time to wait for the service to start or stop in whole seconds. Default value is 2 hours.
SET MaxServiceWait=7200

::-----------------------------------------------------------------------------
:: Set Date/Time to a usable format and create log
::-----------------------------------------------------------------------------

FOR /f %25%25a IN ('WMIC OS GET LocalDateTime ^| FIND "."') DO SET DTS=%25%25a
SET DateTime=%25DTS:~0,4%25%25DTS:~4,2%25%25DTS:~6,2%25_%25DTS:~8,2%25%25DTS:~10,2%25%25DTS:~12,2%25
SET /a tztemp=%25DTS:~21%25/60
SET tzone=UTC%25tztemp%25

echo %25date%25 %25time%25 %25tzone%25: Starting backup process... > %25LogDir%25BackupLog%25datetime%25.log
echo. >> %25LogDir%25BackupLog%25datetime%25.log

::-----------------------------------------------------------------------------
:: Stop Alteryx Service
::-----------------------------------------------------------------------------

echo %25date%25 %25time%25 %25tzone%25: Stopping Alteryx Service... >> %25LogDir%25BackupLog%25datetime%25.log
echo. >> %25LogDir%25BackupLog%25datetime%25.log

SET COUNT=0

:StopInitState
SC query AlteryxService | FIND "STATE" | FIND "RUNNING" >> %25LogDir%25BackupLog%25datetime%25.log
IF errorlevel 0 IF NOT errorlevel 1 GOTO StopService
SC query AlteryxService | FIND "STATE" | FIND "STOPPED" >> %25LogDir%25BackupLog%25datetime%25.log
IF errorlevel 0 IF NOT errorlevel 1 GOTO StopedService
SC query AlteryxService | FIND "STATE" | FIND "PAUSED" >> %25LogDir%25BackupLog%25datetime%25.log
IF errorlevel 0 IF NOT errorlevel 1 GOTO SystemError
echo %25date%25 %25time%25 %25tzone%25: Service State is changing, waiting for service to resolve its state before making changes >> %25LogDir%25BackupLog%25datetime%25.log
SC query AlteryxService | Find "STATE"
timeout /t 1 /nobreak >NUL
SET /A COUNT=%25COUNT%25+1
IF "%25COUNT%25" == "%25MaxServiceWait%25" GOTO SystemError 
GOTO StopInitState

:StopService
SET COUNT=0
SC stop AlteryxService >> %25LogDir%25BackupLog%25datetime%25.log
GOTO StoppingService

:StopServiceDelay
echo %25date%25 %25time%25 %25tzone%25: Waiting for AlteryService to stop >> %25LogDir%25BackupLog%25datetime%25.log
timeout /t 1 /nobreak >NUL
SET /A COUNT=%25COUNT%25+1
IF "%25COUNT%25" == "%25MaxServiceWait%25" GOTO SystemError 

:StoppingService
SC query AlteryxService | FIND "STATE" | FIND "STOPPED" >> %25LogDir%25BackupLog%25datetime%25.log
IF errorlevel 1 GOTO StopServiceDelay

:StopedService
echo %25date%25 %25time%25 %25tzone%25: AlteryService is stopped >> %25LogDir%25BackupLog%25datetime%25.log

::-----------------------------------------------------------------------------
:: Backup MongoDB to local temp directory. 
::-----------------------------------------------------------------------------

echo. >> %25LogDir%25BackupLog%25datetime%25.log
echo %25date%25 %25time%25 %25tzone%25: Starting MongoDB Backup... >> %25LogDir%25BackupLog%25datetime%25.log
echo. >> %25LogDir%25BackupLog%25datetime%25.log

%25AlteryxService%25 emongodump=%25TempDir%25ServerBackup_%25datetime%25\Mongo >> %25LogDir%25BackupLog%25datetime%25.log

::-----------------------------------------------------------------------------
:: Backup Config files to local temp directory. 
::-----------------------------------------------------------------------------

echo. >> %25LogDir%25BackupLog%25datetime%25.log
echo %25date%25 %25time%25 %25tzone%25: Backing up settings, connections, and aliases... >> %25LogDir%25BackupLog%25datetime%25.log
echo. >> %25LogDir%25BackupLog%25datetime%25.log

copy %25ProgramData%25\Alteryx\RuntimeSettings.xml %25TempDir%25ServerBackup_%25datetime%25\RuntimeSettings.xml >> %25LogDir%25BackupLog%25datetime%25.log
copy %25ProgramData%25\Alteryx\Engine\SystemAlias.xml %25TempDir%25ServerBackup_%25datetime%25\SystemAlias.xml
copy %25ProgramData%25\Alteryx\Engine\SystemConnections.xml %25TempDir%25ServerBackup_%25datetime%25\SystemConnections.xml
%25AlteryxService%25 getserversecret > %25TempDir%25ServerBackup_%25datetime%25\ControllerToken.txt

::-----------------------------------------------------------------------------
:: Restart Alteryx Service
::-----------------------------------------------------------------------------

echo. >> %25LogDir%25BackupLog%25datetime%25.log
echo %25date%25 %25time%25 %25tzone%25: Restarting Alteryx Service... >> %25LogDir%25BackupLog%25datetime%25.log
echo. >> %25LogDir%25BackupLog%25datetime%25.log

SET COUNT=0

:StartInitState
SC query AlteryxService | FIND "STATE" | FIND "STOPPED" >> %25LogDir%25BackupLog%25datetime%25.log
IF errorlevel 0 IF NOT errorlevel 1 GOTO StartService
SC query AlteryxService | FIND "STATE" | FIND "RUNNING" >> %25LogDir%25BackupLog%25datetime%25.log
IF errorlevel 0 IF NOT errorlevel 1 GOTO StartedService
SC query AlteryxService | FIND "STATE" | FIND "PAUSED" >> %25LogDir%25BackupLog%25datetime%25.log
IF errorlevel 0 IF NOT errorlevel 1 GOTO SystemError
echo %25date%25 %25time%25 %25tzone%25: Service State is changing, waiting for service to resolve its state before making changes >> %25LogDir%25BackupLog%25datetime%25.log
SC query AlteryxService | Find "STATE"
timeout /t 1 /nobreak >NUL
SET /A COUNT=%25COUNT%25+1
IF "%25COUNT%25" == "%25MaxServiceWait%25" GOTO SystemError 
GOTO StartInitState

:StartService
SET COUNT=0
SC start AlteryxService >> %25LogDir%25BackupLog%25datetime%25.log
GOTO StartingService

:StartServiceDelay
echo %25date%25 %25time%25 %25tzone%25: Waiting for AlteryxService to start >> %25LogDir%25BackupLog%25datetime%25.log
timeout /t 1 /nobreak >NUL
SET /A COUNT=%25COUNT%25+1
IF "%25COUNT%25" == "%25MaxServiceWait%25" GOTO SystemError 

:StartingService
SC query AlteryxService | FIND "STATE" | FIND "RUNNING" >> %25LogDir%25BackupLog%25datetime%25.log
IF errorlevel 1 GOTO StartServiceDelay

:StartedService
echo %25date%25 %25time%25 %25tzone%25: AlteryxService is started >> %25LogDir%25BackupLog%25datetime%25.log

::-----------------------------------------------------------------------------
:: This section compresses the backup to a single zip archive
::
:: Please note the command below requires 7-Zip to be installed on the server.
:: You can download 7-Zip from http://www.7-zip.org/ or change the command to
:: use the zip utility of your choice as defined in the variable above.
::-----------------------------------------------------------------------------

echo. >> %25LogDir%25BackupLog%25datetime%25.log
echo %25date%25 %25time%25 %25tzone%25: Archiving backup... >> %25LogDir%25BackupLog%25datetime%25.log

%25ZipUtil%25 a %25TempDir%25ServerBackup_%25datetime%25.7z %25TempDir%25ServerBackup_%25datetime%25 >> %25LogDir%25BackupLog%25datetime%25.log
powershell Compress-Archive -LiteralPath 'C:\mypath\testfile.txt' -DestinationPath "C:\mypath\Test.zip"

::-----------------------------------------------------------------------------
:: Move zip archive to network storage location and cleanup local files
::-----------------------------------------------------------------------------

echo. >> %25LogDir%25BackupLog%25datetime%25.log
echo %25date%25 %25time%25 %25tzone%25: Moving archive to network storage >> %25LogDir%25BackupLog%25datetime%25.log
echo. >> %25LogDir%25BackupLog%25datetime%25.log

copy %25TempDir%25ServerBackup_%25datetime%25.7z %25NetworkDir%25ServerBackup_%25datetime%25.7z >> %25LogDir%25BackupLog%25datetime%25.log

del %25TempDir%25ServerBackup_%25datetime%25.7z >> %25LogDir%25BackupLog%25datetime%25.log
rmdir /S /Q %25TempDir%25ServerBackup_%25datetime%25 >> %25LogDir%25BackupLog%25datetime%25.log

::-----------------------------------------------------------------------------
:: Done
::-----------------------------------------------------------------------------

echo. >> %25LogDir%25BackupLog%25datetime%25.log
echo %25date%25 %25time%25 %25tzone%25: Backup process completed >> %25LogDir%25BackupLog%25datetime%25.log
GOTO :EOF

:SystemError
echo. >> %25LogDir%25BackupLog%25datetime%25.log
echo %25date%25 %25time%25 %25tzone%25: Error starting or stopping service. Service is not accessible, is offline, or did not respond to the start or stop request within the designated time frame. >> %25LogDir%25BackupLog%25datetime%25.log