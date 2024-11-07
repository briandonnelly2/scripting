function Expand-OctoPackage {
    <#
    .SYNOPSIS
    Expands an OctoPacked package and applies required configuration settings.

    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [System.Management.Automation.Runspaces.PSSession] $Session,
        [Parameter(Mandatory=$true)]
        [string] $PackageFilePath,
        [Parameter(Mandatory=$true)]
        [string] $PackageName,
        [Parameter(Mandatory=$true)]
        [string] $PackageVersion,
        [string] $Environment,
        [string] $ApplicationDirectoryPath,
        [string] $SubstitutionVariables,
        [string] $SubstitutionTargetFiles,
        [string] $XmlConfigurationTransforms
    )

    if ([string]::IsNullOrWhiteSpace($Environment)) {
        $Environment = $null
    }

    if ([string]::IsNullOrWhiteSpace($ApplicationDirectoryPath)) {
        $ApplicationDirectoryPath = "C:\Applications"
    }

    $remoteCalamariLocation = "C:\Deployments\Tools\Calamari"

    $ApplicationDirectoryPath = $ApplicationDirectoryPath.TrimEnd('\')

    $errorActionPreference = 'Stop'
    $log = @()

    try {
        $package = Get-Item $PackageFilePath
        $packageFileName = $package.Name

        # Work out where Calamari should extract the package to.

        # Note: By default, Calamari extracts to '{Target}\{Environment}\{Id}\{Version}'
        # If environment is empty, extract is to '{Target}\{Id}\{Version}'
        $packageIdPath = ("$Environment\$PackageName").Trim('\')
        $packageIdTargetPath = "$ApplicationDirectoryPath\$packageIdPath"

        $log += "Starting package extraction"

        # Setup Octopus Variables
        $octoStandardVariables = @{
            "Octopus.Action.EnabledFeatures" = "Octopus.Features.SubstituteInFiles,Octopus.Features.ConfigurationVariables,Octopus.Features.ConfigurationTransforms";
            "Octopus.Action.Package.AutomaticallyUpdateAppSettingsAndConnectionStrings" = "True";
            "Octopus.Action.Package.DownloadOnTentacle" = "False";
            "Octopus.Tentacle.Agent.ApplicationDirectoryPath" = $ApplicationDirectoryPath;
            "Octopus.Environment.Name" = $Environment
        }

        if (![string]::IsNullOrWhiteSpace($SubstitutionTargetFiles)) {
            $octoStandardVariables["Octopus.Action.SubstituteInFiles.Enabled"] = "True"
            $octoStandardVariables["Octopus.Action.SubstituteInFiles.TargetFiles"] = $SubstitutionTargetFiles
        }

        if (![string]::IsNullOrWhiteSpace($XmlConfigurationTransforms)) {
            $octoStandardVariables["Octopus.Action.Package.AutomaticallyRunConfigurationTransformationFiles"] = "False";
            $octoStandardVariables["Octopus.Action.Package.AdditionalXmlConfigurationTransforms"] = $XmlConfigurationTransforms;
        } else {
            $octoStandardVariables["Octopus.Action.Package.AutomaticallyRunConfigurationTransformationFiles"] = "True";
        }

        if (![string]::IsNullOrWhiteSpace($SubstitutionVariables)) {
            
            # Multiline match on substitution variables using select string
            $SubstitutionVariables | Select-String '(?m)^[ ]*"?(.*?)"?[ ]*:[ ]*"?(.*?)"?[ ,]*$' -AllMatches | ForEach-Object { $_.Matches} | `
                ForEach-Object { @{ Name=$_.Groups[1].Value; Value=$_.Groups[2].Value } } | `
                ForEach-Object { if ($octoStandardVariables[$_.Name] -eq $null) { $octoStandardVariables[$_.Name] = $_.Value } }
        }

        $standardVariablesJson = $octoStandardVariables | ConvertTo-Json -Depth 2
        $log += "Standard variables JSON:`n$standardVariablesJson"

        # Check for existence of Calamari & ensure environment variable is available
        $calamariExePath = Invoke-Command -Session $Session {
            $calamariLocation = $using:remoteCalamariLocation
            if (!(Test-Path $calamariLocation)) {
                return $null
            }

            # Setting the tentacle journal environment variable locally if not already set
            if ($env:TentacleJournal -eq $null) {
                Set-Item -Path Env:\TentacleJournal -Value $calamariLocation\CalamariJournal.xml
            }

            $calamariFile = Get-ChildItem $calamariLocation -Filter Calamari.exe -Recurse
            return $calamariFile.FullName
        }

        if ($calamariExePath -eq $null) {
            throw "Calamari has not been set up on this machine. Please run the PrepareMachinesForDeployment task prior to this task."
        }

        # Create the working directory
        $remoteWorkingDirectoryPath = Invoke-Command -Session $Session {
            $workingDirectory = New-Item -ItemType Directory -Path "$([System.IO.Path]::GetTempPath())\ExpandOctoPackage_$([System.Guid]::NewGuid())"

            return $workingDirectory.FullName
        }

        # Copy files to remote working folder
        $log += "Copying package to server"
        Send-File -Path $PackageFilePath -Destination $remoteWorkingDirectoryPath -Session $Session | Out-Null

        # Setup destination
        $log += "Extracting package to deployment location"
        $extractResult = Invoke-Command -Session $Session {
            $workingPath = $using:remoteWorkingDirectoryPath
            $packageFileName = $using:packageFileName
            $packageVersion = $using:PackageVersion
            $packageIdTargetPath = $using:packageIdTargetPath
            $calamariExePath = $using:calamariExePath
            $standardVariablesJson = $using:standardVariablesJson

            $packageFilePath = "$workingPath\$packageFileName"
            $standardVariablesFilePath = "$workingPath\$packageFileName.variables.json"

            $log = @()

            try {

                # Save variables JSON file
                $standardVariablesJson | Out-File -FilePath $standardVariablesFilePath -Encoding utf8
                
                # Do Calamari things
                $log += "Deploying using Calamari executable"
                & $calamariExePath "deploy-package" "--package" $packageFilePath "--variables" $standardVariablesFilePath | Out-Null
                $log += "Deployment complete"

                # TODO: Get the correct folder returned for IIS Configuration
                $extractedPackageFolder = Get-ChildItem $packageIdTargetPath -Filter "$packageVersion*" | `
                    Sort-Object -Property CreationTime -Descending | Select-Object -First 1
                if ($extractedPackageFolder -eq $null) {
                    throw "The extracted package path cannot be identified."
                }

            } catch {
                $exception = $_.Exception
            } finally {
                # Clean up
                Remove-Item $workingPath -Recurse -Force
            }

            return @{ Log = $log; Exception = $exception; ExtractedPackagePath = $extractedPackageFolder.FullName }
        }

        $extractedPackagePath = $extractResult.ExtractedPackagePath
        $log += $extractResult.Log
        $exception = $extractResult.Exception

    } catch {
        $exception = $_.Exception
    }

    return @{ Success = $success; Log = $log; Exception = $exception; ExtractedPackagePath = $extractedPackagePath; }
}