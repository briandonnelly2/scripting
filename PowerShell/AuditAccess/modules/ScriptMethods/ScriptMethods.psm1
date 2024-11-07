Set-StrictMode -Version 1.0

Function New-KPMGPSSessions {
<#
    .DESCRIPTION
        Creates PSSessions to a given list of servers.
    .PARAMETER Credentials
        A PS Credentials object. (mandatory)
    .PARAMETER ServerNames
        An array of server names.
    .PARAMETER LogFilePath
        PowerShell sessions are passed for the function to query against (mandatory)
    .EXAMPLE
        
    .EXAMPLE

#>  

    [CmdletBinding()]
    param(
        [Parameter( Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName,
        HelpMessage = "Please enter operator level credentials." )]
        [pscredential]$Credentials,
        
        [Parameter( Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName,
        HelpMessage = "Please pass in an array of server names." )]
        [string[]]$ServerNames,

        [Parameter( Mandatory, ValueFromPipelineByPropertyName,
        HelpMessage = "Please pass in an array of server names." )]
        [string]$LogFIlePath
    )

    Process {
        Try {
            Write-KPMGLogInfo -LogFilePath $LogFilePath -Message "Set up PowerShell sessions to the specified servers" -ToConsole:$false
            [System.Object[]]$Sessions += New-PSSession -ComputerName $ServerNames -Credential $Credentials -Name $ServerNames
            foreach( $Server IN $ServerNames ) {
                If( !( $Server -in $Sessions.Name ) ) {
                    Throw "The information returned is not consistent.  Terminating all sessions to be safe."
                }
                Write-KPMGLogInfo -LogFilePath $LogFilePath -Message "PowerShell Session successfully created to $Server" -ToConsole:$false
            }
            return $Sessions
        }
        Catch {
            Get-PSSession | Remove-PSSession
            Write-KPMGLogError -LogFilePath $LogFIlePath -Message ($_.Exception.message) -ToConsole:$false -ExitGracefully:$true
        }
    }
}