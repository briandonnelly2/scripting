Function New-ApplicationDeployment {
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
}