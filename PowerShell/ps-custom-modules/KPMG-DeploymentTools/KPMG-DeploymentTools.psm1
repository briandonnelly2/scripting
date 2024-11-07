Set-StrictMode -Version 1.0
$ErrorActionPreference = "Stop"

Function New-KPMGBackup {
<# 
    .SYNOPSIS
        Backs up a given list of file paths
    .DESCRIPTION
        This fucntion will backup an array of UNC paths to a standard
        backup location. Backup location is created .
        Files are copied then source and destination file lists are compared
        to validate successful backup.
    .PARAMETER BackupLocation
        A backup location that can be passed in to override the default
    .PARAMETER SourceFolders
        An array of UNC paths that must be passed in (mandatory parameter)
    .PARAMETER DeleteSource
        Switch that determines whether the source folder should be deleted
    .PARAMETER DeploymentNumber
        Deployment number in the range 1 - 9. Appended to the date variable below to 
        create deployment number for folder naming purposes
    .INPUTS
        [System.String]
        [System.switch]
        [int16]
    .OUTPUTS
        [System.Object]
    .NOTES
        Version:                1.0
        Author:                 Brian Donnelly
        Creation Date:          29 April 2019
        Modified Date:          N/A
        Review Date:            24 July 2019
        Future Enhancements:    1. Add in functionality to run this as a PowerShell job and notify when complete.
                                2. Allow for backups to be compressed into zip files for better storage organisation.

        Testing:                Tested for local backups successful. (29/04/2019) 
                                Testing across the network successful. (27/02/2020)
    .EXAMPLE
        Example 1:  An example where a custom backup location is passed passed in and source folders are being removed. This is the first deployment
                    as the passed-in deployment number is 1:

                    New-KPMGBackup -BackupLocation "C:\TTGBackup\CCH Suite" -SourceFolders "C:\PowerShell" -DeleteSource:$true -DeploymentNumber 1
    .EXAMPLE
        Example 2:  An example of default usage of the function with the source folder not being removed and default backup location being used. This is the second deployment
                    as the passed-in deployment number is 2: 
            
                    New-KPMGBackup -SourceFolders "C:\PowerShell" -DeploymentNumber 2
    .EXAMPLE
        Example 3: An example of using the function with pre defined variables:

                    $BackupRoot =   "C:\Users\briandonnelly2\Desktop\Working Folder\Test\TTGBackup"
                    $SourceFiles =  "C:\Users\briandonnelly2\OneDrive - KPMG\Scripts\powershell\ps-old",
                                    "C:\Users\briandonnelly2\Documents\Documentation\HMRC Login - Common Error Messages.docx",
                                    "C:\Users\briandonnelly2\Documents\Documentation\UKX Domain - Adding Users & Security Groups.docx"
                    $DeployNum = 1

                    New-KPMGBackup -BackupLocation $BackupRoot -SourceFolders $SourceFiles -DeploymentNumber $DeployNum -Verbose
    .EXAMPLE
        Example 4:  An example of using the function with pre defined variables and UNC paths:
                    (Account executing must have correct network level access to the UNC paths defined)

                    $BackupRoot =   "\\UKVMPAPP1094\TPLBackupShare\CCHSuite\Prod"
                    $SourceFiles =  "\\UKVMPAPP1094\TPLDeploymentShare\CCHSuite\UAT",
                                    "\\UKVMPAPP1094\TPLScriptsShare\SQL"
                    $DeployNum = 1

                    New-KPMGBackup -SourceFolders $SourceFiles -DeploymentNumber $DeployNum -Verbose
#>
    [CmdletBinding()]
    Param(
        [Parameter ( Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName )]
        [string]$BackupLocation = "\\UKVMPAPP1094\TPLBackupShare\unspecified",

        [Parameter ( Mandatory, Position = 1, ValueFromPipeline, ValueFromPipelineByPropertyName,
        HelpMessage = "An array of UNC paths to be backed up" )]
        [ValidateNotNullOrEmpty()]
        [string[]]$SourceFolders,

        [Parameter( Position = 2, ValueFromPipeline, ValueFromPipelineByPropertyName,
        HelpMessage = "If true, source folder contents are deleted" )]
        [switch]$DeleteSource,

        [Parameter( Mandatory, Position = 3, ValueFromPipeline, ValueFromPipelineByPropertyName,
        HelpMessage = "Deployment number in the range 1 - 9" )]
        [ValidateRange(1, 9)]
        [int16]$DeploymentNumber
    )

    Process {
        Try {
            Write-Verbose "Backup location is: $BackupLocation"
            Write-Verbose "Folders being backed up: $SourceFolders"

            $BackupFolder = "$(Get-Date -Format yy.MMdd).$DeploymentNumber"

            $BackupPath = "$BackupLocation\$BackupFolder"

            Write-Verbose "The backup path will be $BackupPath"

            New-Item -Path $BackupPath -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null

            If ( !( Test-Path $BackupPath -PathType Container ) ) {
                Throw "$BackupPath is not created, please check and try again."
            }
       
            foreach ( $SourceFolder IN $SourceFolders ) {
                Write-Verbose "Backing up $SourceFolder"

                Copy-Item -Path $SourceFolder -Destination $BackupPath -Recurse -Force

                $DestinationFolder = Join-Path -Path $BackupPath -ChildPath ($SourceFolder.Split('\') | Select-Object -Last 1)

                #Stores the contents of the source and destination directories to make a comparison
                $SrcComp = Get-ChildItem $SourceFolder -Recurse
                $DstComp = Get-ChildItem $DestinationFolder -Recurse

                Write-Verbose "Verifying backup was successful"
                If ( !( $null -eq (Compare-Object -ReferenceObject $SrcComp -DifferenceObject $DstComp -Property Name -PassThru) ) ) {
                    Write-Warning "There was a problem backing up $SourceFolder"
                    Write-Warning "Files not backed up: $(Compare-Object -ReferenceObject $SrcComp -DifferenceObject $DstComp -Property Name)"
                    $DeleteSource = $false
                } ElseIf ( $null -eq (Compare-Object -ReferenceObject $SrcComp -DifferenceObject $DstComp -Property Name -PassThru) ) {
                    Write-Verbose "$SourceFolder backed up successfully"

                    If ( $DeleteSource -eq $true ) { 
                        Remove-Item -Path $SourceFolder -Recurse -Force -ErrorAction Continue
                        If ( Test-Path $SourceFolder ) {
                            Write-Warning "$SourceFolder has not been deleted"
                        }
                    } Else { 
                        Write-Verbose "Source files have not been deleted" 
                    }
                }
            }
        } Catch {
            Write-Error "ERROR: $($_.Exception.message)"
        }
    }
}

Function Copy-KPMGFiles {
<#
    .SYNOPSIS
        This function will copy files from a 
    .DESCRIPTION
        
    .PARAMETER SourceFolder
        The location the files should be copied from.
    .PARAMETER DestinationFolder
        The location the files should be copied to.
    .PARAMETER DeploymentNumber
        Deployment number in the range 1 - 9. Appended to the date variable below to 
        create deployment number for folder naming purposes
    .INPUTS
        [System.String] 
        [int16]
    .OUTPUTS
        None
    .NOTES
        Version:                1.0
        Author:                 Brian Donnelly
        Creation Date:          29 April 2019
        Modified Date:          N/A
        Revfiew Date:           24 July 2019
        Future Enhancements:    1. Add in functionality to run this as a PowerShell job and notify when complete.
                                2. Rework as BITS transfers.

        Testing:                

    .EXAMPLE
        Example 1:  This command copies the files in the source directory to the destination directory. This is the first deployment
                    as the passed-in deployment number is 1

                    Copy-KPMGFiles -SourceFolder "C:\Deployments" -DestinationFolder "C:\LiveDeployments" -DeploymentNumber 1

    .EXAMPLE 
        Example 2:  An example of using the function with pre defined variables and UNC paths:
                    (Account executing must have correct network level access to the UNC paths defined)

                    $SourceDirectory = "\\UKVMPAPP1094\TPLDeploymentShare\CCHSuite\UAT"
                    $DestinationDirectory = "\\UKVMURDS1002\deploy$"

Copy-KPMGFiles -SourceFolder $SourceDirectory -DestinationFolder $DestinationDirectory -DeploymentNumber 1
#>
    [CmdletBinding()]
    Param(
        [Parameter ( Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName,
        HelpMessage = "Location files are to be copied from" )]
        [ValidateScript({
            If ( !( Test-Path -Path $_ -PathType Container ) ) {
                Throw "Source directory does not exist.  Please check this and re-run"
            } Else { $True }
        })]
        [string]$SourceFolder,

        [Parameter ( Mandatory, Position = 1, ValueFromPipeline, ValueFromPipelineByPropertyName,
        HelpMessage = "Location files are to be copied to" )]
        [ValidateScript({
            If ( !( Test-Path -Path $_ -PathType Container ) ) {
                Throw "Destination directory does not exist.  Please ensure this is created first."
            } Else { $True }
        })]
        [string]$DestinationFolder,

        [Parameter( Mandatory, Position = 3, ValueFromPipeline, ValueFromPipelineByPropertyName,
        HelpMessage = "Deployment number in the range 1 - 9" )]
        [ValidateRange(1, 9)]
        [int16]$DeploymentNumber
    )

    Process {
        Try {
            Write-Verbose "Source location is: $SourceFolder"
            Write-Verbose "Destination location is: $DestinationFolder"

            [string]$DeployFolderName = "$(Get-Date -Format yy.MMdd).$DeploymentNumber"

            [string]$DeployFolder = "$DestinationFolder\$DeployFolderName"

            Write-Verbose "The destination path will be $DeployFolder"

            New-Item -Path $DeployFolder -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null

            If ( !( Test-Path $DeployFolder -PathType Container ) ) {
                Throw "$DeployFolder has not created, please check and try again."
            }

            Write-Verbose "Copying contents of $SourceFolder to $DeployFolder"
            Copy-Item -Path $SourceFolder -Destination $DeployFolder -Recurse -Force

            Write-Verbose "All files in $SourceFolder were successfully transferred to $DeployFolder"

        } Catch {
            Write-Error "ERROR: $($_.Exception.message)"
        }
    }
}

Function Invoke-KPMGInstall {#Should be tested further
<#
    .SYNOPSIS
        This function will invoke the installation of a .exe or .msi packaged application. 
    .DESCRIPTION
        This function validate that the file is a msi or exe and also test it exists first.
        It will then run the file using optional arguments to try to install the application.
        The return code is passed back through the pipeline to the calling script.
    .PARAMETER ApplicationInstallerPath
        The path to the installer file.
    .PARAMETER Arguments
        Command line arguments to be supplied when invoking the installer.
    .INPUTS
        [System.String] 
    .OUTPUTS
        [System.Object]
    .NOTES
        Version:                1.0
        Author:                 Brian Donnelly
        Creation Date:          29 April 2019
        Modified Date:          N/A
        Revfiew Date:           29 July 2019
        Future Enhancements:    
    .EXAMPLE
        Install a .exe application and supplies some arguments:

            Invoke-KPMGInstall -ApplicationInstallerPath "C:\Deployments\exe-installer.exe" -Arguments "/s /log="C:\Logging\install.log
    .EXAMPLE
        Install a .msi application and supplies no arguments:

            Invoke-KPMGInstall -ApplicationInstallerPath "C:\Deployments\msi-installer.msi"
#>
    
    [CmdletBinding()]
    Param(
        [Parameter ( Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName,
        HelpMessage = "The path to the application installer file" )]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
            If ( !( ( $_ -Like "*.exe" ) -or ( $_ -Like "*.msi" ) ) ) {
                Throw "$($_) is not an exe or msi. Quitting."
            } ElseIf ( Test-Path $_ -PathType Leaf ) {
                Throw "$($_) does not exist."
            } Else { $true }
        })]
        [string]$ApplicationInstallerPath,

        [Parameter ( Position = 1, ValueFromPipeline, ValueFromPipelineByPropertyName,
        HelpMessage = "Any arguments to be used for invoking this" )]
        [string]$Arguments
    )

    Process {
        Try {
            Write-Verbose "Determining which type of installer has been passed in"

            If ( $ApplicationInstallerPath -Like "*.exe" ) {
                Write-Verbose "Installer is an executable (.exe).  Proceeding..."

                If ( $Arguments -eq "" ) {
                    Write-Verbose "Running without arguments: Start-Process -FilePath $ApplicationInstallerPath -NoNewWindow -Wait -Passthru"

                    $ReturnFromEXE = Start-Process -FilePath $ApplicationInstallerPath -NoNewWindow -Wait -Passthru
                } Else { 
                    Write-Verbose "Running with arguments: Start-Process -FilePath $ApplicationInstallerPath -ArgumentList $Arguments -NoNewWindow -Wait -Passthru"

                    $ReturnFromEXE = Start-Process -FilePath $ApplicationInstallerPath -ArgumentList $Arguments -NoNewWindow -Wait -Passthru
                }
                Write-Verbose "Returncode is $($ReturnFromEXE.ExitCode)"

                Return $ReturnFromEXE.ExitCode

            } ElseIf ( $ApplicationInstallerPath -Like "*.exe" ) {
                Write-Verbose "Installer is a Microsoft installer (.msi).  Proceeding..."

                Write-Verbose "Setting MSI argumnents..."

                $MSIArgs = "/i " + $ApplicationInstallerPath + " " + $Arguments

                If ( $Arguments -eq "" ) {
                    $MSIArgs = "/i " + $ApplicationInstallerPath

                    Write-Verbose "Running without arguments: $MSIArgs"
                } Else {
                    $MSIArgs = "/i " + $ApplicationInstallerPath + " " + $Arguments

                    Write-Verbose "Running with arguments: $MSIArgs"
                }

                Write-Verbose "Running Start-Process -FilePath msiexec.exe -ArgumentList $MSIArgs -NoNewWindow -Wait -Passthru"

                $ReturnFromEXE = Start-Process -FilePath msiexec.exe -ArgumentList $MSIArgs -NoNewWindow -Wait -Passthru

                Write-Verbose "Returncode is $($ReturnFromEXE.ExitCode)"

                Return $ReturnFromEXE.ExitCode

            } Else {
                Throw "Please check the type of file supplied to the script.  Installation aborted."
            }
        } Catch {
            Write-Error "ERROR: $($_.Exception.message)"
        }
    }
}

