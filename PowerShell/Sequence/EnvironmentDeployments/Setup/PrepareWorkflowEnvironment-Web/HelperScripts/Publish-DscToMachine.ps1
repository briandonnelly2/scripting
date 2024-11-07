param($machineName, $parameter)

# This preference is important for the Try .. Catch
$errorActionPreference = 'Stop'

$machineName = $machineName.Trim()

$deploymentParams = $parameter.deploymentParams
$packageParams = $parameter.packageParams
$dscParams = $parameter.dscParams
$dscSecureParams = $parameter.dscSecureParams
$dscScript = $parameter.dscScript
$prepareDscScript = $parameter.prepareDscScript
$expandPackageScript = $parameter.expandPackageScript
$sendFileScript = $parameter.sendFileScript

if ($packageParams.ApplicationDirectoryPath -eq $null -or [string]::IsNullOrWhiteSpace($packageParams.ApplicationDirectoryPath)) {
    $packageParams.ApplicationDirectoryPath = "C:\Applications"
}

if ($packageParams.WorkingDirectoryPath -eq $null -or [string]::IsNullOrWhiteSpace($packageParams.WorkingDirectoryPath)) {
    $packageParams.WorkingDirectoryPath = "C:\Applications\_work"
}

# -------- Source Helper scripts
. $expandPackageScript
. $sendFileScript

$log = @()

try {

    # -------- Setup session option
    if ($deploymentParams.skipCertificateTests) {
        $sessionOption = New-PSSessionOption -SkipCACheck -SkipCNCheck
    } else {
        $sessionOption = New-PSSessionOption
    }

    # -------- Create the session 
    $session = New-PSSession -ComputerName $machineName -UseSSL:$deploymentParams.useSsl -SessionOption $sessionOption -Credential $deploymentParams.credential

    $deploymentDetails = @{ 
        RootWorkingPath = $packageParams.WorkingDirectoryPath;
        WorkingPath = $packageParams.WorkingDirectoryPath;
    }
    
    if (![string]::IsNullOrWhiteSpace($packageParams.PackageFilePath)) {

        # Get package details
        $metadataRegex = [regex]::Match($packageParams.PackageFilePath, '^(?<folder>(?:.*\\)?)(?<name>.*?)\.?(?<version>(?:[0-9]+\.?)+)?\.\w+$')
        $deploymentDetails.PackageName = $metadataRegex.Groups['name'].Value
        $deploymentDetails.PackageVersion = $metadataRegex.Groups['version'].Value

        if ([string]::IsNullOrWhiteSpace($deploymentDetails.PackageName) -or [string]::IsNullOrWhiteSpace($deploymentDetails.PackageVersion)) {
            throw "A valid package name or version cannot be identified from this package."
        }

        $deploymentDetails.WorkingPath = "$($deploymentDetails.RootWorkingPath)\$($deploymentDetails.PackageName)\$($deploymentDetails.PackageVersion)"

        # -------- Create the working directory for the package
        Invoke-Command -Session $session {
            param([string]$workingPath)
            if (!(Test-Path $workingPath)) {
                New-Item -ItemType Directory -Path $workingPath
            }
        } -ArgumentList $deploymentDetails.WorkingPath
        $log += "Package working path: $($deploymentDetails.WorkingPath)"

        if ($packageParams.PerformPackageExtraction) {
            # -------- Extract the package to the remote server
            Write-Host "$machineName | 20% | Extracting package"
            $expandResult = Expand-OctoPackage -Session $session `
                -PackageFilePath $packageParams.PackageFilePath `
                -Environment $packageParams.Environment `
                -PackageName $deploymentDetails.PackageName `
                -PackageVersion $deploymentDetails.PackageVersion `
                -ApplicationDirectoryPath $packageParams.ApplicationDirectoryPath `
                -SubstitutionVariables $packageParams.SubstitutionVariables `
                -SubstitutionTargetFiles $packageParams.SubstitutionTargetFiles `
                -XmlConfigurationTransforms $packageParams.XmlConfigurationTransforms

            $log += ""
            $log += "----------------------"
            $log += "Package Extraction Log"
            $log += "----------------------"
            $log += $expandResult.Log
            # Got the log, throw the exception
            if ($expandResult.Exception -ne $null) {
                throw $expandResult.Exception
            }
            Write-Host "$machineName | 40% | Package extracted"

            # Parameters made available to DSC Config scripts
            $deploymentDetails.DeploymentPath = $expandResult.ExtractedPackagePath

            $log += "Package extracted to $($expandResult.ExtractedPackagePath)"
        }

    }

    # -------- Invoke the DSC script

    # Setup the DSC scripts into a script block for remote execution
    $script = Get-Item $dscScript

    Write-Host "$machineName | 60% | Preparing $($script.BaseName) Desired State Configuration"
    $dscOutput = Invoke-Command -Session $session -FilePath $prepareDscScript
    Write-Host "$machineName | 80% | Performing $($script.BaseName) Desired State Configuration"
    $dscOutput = Invoke-Command -Session $session -FilePath $dscScript -ArgumentList $deploymentDetails, $dscParams, $dscSecureParams
    Write-Host "$machineName | 100% | $($script.BaseName) Desired State Configuration complete"

    $log += ""
    $log += "-------"
    $log += "DSC Log"
    $log += "-------"
    $log += $dscOutput.Log
    # Got the log, throw the exception
    if ($dscOutput.Exception -ne $null) {
        throw $dscOutput.Exception
    }
}
catch 
{
    $exception = $_.Exception
    Write-Host "$machineName | [EXCEPTION] $($_.Exception.Message)."
}
finally
{
    if ($session) {
        Remove-PSSession $session
    }
}

return @{
    MachineName = $machineName;
    Exception = $exception;
    Log = $log
}