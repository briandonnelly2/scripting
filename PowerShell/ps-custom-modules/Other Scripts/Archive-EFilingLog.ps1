<#
    .SYNOPSIS
        Script that archives a single file as a .zip
    .DESCRIPTION
        This script will archive the e-filing service log after it gets larger than 3 MB.
        Ths stops the service tipping over.
    .PARAMETER SourceDirectory
        Describes a parameter that can be passed in to the script
    .PARAMETER DestinationDirectory
        Describes a parameter that can be passed in to the script

    .NOTES
        Version:                1.1
        Author:                 Brian Donnelly
        Creation Date:          14 October 2018
        Modified Date:          29 July 2019
        Revfiew Date:           29 October 2019
        Future Enhancements:    
    .EXAMPLE
        .\BackupLogFiles.ps1 -SourceDirectory 'C:\Users\-svc-EfilingWFS_TST\AppData\Local\Digita\Document Management Service' `
            -DestinationDirectory 'E:\TTGAppLogs\DigitaEFilingLogArchive' `

    .EXAMPLE
        Another example of how to use this cmdlet
#>

#requires -version 4.0
#requires -module KPMG-Logging

[CmdletBinding()]
Param(
    [Parameter( Mandatory, Position = 0,
        HelpMessage = "Provide a valid source directory" )]
    [ValidateScript({
        If ( !( Test-Path -Path $_ -PathType Container ) ) {
            Throw "The supplied path does not exist! Please check and try again!."
        } Else { $True }
        })]
    [string]$SourceDirectory,

    [Parameter( Mandatory, Position = 1,
        HelpMessage = "Please supply a valid destination directory" )]
    [ValidateScript({
        If ( !( Test-Path -Path $_ -PathType Container ) ) {
            Throw "The supplied path does not exist! Please check and try again!."
        } Else { $True }
    })]
    [string]$DestinationDirectory,

    [Parameter( Mandatory, Position = 2,
        HelpMessage = "Please specify the filename to be archived" )]
    [ValidateNotNullOrEmpty()]
    [string]$FileName,

    [Parameter( Position = 3,
        HelpMessage = "Output to console." )]
    [bool]$ToConsole
)

#region Global Variables
$ErrorActionPreference = 'Continue'

[System.Guid]$UniqueJobGUID = ([guid]::NewGuid())
[string]$TimeStamp = Get-Date -Format yy-MM-dd_hh-mm-ss
[string]$CallingScriptName = (($MyInvocation.MyCommand.Name).ToLower()).Replace('.','_')
[string]$StdErrorMsg = "An error weas encountered.  Please check the logfile at $LogFilePath for ore details."

#Builds a uniform logging path for all scripts
Import-Module -Name KPMG-Logging
[string]$LogFileDir = $PSScriptRoot + '\Logs\' + $CallingScriptName
[string]$LogFilePath = $null

#Builds source file path and path to archive file
[string]$SourceFile = $SourceDirectory + '\' + $FileName
[string]$ArchiveFile = $DestinationDirectory + '\' + ($FileName).Replace('.log', '.zip')

#endregion Global Variables

Process{

    Try{
        #region Configure Logging

        #Attempts to create the log directory and log file. Suppresses any errors. 
        New-Item -Path $LogFileDir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
        $LogFilePath = New-KPMGLog -LogFileDir $LogFileDir -LogFileName "$TimeStamp" -JobGUID $UniqueJobGUID -ErrorAction SilentlyContinue | Out-Null
        
        #If the logfile does not exist at this point, something has went wrong
        If( !( Test-Path -Path $LogFilePath ) ) { Throw 'Logfile does not exist. Logging was not configured correctly.  Quitting execution.' }

        #endregion Configure Logging

        Write-KPMGLogInfo -LogFilePath $LogFilePath -Message "Source path: [$SourceDirectory]" -ToConsole:$ToConsole
        Write-KPMGLogInfo -LogFilePath $LogFilePath -Message "Destination path: [$DestinationDirectory]" -ToConsole:$ToConsole

        # Get information about the file to be archived
        Write-KPMGLogInfo -LogFilePath $LogFilePath -Message "Getting information on source file" -ToConsole:$ToConsole
        [System.Object]$FileInfo = Get-ChildItem -Path $SourceFile | Select-Object name, @{name="FileSize";Expression={($_.Length)/1MB }}

        $FileSize = [math]::Round($File.FileSize, 2)

        #If source file is greater than 3MB, it will be archived and removed
        If( $FileSize -ge 3 ) {
            Write-KPMGLogInfo -LogFilePath $LogFilePath -Message "Archiving $($FileInfo.Name) as it exceeds 3MB at $($FileInfo.Size)MB" -ToConsole:$ToConsole

            Compress-Archive -LiteralPath $SourceFile -CompressionLevel Optimal -DestinationPath $ArchiveFile -Force -ErrorAction SilentlyContinue

            If( !( Test-Path -Path $ArchiveFile ) ) {
                Throw 'Error creating archive.  Please check logs and try again'
            }
        }

        #If source file is less than 3MB it will be left as is


    } Catch{
        IF( !( $null = $LogFilePath ) ) {
            Write-KPMGLogError -LogFilePath $LogFilePath -Message $($_.Exception.message) -ExitGracefully:$true -ToConsole:$ToConsole
            Write-Error $StdErrorMsg
        }
        Else{
            Write-Error "ERROR: $($_.Exception.message)"
        }
    }
}