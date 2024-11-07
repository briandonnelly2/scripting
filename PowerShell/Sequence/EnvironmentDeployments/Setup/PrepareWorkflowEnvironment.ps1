[CmdletBinding()]
param(
    [pscredential]$WinRmCredential,
    [pscredential]$SequenceCredential,
    [pscredential]$PortalCredential
)

$webServers = 'ukxvmsweb022'
$appServers = 'ukxvmsapp023'

if ($WinRmCredential -eq $null) {
    $WinRmCredential = Get-Credential -Message 'Provide a credential to run this setup as'
}

if ($SequenceCredential -eq $null) {
    $SequenceCredential = Get-Credential -Message 'Provide a sequence admin credential'
}

if ($PortalCredential -eq $null) {
    $PortalCredential = Get-Credential -Message 'Provide a portal credential'
}

. $PSScriptRoot\PrepareMachinesForDeployment\PrepareMachinesForDeployment.ps1 -MachineNames "$webServers,$appServers" `
    -WinRmProtocol https -WinRmSkipCertificateTests true -ParallelDeploymentThrottle 1 `
    -PrepareCommonDsc true -PrepareCalamari false -WinRmAdminCredential $WinRmCredential

. $PSScriptRoot\PrepareWorkflowEnvironment-App\PrepareWorkflowEnvironment-App.ps1 -MachineNames $appServers `
    -WinRmProtocol https -WinRmSkipCertificateTests true -ParallelDeploymentThrottle 1 `
    -WinRmAdminCredential $WinRmCredential `
    -Environment DevUkx -DeploymentPath G:\Deployments `
    -SvcSequenceAdminCredential $SequenceCredential `
    -SvcPortalCredential $PortalCredential `
    -SvcAlphataxCredential $PortalCredential `
    -SvcDigitaCredential $PortalCredential `
    -SvcEfilingCredential $PortalCredential `
    -SvcSapCredential $PortalCredential

. $PSScriptRoot\PrepareWorkflowEnvironment-Web\PrepareWorkflowEnvironment-Web.ps1 -MachineNames $webServers `
    -WinRmProtocol https -WinRmSkipCertificateTests true -ParallelDeploymentThrottle 1 `
    -WinRmAdminCredential $WinRmCredential `
    -Environment DevUkx -DeploymentPath G:\Deployments `
    -SvcSequenceAdminCredential $SequenceCredential `
    -SvcPortalCredential $PortalCredential