Function Restore-KPMGApplication { #This has not yet been coded...
<#
    .SYNOPSIS
        Used to restore 
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

Function Get-KPMGSysInformation {
<#
    .SYNOPSIS
        Function returns system information that may be needed during a deployment
    .DESCRIPTION
        The function will return a hashtable containing various information. This would
        stored in a variable then referenced in order to make decisions about what 
        installer to use for example. The script takes no parameters and 
        sends an array with the info back through the pipeline.
    .PARAMETER ServerNames
        An array of servers to be checked
    .INPUTS
        None
    .OUTPUTS
        [System.Object]
    .NOTES
        Version:                1.0
        Author:                 Brian Donnelly
        Creation Date:          29 April 2019
        Modified Date:          N/A
        Revfiew Date:           29 July 2019
        Future Enhancements:    
    .EXAMPLE
        Invokes the method and stores the results in a variable:

            $Result = Get-KPMGSysInformation
#>
    
    [CmdletBinding()]
    Param(
        [Parameter ( ValueFromPipeline, ValueFromPipelineByPropertyName,
        HelpMessage = "An array of servers to return information on" )]
        [string[]]$ServerNames
    )

    Process {
        Try {
            $SysInfoSB = {
                #Gets reliability index
                [System.Object]$Index = Get-WmiObject -Class Win32_ReliabilityStabilityMetrics | Select-Object @{N="TimeGenerated"; E={$_.ConvertToDatetime($_.TimeGenerated)}},SystemStabilityIndex | Select-Object -First 1
                #Gets hardware information
                [System.Object]$ComputerSystem = Get-WmiObject -Class Win32_ComputerSystem
                #Gets values for when the system was last booted and the operating system version
                [System.Object]$OperatingSystem = Get-WmiObject -Class Win32_OperatingSystem | Select-Object @{N="LastBootUpTime"; E={$_.ConvertToDatetime($_.LastBootUpTime)}},Version

                [System.Object]$Plupp = [ordered]@{ 
                    ComputerName = $($env:COMPUTERNAME)
                    Index =  $([math]::Round($Index.SystemStabilityIndex))
                    TimeGenerated = $($Index.TimeGenerated)
                    Make = $($ComputerSystem.Manufacturer)
                    Model = $($ComputerSystem.Model)
                    OSVersion = $($OperatingSystem.Version)
                    UpTimeInDays = $([math]::round(((Get-Date) - ($OperatingSystem.LastBootUpTime)).TotalDays))
                    OSDiskFreeSpaceInGB = $([Math]::Round($(((Get-Volume -DriveLetter C).SizeRemaining)/1GB),2))
                }

                New-Object PSObject -Property $Plupp
            }
            
            [System.Object[]]$SystemInformation

            Foreach ( $Server IN $ServerNames ) {
                Write-Verbose "Getting data from $Server"

                $SystemInformation += Invoke-Command -ComputerName $Server -ScriptBlock $SysInfoSB              
            }
            return $SystemInformation

        } Catch {
            Write-Error "ERROR: $($_.Exception.message)"
        }
    }
}

Function New-KPMGPSSessions {#Should be tested further
<#
    .DESCRIPTION
        Creates PSSessions to a given list of servers.
    .PARAMETER Credentials
        A PS Credentials object. (mandatory)
    .PARAMETER ServerNames
        An array of server names.
    .PARAMETER LogFilePath
        PowerShell sessions are passed for the function to query against (mandatory)
    .EXAMPLE
        
    .EXAMPLE

#>  

    [CmdletBinding()]
    param(
        [Parameter( Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName,
        HelpMessage = "Please enter operator level credentials." )]
        [pscredential]$Credentials,
        
        [Parameter( Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName,
        HelpMessage = "Please pass in an array of server names." )]
        [string[]]$ServerNames,

        [Parameter( Mandatory, ValueFromPipelineByPropertyName,
        HelpMessage = "Please pass in an array of server names." )]
        [string]$LogFIlePath
    )

    Process {
        Try {
            Write-KPMGLogInfo -LogFilePath $LogFilePath -Message "Set up PowerShell sessions to the specified servers" -ToConsole:$false
            [System.Object[]]$Sessions += New-PSSession -ComputerName $ServerNames -Credential $Credentials -Name $ServerNames
            foreach( $Server IN $ServerNames ) {
                If( !( $Server -in $Sessions.Name ) ) {
                    Throw "The information returned is not consistent.  Terminating all sessions to be safe."
                }
            }
            return $Sessions
        }
        Catch {
            Get-PSSession | Remove-PSSession
        }
    }
}

Function New-KPMGWebService {

}

Function Update-KPMGWebService {

}