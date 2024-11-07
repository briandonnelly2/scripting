Function Get-AccountCredential {
    <#

    .SYNOPSIS
    Gets a credential object from a provided credential, username and password. Optionally asks the user for credentials

    .PARAMETER UserName
    A username string

    .PARAMETER Pass
    A password string

    .PARAMETER Credential
    A credential object, which will be simply returned if provided

    .PARAMETER CredentialRequired
    If set, the user will be asked for credentials

    .PARAMETER DialogMessage
    The message to display on a dialog (if shown) asking the user for credentials

    #>

    param(
        [string]$UserName,
        [string]$Pass,
        [pscredential]$Credential,
        [switch]$CredentialRequired,
        [string]$DialogMessage
    )

    if ($Credential -ne $null) {
        return $Credential
    }

    if (![string]::IsNullOrWhiteSpace($UserName) -and ![string]::IsNullOrWhiteSpace($Pass)) {
        return New-Object System.Management.Automation.PSCredential($UserName, (ConvertTo-SecureString $Pass -AsPlainText -Force))
    }

    if (!$CredentialRequired) {
        return $null;
    }

    $Credential = Get-Credential -Message $DialogMessage

    if ($Credential -eq $null) {
        throw "A required credential was not provided."
    }
    
    return $Credential
}