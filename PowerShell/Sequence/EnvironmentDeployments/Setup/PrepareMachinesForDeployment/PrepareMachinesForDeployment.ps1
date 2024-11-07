<#

.SYNOPSIS
Prepares machines to allow them to successfully deploy applications and apply Desired State Configurations.

.PARAMETER MachineNames
Comma separated machine names to prepare.

.PARAMETER WinRmAdminUserName
The username for admin credentials used to perform the work. Used for compatibility with VSTS release management; please provide an WinRmAdminCredential object otherwise.

.PARAMETER WinRmAdminPass
The password for admin credentials used to perform the work. Used for compatibility with VSTS release management; please provide an WinRmAdminCredential object otherwise.

.PARAMETER WinRmAdminCredential
An admin credential to use to perform the work. If not provided, a credential will be requested. Please note: the credential must work on local and remote machines.

.PARAMETER WinRmProtocol
The protocol to use for WinRM, either of http or https.

.PARAMETER WinRmSkipCertificateTests
If set as 'true' certificate tests will be skipped on WinRM communications, such as checking the certificate authority and common name.

.PARAMETER PrepareCalamari
Prepare Octopus Calamari application on machines.

.PARAMETER PrepareCommonDsc
Prepare common DSC modules on machines.

#>

[CmdletBinding()]
param (
    # WinRM Parameters - Required
    [Parameter(Mandatory=$true)]
    [string]$MachineNames,
    [string]$WinRmAdminUserName,
    [string]$WinRmAdminPass,
    [pscredential]$WinRmAdminCredential,
    [Parameter(Mandatory=$true)]
    [ValidateSet("http","https")]
    [string]$WinRmProtocol,
    [Parameter(Mandatory=$true)]
    [ValidateSet("true","false")]
    [string]$WinRmSkipCertificateTests,
    [ValidateSet("1","2","3","4","5")]
    [string]$ParallelDeploymentThrottle = 5,
    # Task Specific Parameters
    [Parameter(Mandatory=$true)]
    [ValidateSet("true","false")]
    [string]$PrepareCalamari,
    [Parameter(Mandatory=$true)]
    [ValidateSet("true","false")]
    [string]$PrepareCommonDsc
)

$errorActionPreference = 'Stop'

Write-Verbose "Entering script PrepareMachinesForDeployment.ps1"

#----------------------------------------------------------
# OFFLINE TASK START
#----------------------------------------------------------

# Setting a script for offline use and exiting this script if offline deployments are enabled
. "$PSScriptRoot/HelperScripts/OfflineDeploymentFunctions.ps1"
if ((Set-OfflineDeploymentTaskScript -TaskName "PrepareMachinesForDeployment" `
    -ParameterReplacements @{ WinRmAdminUserName = $null; WinRmAdminPass = $null; WinRmAdminCredential = '$WinRmAdminCredential' } `
    -RequiredParameterReplacements @('WinRmAdminCredential') `
    -ReturnOfflineDeploymentEnabled) -eq $true) {
        Write-Host "** This task has generated a script to run offline. Use an 'Offline Deployment' task to use this script **"
        return
}

#----------------------------------------------------------
# OFFLINE TASK END
#----------------------------------------------------------

Write-Verbose "MachineNames = $MachineNames" 
Write-Verbose "WinRmAdminUserName = $WinRmAdminUserName" 
Write-Verbose "WinRmProtocol = $WinRmProtocol" 
Write-Verbose "WinRmSkipCertificateTests = $WinRmSkipCertificateTests" 
Write-Verbose "PrepareCalamari = $PrepareCalamari"
Write-Verbose "PrepareCommonDsc = $PrepareCommonDsc"

Write-Output "Preparing machines for deployment."

# Dot-source the Get-AccountCredential script
. "$PSScriptRoot/HelperScripts/Get-AccountCredential.ps1"

$WinRmAdminCredential = Get-AccountCredential -UserName $WinRmAdminUserName -Pass $WinRmAdminPass -Credential $WinRmAdminCredential `
    -CredentialRequired -DialogMessage "Please provide credentials to perform this preparation as.";

$parameters = @{
    scriptRoot = $PSScriptRoot
    credential = $WinRmAdminCredential;
    skipCertificateTests = ($WinRmSkipCertificateTests -eq 'true');
    prepareCalamari = ($PrepareCalamari -eq 'true');
    prepareCommonDsc = ($PrepareCommonDsc -eq 'true');
    installDscCertificate = ($PrepareCommonDsc -eq 'true');
    useSsl = ($WinRmProtocol -eq 'https');
}

. "$PSScriptRoot/HelperScripts/Invoke-Parallel.ps1"

$machines = $MachineNames.Split(',') | ForEach-Object { $_.Trim() }
$maxThrottle = [System.Convert]::ToInt32($ParallelDeploymentThrottle)

Write-Output "$(($machines | Measure-Object).Count) machine(s) found, deploying with a throttle of $maxThrottle."

$preparationScript = "$PSScriptRoot\PrepareMachinesForDeployment-SingleMachine.ps1"

# Prepare DSC modules on agent - for some reason required for Invoke-Command to work.
$results = & $preparationScript -machineName localhost -parameter @{
    scriptRoot = $PSScriptRoot;
    prepareCommonDsc = ($PrepareCommonDsc -eq "true");
    skipCertificateTests = ($WinRmSkipCertificateTests -eq "true");
    installDscCertificate = $false;
    credential = $WinRmAdminCredential;
}

Write-Output ""
Write-Output "=========================="
Write-Output "Local Setup - Output Logs:"
Write-Output "=========================="
$error = $false

foreach($result in $results) {
    Write-Output ""
    Write-Output "------------"
    Write-Output $result.MachineName
    Write-Output "------------"
    foreach ($logLine in $result.Log) {
        Write-Output $logLine
    }

    if ($result.Exception -ne $null) {
        $error = $true
        Write-Output "[EXCEPTION]"
        # TODO: Look at formatting in VSTS, spits out the types instead
        Write-Output $result.Exception.Message
    }
}

# Prepare remote machines
$results = Invoke-Parallel -ImportVariables -ScriptFile $preparationScript -InputObject $machines -Parameter $parameters -Throttle $maxThrottle

Write-Output ""
Write-Output "==========================="
Write-Output "Remote Setup - Output logs:"
Write-Output "==========================="

$error = $false
foreach($result in $results) {
    Write-Output ""
    Write-Output "------------"
    Write-Output $result.MachineName
    Write-Output "------------"
    foreach ($logLine in $result.Log) {
        Write-Output $logLine
    }

    if ($result.Exception -ne $null) {
        $error = $true
        Write-Output "[EXCEPTION] - $($result.Exception.Message)"
        # TODO: Look at formatting in VSTS, spits out the types instead
        $exception = $result.Exception
        $exception | Format-List * -Force
        $exception.InvocationInfo | Format-List *
    }
}

Write-Output ""

if ($error) {
    throw "An error has occurred on at least 1 machine. Check the logs above for the reason."
}