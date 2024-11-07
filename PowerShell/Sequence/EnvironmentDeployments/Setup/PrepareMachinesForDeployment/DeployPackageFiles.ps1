Function DeployPackageFiles {
    param(
        [System.Management.Automation.Runspaces.PSSession] $Session,
        [string] $LocalSource,
        [string] $RemoteDestination,
        [string] $PackageLogName,
        [switch] $RemoveOtherVersions,
        [switch] $FilesInRootFolderIfPowershellNot5,
        [switch] $Force
    )

    . "$PSScriptRoot\HelperScripts\Get-PackageFolderDetails.ps1"

    $errorActionPreference = 'Stop'
    $log = @()

    try {
        $sourceFiles = Get-ChildItem $LocalSource -Filter *.zip
        $sourceFilesAndFolders = $sourceFiles | ForEach-Object {
            $packageFolderDetails = Get-PackageFolderDetails $_.Name
            $packagePath = ("$($packageFolderDetails.Name)\$($packageFolderDetails.Version)").Trim('\')

            @{
                LocalZipPath = $_.FullName; 
                RemoteZipPath = "$RemoteDestination\$($_.Name)";
                RemoteDestination = $RemoteDestination;
                PackageFolderPath = $packagePath;
                PackageDestination = "$RemoteDestination\$packagePath";
                PackageName = $packageFolderDetails.Name;
                PackageVersion = $packageFolderDetails.Version
            }
        }

        if ($Force) {
            $requiredFilesAndFolders = $sourceFilesAndFolders
        } else {
            $log += "$PackageLogName - Checking if deployment is required"
            $remoteCheckScript = {
                param($destination, $sourceFilesAndFolders)

                $missingFiles = @()
                $existingFiles = @()

                foreach($sourceFileAndFolder in $sourceFilesAndFolders) {
                    if (!(Test-Path $sourceFileAndFolder.PackageDestination)) {
                        $missingFiles += $sourceFileAndFolder
                    } else {
                        $existingFiles += $sourceFileAndFolder
                    }
                }

                return @{ Missing = $missingFiles; Existing = $existingFiles }
            }

            if ($session -ne $null) {
                $remoteCheckResults = Invoke-Command -Session $Session -ScriptBlock $remoteCheckScript -ArgumentList $RemoteDestination, $sourceFilesAndFolders
            } else {
                $remoteCheckResults = & $remoteCheckScript $RemoteDestination $sourceFilesAndFolders
            }
            $log += ""
            $remoteCheckResults.Existing | ForEach-Object { $log += "$PackageLogName - $($_.PackageFolderPath) exists." }
            $remoteCheckResults.Missing | ForEach-Object { $log += "$PackageLogName - $($_.PackageFolderPath) missing." }

            $requiredFilesAndFolders = $remoteCheckResults.Missing
        }

        if (($requiredFilesAndFolders | Measure-Object).Count -eq 0) {
            $log += "$PackageLogName - **Deployment not required**"
            return @{ Success = $success; Log = $log; Exception = $exception; PackageUpdated = $false }
        }
        $log += "$PackageLogName - **Deployment required**"

        # Create base folder
        $baseFolderScriptBlock = {
            param ($destination)

            if (!(Test-Path $destination)) {
                New-Item -ItemType Directory -Path $destination | Out-Null
            }

            Get-ChildItem $destination -Filter *.zip | Remove-Item
        }

        if ($Session -ne $null) {
            Invoke-Command -Session $Session -ScriptBlock $baseFolderScriptBlock -ArgumentList $RemoteDestination
        } else {
            & $baseFolderScriptBlock $RemoteDestination
        }

        # Copy files
        $log += "$PackageLogName - Copying $(($requiredFilesAndFolders | Measure-Object).Count) file(s)"
        if ($Session -ne $null) {
            $requiredFilesAndFolders | ForEach-Object { Send-File -Path $_.LocalZipPath -Destination $_.RemoteDestination -Session $Session | Out-Null }
        } else {
            $requiredFilesAndFolders | ForEach-Object { Copy-Item -Path $_.LocalZipPath -Destination $_.RemoteDestination | Out-Null }
        }
        
        # Setup destination
        $log += "$PackageLogName - Extracting files"
        $extractScriptBlock = {
            param($removeOtherVersions, $requiredFilesAndFolders, $packageLogName, $filesInRootFolderIfPowershellNot5)

            $filesRequiredInRootFolder = ($FilesInRootFolderIfPowershellNot5 -and $PSVersionTable.PSVersion.Major -lt 5);

            $log = @()

            try {
                foreach ($requiredFileAndFolder in $requiredFilesAndFolders) {

                    $log += "$packageLogName - Extracting to destination '$($requiredFileAndFolder.PackageDestination)'"

                    if (Test-Path $requiredFileAndFolder.PackageDestination) {
                        $log += "$packageLogName - Destination exists, removing"
                        Remove-item $requiredFileAndFolder.PackageDestination -Recurse -Force
                    }

                    # The directory shouldn't exist - we checked earlier.
                    New-Item -ItemType Directory -Path $requiredFileAndFolder.PackageDestination | Out-Null

                    Add-Type -assembly "system.io.compression.filesystem"
                    [io.compression.zipfile]::ExtractToDirectory($requiredFileAndFolder.RemoteZipPath, $requiredFileAndFolder.PackageDestination) | Out-Null

                    Remove-Item $requiredFileAndFolder.RemoteZipPath | Out-Null

                    if ($requiredFileAndFolder.PackageVersion -ne '') {
                        $packageDestinationFolder = "$($requiredFileAndFolder.RemoteDestination)\$($requiredFileAndFolder.PackageName)"

                        if ($RemoveOtherVersions -or $filesRequiredInRootFolder) {

                            $otherVersions = Get-ChildItem $packageDestinationFolder -Directory
                            if ($otherVersions -ne $null) {
                                $log += "$packageLogName - Removing other versions..."
                                Get-ChildItem $packageDestinationFolder -Directory | `
                                    Where-Object { $_.Name -ne $requiredFileAndFolder.PackageVersion } | `
                                    ForEach-Object {
                                        if ($_.Name -match '[0-9\.]+') {
                                            $log += "$packageLogName - Removing '$($_.FullName)'"
                                        }
                                        Remove-Item $_.FullName -Recurse -Force
                                    }
                            }
                        }

                        # Remove files from the root folder, they shouldn't be there now.
                        Get-ChildItem $packageDestinationFolder -File | Remove-Item -Recurse -Force
                        if ($filesRequiredInRootFolder) {
                            Move-Item "$packageDestinationFolder\$($requiredFileAndFolder.PackageVersion)\**" $packageDestinationFolder
                        }
                    }
                }
            } catch {
                $exception = $_.Exception
            }
            return @{ Log = $log; Exception = $exception }
        }

        if ($Session -ne $null) {
            $extractResult = Invoke-Command -Session $Session -ScriptBlock $extractScriptBlock -ArgumentList $RemoveOtherVersions, $requiredFilesAndFolders, $PackageLogName, $FilesInRootFolderIfPowershellNot5
        } else {
            $extractResult = & $extractScriptBlock $RemoveOtherVersions $requiredFilesAndFolders $PackageLogName, $FilesInRootFolderIfPowershellNot5
        }

        $log += $extractResult.Log
        $exception = $extractResult.Exception

    } catch {
        $exception = $_.Exception
    }
    $log += ""
    return @{ Success = $success; Log = $log; Exception = $exception; PackageUpdated = $true }
}