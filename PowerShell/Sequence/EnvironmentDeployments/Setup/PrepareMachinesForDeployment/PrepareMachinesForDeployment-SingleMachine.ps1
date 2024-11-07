# Note: This script is run in parallel, and uses variables defined in PrepareMachinesForDeployment.ps1
param($machineName, $parameter)

# This preference is important for the Try .. Catch
$errorActionPreference = 'Stop'

$scriptRoot = $parameter.ScriptRoot
$machineName = $machineName.Trim()
$credential = $parameter.credential
$useSsl = $parameter.useSsl
$skipCertificateTests = $parameter.skipCertificateTests

$prepareCalamari = $parameter.prepareCalamari
$prepareCommonDsc = $parameter.prepareCommonDsc

$installDscCertificate = $parameter.installDscCertificate

$calamariSource = "$scriptRoot\Packages\Calamari"
$calamariDestination = "C:\Deployments\Tools"

$commonDscSource = "$scriptRoot\Packages\CommonDsc"
$commonDscDestination = "C:\Program Files\WindowsPowerShell\Modules"

. "$scriptRoot\DeployPackageFiles.ps1"
. "$scriptRoot\HelperScripts\Send-File.ps1"

$log = @()

try {

    if ($skipCertificateTests) {
        $sessionOption = New-PSSessionOption -SkipCACheck -SkipCNCheck
    } else {
        $sessionOption = New-PSSessionOption
    }
    
    # Create a session 
    $session = New-PSSession -ComputerName $machineName -UseSSL:$useSsl -SessionOption $sessionOption -Credential $credential

    # Deploy calamari
    if ($session -ne $null -and $prepareCalamari) {
        $packageLogName = "Calamari"
        $deployResult = DeployPackageFiles -Session $session -LocalSource $calamariSource -RemoteDestination $calamariDestination -PackageLogName $packageLogName -RemoveOtherVersions
        $log += $deployResult.Log
        # Got the log, throw the exception
        if ($deployResult.Exception -ne $null) {
            throw $deployResult.Exception
        }

        if ($deployResult.PackageUpdated) {
            # Set the tentacle journal machine variable
            $log += "$packageLogName - Setting TentacleJournal environment variable"
            Invoke-Command -Session $session {
                $calamariDestination = $using:calamariDestination 
                [Environment]::SetEnvironmentVariable("TentacleJournal", "$calamariDestination\CalamariJournal.xml", "Machine") 
            }
        }
    }

    # Deploy common DSC modules
    if ($prepareCommonDsc) {
        $packageLogName = "Common DSC"
        $deployResult = DeployPackageFiles -Session $session -LocalSource $commonDscSource -RemoteDestination $commonDscDestination -PackageLogName $packageLogName -RemoveOtherVersions -FilesInRootFolderIfPowershellNot5
        $log += $deployResult.Log
        # Got the log, throw the exception
        if ($deployResult.Exception) {
            throw $deployResult.Exception
        }
    }

    # Install DSC Encryption Certificate on remote machine if DSC required
    if ($installDscCertificate) {
        $log += ""
        $log += "DSC - Checking DSC encryption certificate"
        $scriptCreated = Invoke-Command -Session $session -FilePath "$scriptRoot\SetupDscEncryptionCertificate.ps1"
        if ($scriptCreated) {
            $log += "DSC - DSC encryption certificate created"
        } else {
            $log += "DSC - Valid DSC encryption certificate already exists"
        }
    }
} 
catch 
{
    $exception = $_.Exception
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