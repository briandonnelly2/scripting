[CmdletBinding()]
Param(
    [Parameter()]
    [ValidateSet('dev','staging','production')]
    [String]$Environment = 'staging'
)

#Sets location to where this script is being run from
#Set-Location -Path $PSScriptRoot #Live
Set-Location -Path "C:\Users\briandonnelly2\OneDrive - KPMG\Scripts\ps-kpmg\Payroll Pro" #test

#test to see if the psd1 file exists where we expect it to
<# If($true -eq (Test-Path -Path "$PSScriptRoot\config\*.psd1")) {
    #If it does, import the psd1 file with the data paths
    Import-PowerShellDataFile -Path "$PSScriptRoot\config\*.psd1" # Live
} #>
If($true -eq (Test-Path -Path ".\config\*.psd1")) {
    #If it does, import the psd1 file with the data paths
    $Data = Import-PowerShellDataFile -Path ".\config\*.psd1" # test
}
Else {
    #Something went wrong, print a message in the event logs
}

#Constructs and stores path to the correct deployment location
$DeployDirectory = $Data.general.DeployDirectory + "$Environment\"

#Call the New-ApplicationDeployment function to create the necessary directories and extract the deployment files
$ReturnValueNAD = New-ApplicationDeployment -DeployDirectory $DeployDirectory

#return value 'failed'
If("failed" -eq $ReturnValueNAD) {
    #let the user know the extraction has failed and to check the event logs for further info
}
#Return value null or empty string
ElseIf(("" -eq $ReturnValueNAD) -or ($null -eq $ReturnValueNAD)) {
    #Nothing or null has been returned, which is not right.  Ask user to check the logs
}
#return value can only be the deployment number
Else {
    [string]$BackupDirectory = $DeployDirectory + "packages\backups\" + $ReturnValueNAD + "\"

    #Shpuld ask the user to press enter to begin the backup
    
    #next call the Backup-Files method to backup all required files
    Backup-Files -BackupDirectory $BackupDirectory
}

<# 
[CmdletBinding()]
Param(
    [Parameter(Mandatory)]
    [String]$DeployDirectory
)

#Constructs path to the required folder
$PackagesDirectory = $DeployDirectory + "packages\"

#Grabs any zip files in the packages directory (this is where we drop the vendor zip file)
$ZIPS = Get-ChildItem -Path $PackagesDirectory -Filter '*.zip'

