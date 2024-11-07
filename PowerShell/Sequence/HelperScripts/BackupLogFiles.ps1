<#
    .SYNOPSIS
        Script that archives a single file as a .zip
    .DESCRIPTION
        This script will archive the e-filing service log after it gets larger than 3 MB.
        Ths stops the service tipping over.
    .PARAMETER SourceFilePath
        Describes a parameter that can be passed in to the script
    .PARAMETER DestinationFilePath
        Describes a parameter that can be passed in to the script
    .PARAMETER FileSizeThreshold
        Describes a parameter that can be passed in to the script
    .NOTES
        Version:                1.1
        Author:                 Brian Donnelly
        Creation Date:          14 October 2018
        Modified Date:          29 July 2019
        Revfiew Date:           29 October 2019
        Future Enhancements:    
    .EXAMPLE
        .\BackupLogFiles.ps1 -SourceFilePath 'C:\Users\-svc-EfilingWFS_TST\AppData\Local\Digita\Document Management Service' `
            -DestinationFilePath 'E:\TTGAppLogs\DigitaEFilingLogArchive' `
            -FileSizeThreshold 3MB
    .EXAMPLE
        Another example of how to use this cmdlet
#>

#requires -version 4.0
#requires -module KPMG-Logging

#region Parameters

[CmdletBinding()]
Param(
    [string]$SourceFilePath,

    [string]$DestinationFilePath,

    [int32]$FileSizeThreshold,

    [bool]$ToConsole

)

#endregion Parameters

#region Global Variables
$ErrorActionPreference = 'Continue'

[System.Guid]$UniqueJobGUID = ([guid]::NewGuid())
[string]$TimeStamp = Get-Date -Format yy-MM-dd_hh-mm-ss
[string]$CallingScriptName = (($MyInvocation.MyCommand.Name).ToLower()).Replace('.','_')
[string]$StdErrorMsg = "An error weas encountered.  Please check the logfile at $LogFilePath for ore details."

#endregion Global Variables

#Builds a uniform logging path for all scripts
Import-Module -Name KPMG-Logging
[string]$LogFileDir = $PSScriptRoot + '\Logs\' + $CallingScriptName
[string]$LogFilePath = $null

