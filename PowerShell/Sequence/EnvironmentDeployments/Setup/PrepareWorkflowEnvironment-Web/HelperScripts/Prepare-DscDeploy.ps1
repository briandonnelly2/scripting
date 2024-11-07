Function ExportCertificate {
[CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [Security.Cryptography.X509Certificates.X509Certificate2]$Cert,
        [Parameter(Mandatory = $true)]
        [IO.FileInfo]$FilePath,
        [switch]$IncludeAllCerts
    )
    $certs = New-Object Security.Cryptography.X509Certificates.X509Certificate2Collection
    if ($IncludeAllCerts) {
        $chain = New-Object Security.Cryptography.X509Certificates.X509Chain
        $chain.ChainPolicy.RevocationMode = "NoCheck"
        [void]$chain.Build($Cert)
        $chain.ChainElements | ForEach-Object {[void]$certs.Add($_.Certificate)}
        $chain.Reset()
    } else {
        [void]$certs.Add($Cert)
    }
    if (!(Test-Path $FilePath.FullName)) {
        New-Item $FilePath.FullName
    }
    [io.file]::WriteAllBytes($FilePath.FullName, $certs.Export('cer'))
}

Function CreateMofFiles {
    param(
        [string]$Name, 
        [string]$MofOutputPath,
        [hashtable] $LocalhostConfigData)

    if ([string]::IsNullOrWhiteSpace($MofOutputPath)) {
        throw "A MOF output path is required."
    }

    # An exception is thrown here if the command doesn't exist.
    $command = Get-Command -Name $Name -CommandType Configuration
    if ($command -eq $null) {
        return
    }

    if (Test-Path $MofOutputPath) {
        Remove-Item $MofOutputPath -Force -Recurse
    }

    # Get certificate & configuration data
    $certName = 'DscEncryption'
    $certExportFile = (Get-Item ([System.IO.Path]::GetTempFileName())).FullName
    $dscCert = Get-ChildItem Cert:\LocalMachine\My `
        | Where-Object { $_.Subject -eq "CN=$certName" -and $_.NotBefore -le (Get-Date) -and $_.NotAfter -ge (Get-Date) } `
        | Sort-Object NotAfter -Descending | Select-Object -First 1
    if ($dscCert -eq $null) { throw "A DSC encryption certificate cannot be found. Please run the PrepareMachinesForDeployment task prior to this one." }
    ExportCertificate -Cert $dscCert -FilePath $certExportFile | Out-Null

    if ($LocalhostConfigData -eq $null) {
        $LocalhostConfigData = @{}
    }

    $LocalhostConfigData.NodeName = 'localhost';
    $LocalhostConfigData.Thumbprint = $dscCert.Thumbprint;
    $LocalhostConfigData.CertificateFile = $certExportFile; 
    $LocalhostConfigData.PSDscAllowDomainUser = $true 

    $configurationData = @{ 
        AllNodes = @($LocalhostConfigData) 
    }

    # Generate the MOF files
    $mofParams = @{
        ConfigurationData = $configurationData
        OutputPath = $MofOutputPath
    }
    $mofFiles = & $Name @mofParams

    # Remove the cert
    Remove-Item $certExportFile -Force
}

Function PerformDscFromMofFiles {
    param([string]$MofOutputPath, [switch]$RemoveOutputPath)

    # Start the DSC configuration
    if ((Get-ChildItem $MofOutputPath -Filter '*.meta.mof' | Measure-Object).Count -gt 0) {
        Set-DscLocalConfigurationManager -Path $MofOutputPath
    }

    $log = $(Start-DscConfiguration -Path $MofOutputPath -Wait -Force -Verbose) 2>&1 3>&1 4>&1 5>&1
    $errors = @()
    $log = $log | ForEach-Object {
        if ($_ -is [System.Management.Automation.ErrorRecord]) {
            $errors += $_
            return "[EXCEPTION] $_"
        } else {
            return "$_".Replace("VERBOSE: ","")
        }
    }

    # Remove the generated MOF files
    if ($RemoveOutputPath) {
        Remove-Item $MofOutputPath -Recurse -Force | Out-Null
    }

    $exception = $null
    if (($errors | Measure-Object).Count -gt 0) {
        # Get the first exception.
        $exception = $errors[0]
    }

    return @{ Log = $log; Exception = $exception }
}

Function PerformDsc {
    param(
        [string]$Name,
        [string]$MofOutputPath,
        [hashtable]$LocalhostConfigData)

    $removeOutputPath = [string]::IsNullOrWhiteSpace($MofOutputPath)
    if ($removeOutputPath) {
        $MofOutputPath = ($env:TEMP + "\MofFiles_" + ([System.Guid]::NewGuid().ToString()))
    }

    CreateMofFiles -Name $Name -MofOutputPath $mofOutputPath -LocalhostConfigData $LocalhostConfigData
    return PerformDscFromMofFiles -MofOutputPath $MofOutputPath -RemoveOutputPath:$removeOutputPath
}