#Means more than one ZIP exisits, ask the user to check the packages directory for other zip files
If(1 -lt $ZIPS.Count) {
    #Print a suitable message
}
#Means ghere are no ZIP files, ask the user to check the packages directory
ElseIf(0 -eq $ZIPS.Count) {
    #Print a suitable message
}
#Means we have a single zip file so can proceed
Else {
    #grab the name of the zip file without the extension
    $DeployNumber = ($ZIPS.Name).Replace('.zip', '')

    #Construct the full path for the location the extracted zip files will go
    $ExtractedPackagesDirectory = $PackagesDirectory + $Deploynumber + "\"
    $DeployedPackagesDirectory = $PackagesDirectory + 'deployed\' + $Deploynumber + "\"

    #Create a directory for the extracted files to go into, another to archive the zip when complete
    New-Item -Path $ExtractedPackagesDirectory -ItemType Directory -Force
    New-Item -Path $DeployedPackagesDirectory -ItemType Directory -Force

    #Checks to see if the extraction location is empty
    If($null -eq (Get-ChildItem -Path $ExtractedPackagesDirectory -Directory)) {
        Try {
            #tries to extract the files..
            Expand-Archive -Path $ZIPS.FullName -DestinationPath $ExtractedPackagesDirectory -Force

            #Checks to see if the extraction directory is empty
            If($null -eq (Get-ChildItem -Path $ExtractedPackagesDirectory -Directory)) {
                #tell the user something went wrong because the extraction directory is empty
            }
            #Else there is folders in the directory
            Else {
                #Copy the zip package into the deployed folder for archive purposes...
                Copy-Item -Path $ZIPS.FullName -Destination $DeployedPackagesDirectory -Force

                #...then remove the ZIP from the 'Packages' directory
                Remove-Item -Path $ZIPS.FullName -Force

                return $DeployNumber
            }
        }
        Catch {
            #return a failure message
            return "failed"
        }
    }
    #Else there is already an extraction directory for today's deployment
    Else {
        #Checks to see if the extraction directory is empty
        If($null -eq (Get-ChildItem -Path $ExtractedPackagesDirectory -Directory)) {
            #Directory is empty, try to extract the files
            Try {
                #tries to extract the files..
                Expand-Archive -Path $ZIPS.FullName -DestinationPath $ExtractedPackagesDirectory -Force

                #Checks to see if the extraction directory is empty
                If($null -eq (Get-ChildItem -Path $ExtractedPackagesDirectory -Directory)) {
                    #tell the user something went wrong because the extraction directory is empty so something must have went wrong with the extraction
                }
                #Else there is files in the directory
                Else {
                    #Copy the zip package into the deployed folder for archive purposes...
                    Copy-Item -Path $ZIPS.FullName -Destination $DeployedPackagesDirectory -Force

                    #...then remove the ZIP from the 'Packages' directory
                    Remove-Item -Path $ZIPS.FullName -Force

                    return $DeployNumber
                }
            }
            Catch {
                #return a failure message
                return "failed"
            }
        }
        #Else there is files in the directory
        Else {
            #Copy the zip package into the deployed folder for archive purposes...
            Copy-Item -Path $ZIPS.FullName -Destination $DeployedPackagesDirectory -Force

            #...then remove the ZIP from the 'Packages' directory
            Remove-Item -Path $ZIPS.FullName -Force

            return $DeployNumber
        }
    }
}

$Dir = 'E:\Shares\TPL Deployment Share\PayrollPro\staging\'

New-ApplicationDeployment -DeployDirectory $Dir


$Dir2 = 'E:\Shares\TPL Deployment Share\PayrollPro\staging\packages\2020.202.7\'
$Dir3 = "\\ukvmurds1001\C$\Program Files (x86)\Star\Payroll\"
$appdata = "\\ukbirdata02\PENSIONSBIR\Admin\Gen\Star\Star payroll server\Shared Data\"



#Store the locations of the folders from the applications files that were extracted and found....
$CopyFolders = Get-ChildItem -Path $Dir2

#Switch statement that checks if each source location exists, if they do, it copies the required files to those locations...
switch ($true) {
    ($CopyFolders.Name -contains 'ApplicationFilesPath') { 
        #Grabs the source location of the files
        $AppFiles = Get-ChildItem -Path (Join-Path -Path $Dir2 -ChildPath 'ApplicationFilesPath') -Recurse
    
        #Copies files across to the relevant location
        Copy-Item -Path $AppFiles -Destination $appdata -Verbose -Recurse -Force
    }
    ($CopyFolders.Name -contains 'ProgramDirectory') { 
        #Grabs the source location of the files
        $ProgFiles = Get-ChildItem -Path (Join-Path -Path $Dir2 -ChildPath 'ProgramDirectory') -Recurse
    
        #Copies files across to the relevant location
        Copy-Item -Path $ProgFiles -Destination $Dir3 -Verbose -Recurse -Force
    }
    ($CopyFolders.Name -contains 'Reports') { 
        #Grabs the source location of the files
        $RptFiles = Get-ChildItem -Path (Join-Path -Path $Dir2 -ChildPath 'Reports') -Recurse
    
        #Copies files across to the relevant location
        Copy-Item -Path $RptFiles -Destination $appdata\Reports -Verbose -Recurse -Force
    }
    ($CopyFolders.Name -contains 'Schemas') { 
        #Grabs the source location of the files
        $ScmFiles = Get-ChildItem -Path (Join-Path -Path $Dir2 -ChildPath 'Schemas') -Recurse
    
        #Copies files across to the relevant location
        Copy-Item -Path $ScmFiles -Destination $appdata\Schemas -Recurse -Force
    }
    Default { 
    
    }
}
#>