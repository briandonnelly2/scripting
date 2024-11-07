<#

.SYNOPSIS
Prepares web servers in an environment configured for Workflow.

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

.PARAMETER WorkingDirectory
The working directory to store MOF files in.

.PARAMETER Environment
The environment configured.

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
    # DSC Parameters
    [Parameter(Mandatory=$true)]
    [ValidateSet("Dev","DevUkx","Test","TestUkx","Stg","Live","LivePA")]
    [string]$Environment,
    [Parameter(Mandatory=$true)]
    [string]$DeploymentPath,
    [Parameter()]
    [string]$SvcSequenceAdminUserName,
    [Parameter()]
    [string]$SvcSequenceAdminPass,
    [Parameter()]
    [pscredential]$SvcSequenceAdminCredential,
    [Parameter()]
    [string]$SvcPortalUserName,
    [Parameter()]
    [string]$SvcPortalPass,
    [Parameter()]
    [pscredential]$SvcPortalCredential,

    [Parameter()]
    [string]$SvcAlphataxUserName,
    [Parameter()]
    [string]$SvcAlphataxPass,
    [Parameter()]
    [pscredential]$SvcAlphataxCredential,

    [Parameter()]
    [string]$SvcDigitaUserName,
    [Parameter()]
    [string]$SvcDigitaPass,
    [Parameter()]
    [pscredential]$SvcDigitaCredential,

    [Parameter()]
    [string]$SvcEfilingUserName,
    [Parameter()]
    [string]$SvcEfilingPass,
    [Parameter()]
    [pscredential]$SvcEfilingCredential,

    [Parameter()]
    [string]$SvcSapUserName,
    [Parameter()]
    [string]$SvcSapPass,
    [Parameter()]
    [pscredential]$SvcSapCredential
)

$ErrorActionPreference = 'Stop'

Write-Output "Preparing a Workflow environment."

#----------------------------------------------------------
# DSC CONFIG START
#----------------------------------------------------------

$dscScript = "$PSScriptRoot\PrepareWorkflowEnvironment-App-Dsc.ps1"

# Dot-source the Get-AccountCredential function
. "$PSScriptRoot/HelperScripts/Get-AccountCredential.ps1"

# Params
$dscParams = @{
    Environment = $Environment;
    DeploymentPath = $DeploymentPath;
}

$dscSecureParams = @{
    SvcPortalCredential = Get-AccountCredential -UserName $SvcPortalUserName -Pass $SvcPortalPass -Credential $SvcPortalCredential `
        -CredentialRequired -DialogMessage "Please provide a credential for a Portal service account.";
    SvcSequenceAdminCredential = Get-AccountCredential -UserName $SvcSequenceAdminUserName -Pass $SvcSequenceAdminPass -Credential $SvcSequenceAdminCredential `
        -CredentialRequired -DialogMessage "Please provide a credential for a Sequence Admin service account.";
    SvcAlphataxCredential = Get-AccountCredential -UserName $SvcAlphataxUserName -Pass $SvcAlphataxPass -Credential $SvcAlphataxCredential `
        -CredentialRequired -DialogMessage "Please provide a credential for an Alphatax service account.";
    SvcDigitaCredential = Get-AccountCredential -UserName $SvcDigitaUserName -Pass $SvcDigitaPass -Credential $SvcDigitaCredential `
        -CredentialRequired -DialogMessage "Please provide a credential for a Digita service account.";
    SvcEfilingCredential = Get-AccountCredential -UserName $SvcEfilingUserName -Pass $SvcEfilingPass -Credential $SvcEfilingCredential `
        -CredentialRequired -DialogMessage "Please provide a credential for an Efiling service account.";
    SvcSapCredential = Get-AccountCredential -UserName $SvcSapUserName -Pass $SvcSapPass -Credential $SvcSapCredential `
        -CredentialRequired -DialogMessage "Please provide a credential for a SAP service account.";
}

#----------------------------------------------------------
# DSC CONFIG END
#----------------------------------------------------------

# Set to true to perform a package extraction onto servers
$performPackageExtraction = $false

# Do the work
. "$PSScriptRoot\HelperScripts\Publish-ToMachines.ps1"