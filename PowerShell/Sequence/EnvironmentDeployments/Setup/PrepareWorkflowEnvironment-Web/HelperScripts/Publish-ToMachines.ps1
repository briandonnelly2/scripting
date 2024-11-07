# Scripts used below.
$publishToMachineScript = "$PSScriptRoot\Publish-DscToMachine.ps1"
$expandPackageScript = "$PSScriptRoot\Expand-Octopackage.ps1"
$prepareDscScript = "$PSScriptRoot\Prepare-DscDeploy.ps1"
$sendFileScript = "$PSScriptRoot\Send-File.ps1"

# Dot-source the Invoke-Parallel function
. "$PSScriptRoot/Invoke-Parallel.ps1"

# Dot-source the Get-AccountCredential function
. "$PSScriptRoot/Get-AccountCredential.ps1"

# Setup credentials
$WinRmAdminCredential = Get-AccountCredential -UserName $WinRmAdminUserName -Pass $WinRmAdminPass -Credential $WinRmAdminCredential `
    -CredentialRequired -DialogMessage "Please provide credentials to perform this deployment as."

# Allow wildcards to be supported in package file names, to allow version numbers to be ignored
if (![string]::IsNullOrWhiteSpace($PackageFilePath)) {
    $packages = Get-ChildItem $PackageFilePath
    $packageCount = ($packages | Measure-Object).Count 
    if ($packageCount -eq 0) {
        throw "A valid package cannot be found."
    } elseif ($packageCount -ne 1) {
        throw "Multiple valid packages can be found for this package file."
    }

    $package = $packages[0]
    $PackageFilePath = $package.FullName
} else {
    $PackageFilePath = $null
}

# Setup parameters
$deploymentParams = @{
    credential = $WinRmAdminCredential
    skipCertificateTests = ($WinRmSkipCertificateTests -eq 'true')
    useSsl = ($WinRmProtocol -eq 'https')
}

$packageParams = @{
    PerformPackageExtraction = ($performPackageExtraction -eq $true -or $performPackageExtraction -eq 'true')
    WorkingDirectoryPath = $WorkingDirectoryPath
    PackageFilePath = $PackageFilePath
    ApplicationDirectoryPath = $ApplicationDirectoryPath
    Environment = $Environment
    SubstitutionVariables = $SubstitutionVariables
    SubstitutionTargetFiles = $SubstitutionTargetFiles
    XmlConfigurationTransforms = $XmlConfigurationTransforms
}

Write-Output ""
Write-Output "==================="
Write-Output "Deployment Params:"
Write-Output "==================="
$deploymentParams.GetEnumerator() | ForEach-Object { Write-Output "$($_.Key): $($_.Value)" }

Write-Output ""
Write-Output "================"
Write-Output "Package Params:"
Write-Output "================"
$packageParams.GetEnumerator() | ForEach-Object { Write-Output "$($_.Key): $($_.Value)" }

Write-Output ""
Write-Output "==========="
Write-Output "DSC Params:"
Write-Output "==========="
$dscParams.GetEnumerator() | ForEach-Object { Write-Output "$($_.Key): $($_.Value)" }

$parameters = @{
    expandPackageScript = $expandPackageScript
    dscScript = $dscScript
    prepareDscScript = $prepareDscScript
    sendFileScript = $sendFileScript

    deploymentParams = $deploymentParams
    packageParams = $packageParams
    dscParams = $dscParams
    dscSecureParams = $dscSecureParams
}

$machines = $MachineNames.Split(',') | ForEach-Object { $_.Trim() } | Where-Object { ![string]::IsNullOrWhiteSpace($_) }
if ([string]::IsNullOrWhiteSpace($ParallelDeploymentThrottle)) {
    $ParallelDeploymentThrottle = '5'
}
$maxThrottle = [System.Convert]::ToInt32($ParallelDeploymentThrottle)

Write-Output ""
Write-Output "------------"
Write-Output "$(($machines | Measure-Object).Count) machine(s) found, deploying with a throttle of $maxThrottle."
Write-Output "------------"
Write-Output ""
Write-Output "=========="
Write-Output "Host logs:"
Write-Output "=========="

$results = Invoke-Parallel `
    -ScriptFile $publishToMachineScript `
    -InputObject $machines `
    -Parameter $parameters `
    -Throttle $maxThrottle

$lastException = $null
foreach($result in $results) {
    Write-Output ""
    Write-Output "===================================="
    Write-Output "$($result.MachineName) logs:"
    Write-Output "===================================="
    foreach ($logLine in $result.Log) {
        Write-Output $logLine
    }

    if ($result.Exception -ne $null) {
        $lastException = $result.Exception
        Write-Output "[EXCEPTION]"
        Write-Output $result.Exception.Message
    }
}

Write-Output ""

if ($lastException -ne $null) {
    Write-Warning "An error has occurred on at least 1 machine. Check the logs above, throwing the last exception raised:"
    throw $lastException
}