Try {
    #region Configure Logging

    #If the Logging directory does not exist, create it
    If( !( Test-Path -Path $LogFileDir -PathType Container ) ) {
        Write-Verbose "Creating logging directory at [$LogFileDir]"
        New-Item -Path $LogFileDir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null

        #Test the logging directory has been created and create the logfile
        If( Test-Path -Path $LogFileDir -PathType Container ) {
            Write-Verbose "Logging directory created. Creating log file."
            $LogFilePath = New-KPMGLog -LogFileDir $LogFileDir -LogFileName "$TimeStamp" -JobGUID $UniqueJobGUID
        }
    }
    
    If( Test-Path -Path $LogFileDir -PathType Container ) {
        Write-Verbose "Logging directory already exists. Creating log file."
        $LogFilePath = New-KPMGLog -LogFileDir $LogFileDir -LogFileName "$TimeStamp" -JobGUID $UniqueJobGUID
    }

    #endregion Configure Logging

    #region main execution

    # 1. Check the source & destination paths exist If not create them or act accordingly

    # a. Test source path exists, throw error if not found
    Write-KPMGLogInfo -LogFilePath $LogFilePath -Message "Testing source path [$SourceFilePath] exists" -ToConsole:$ToConsole

    If( !( Test-Path -Path $SourceFilePath -PathType Container ) ) {
        Write-KPMGLogError -LogFilePath $LogFilePath -Message "The supplied $SourceFilePath does not exist" -ExitGracefully:$true -ToConsole:$ToConsole
        Throw $StdErrorMsg
    }

    # b. Test destination path exists, create if not found
    Write-KPMGLogInfo -LogFilePath $LogFilePath -Message "Testing destination path [$DestinationFilePath] exists" -ToConsole:$ToConsole

    If( !( Test-Path -Path $DestinationFilePath -PathType Container ) ) {
        Write-KPMGLogInfo -LogFilePath $LogFilePath -Message "Creating destination path at [$DestinationFilePath] exists" -ToConsole:$ToConsole
        New-Item -Path $DestinationFilePath -ItemType Directory -Force | Out-Null

        # I. Test creation of destination path, throw error if not found
        Write-KPMGLogInfo -LogFilePath $LogFilePath -Message "Testing destination path [$DestinationFilePath] exists"
        If( !( Test-Path -Path $DestinationFilePath -PathType Container ) ) {
            Write-KPMGLogError -LogFilePath $LogFilePath -Message "The $DestinationFilePath directory was not created.  Check the permissions of the account executing this script" -ExitGracefully:$true -ToConsole:$ToConsole
            Throw $StdErrorMsg
        }
    }

    Write-KPMGLogInfo -LogFilePath $LogFilePath -Message "Confirmed source path: [$SourceFilePath]" -ToConsole:$ToConsole
    Write-KPMGLogInfo -LogFilePath $LogFilePath -Message "Confirmed destination path: [$DestinationFilePath]" -ToConsole:$ToConsole

    # 2. Get information about the files in the source directory to be used in decision making

    # a. Grab information about the file(s) to be archived
    Write-KPMGLogInfo -LogFilePath $LogFilePath -Message "Getting information on source files" -ToConsole:$ToConsole
    [System.Object]$FileInfo = Get-ChildItem -Path $SourceFilePath | Select-Object name, @{name="FileSize";Expression={($_.Length)/1MB }}, LastWriteTime, Extension

    [System.Object[]]$SourceFiles = @()

    # b. Save the inforamation obtained as log file entries and store the same info in a variable
    Write-KPMGLogInfo -LogFilePath $LogFilePath -Message "Logging source file information" -ToConsole:$ToConsole

    foreach( $File IN $FileInfo ) {
        $CurrentFile = @{}
        $CurrentFile.Name = $File.name
        $currentFile.Size = [math]::Round($File.FileSize, 2)
        $CurrentFile.Extension = ($File.Extension).Trim('.')
        $CurrentFile.LastWriteTime = $File.LastWriteTime

        $SourceFiles += New-Object -TypeName psobject -Property $CurrentFile

        $CurrentLogEntry = "
                            Name: $($CurrentFile.Name)
                            Size: $($currentFile.Size)MB
                             Ext: $($currentFile.Extension)
                             LRT: $($currentFile.LastWriteTime)
                           "

        Write-KPMGLogInfo -LogFilePath $LogFilePath -Message $CurrentLogEntry -ToConsole:$ToConsole
    }

    # 3. Test whether the file is to be archived:

    foreach( $sourcefile IN $SourceFiles ) {

        switch ( $true ) {
            #Large Files
            ( $sourcefile.Size -gt $FileSizeThreshold ) {
                Write-KPMGLogInfo -LogFilePath $LogFilePath -Message "Archiving $($SourceFile.Name) as it exceeds $($FileSizeThreshold)MB at $($SourceFile.Size)MB" -ToConsole:$ToConsole
            }
            Default {}
        }
    }

    #4a. If File archivng not required

    #4b. If File arciving is required

    #endregion main execution
} Catch {
    Write-Error "ERROR: $($_.Exception.message)"
} Finally {
    #region Cleanup before exit

    Get-PSSession | Remove-PSSession
    Stop-KPMGLog -LogFilePath $LogFilePath -ToConsole:$ToConsole

    #endregion Cleanup before exit
}

<#

# 5. Tidy up and log any required actions

<# Testing...

$SourceFilePath = 'C:\Users\-oper-briandonnelly2\Desktop\Test\source'
$DestinationFilePath = 'C:\Users\-oper-briandonnelly2\Desktop\Test\destination'

$Files = .\BackupLogFiles.ps1 -SourceFilePath $SourceFilePath -DestinationFilePath $DestinationFilePath -ToConsole:$false -Verbose


$FileSizeThreshold = 3MB

#>