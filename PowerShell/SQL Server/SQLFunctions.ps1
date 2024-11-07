Function Get-KPMGSQLServerDatabaseInfo {
<#
    .SYNOPSIS
        Invokes SQL scripts to return application database information.
    .PARAMETER DatabaseInstances
        The names of the database instances the scripts are rto be invoked against
    .PARAMETER SqlScripts
        The scripts that should be executed
    .EXAMPLE
#>
    [CmdletBinding()]
    param(
        [Parameter( Mandatory )]
        [string]$DatabaseInstance,
        #$DatabaseInstance = "UKIXESQL384\DB01"
        [Parameter( Mandatory )]
        [string]$ScriptDir,
        #$ScriptDir = "C:\Users\-oper-briandonnelly2\Documents"
        [Parameter( Mandatory )]
        [string[]]$SqlScripts
        #$SqlScripts = "testquery.sql"
    )
    
    process {
        $Runtime = Get-Date -Format ' - dd-MM-yyyy HH-mm'
        $OutputDir = '\\UKVMPAPP1094\TPLOutputShare\Automated Reports'

        If ( Test-Connection -ComputerName $DatabaseInstance.Split('\')[0] -Quiet ) {            
            Try {
                foreach ($script in $SqlScripts) {
                    $OutputName = $Script.Split('.')[0] + ' ' + $Runtime + '.csv'

                    $Output = Invoke-Sqlcmd -AbortOnError -InputFile "$ScriptDir\$Script" -ServerInstance $DatabaseInstance

                    Set-Location C:
                    
                    $Output | Export-Csv -Path "$OutputDir\$OutputName" -NoTypeInformation -Force

                    $output = $null
                }
            } 
            Catch {
                Write-Error ($_.Exception.message)
            }
        }
        Else { 
            Write-Error "Error when contacting the $DatabaseInstance database server. Please check details and retry."

            Start-Sleep -Milliseconds 250
        }
    }
}

<# 
G:\Scripts\PowerShell\Get-KPMGSQLServerDatabaseInfo.ps1

-DatabaseInstance 'UKIXESQL023\DB01' -ScriptDir "G:\Scripts\SQL" -SqlScripts 'PA Amendments Report - 2018.sql', 'PA Amendments Report - 2019.sql', 'PA Amendments Report - 2020.sql', 'PCC Amendments Report - 2018.sql', 'PCC Amendments Report - 2019.sql', 'PCC Amendments Report - 2020.sql'

-DatabaseInstance 'UKIXESQL023\DB01' -ScriptDir "G:\Scripts\SQL" -SqlScripts 'GMS EFiling Status Issues Report - 2017.sql', 'GMS EFiling Status Issues Report - 2018.sql', 'GMS EFiling Status Issues Report - 2019.sql', 'GMS EFiling Status Issues Report - 2020.sql'

-DatabaseInstance 'UKIXESQL023\DB01' -ScriptDir "G:\Scripts\SQL" -SqlScripts 'GMS EFiling Status Issues Report - 2019.sql', 'GMS EFiling Status Issues Report - 2020.sql'

GMS EFiling Status Issues Report - 2019, 2020 - Sat 30th Jan - 10AM & 1PM

This task will run the GMS EFiling Status Issues Report for 2019 and 2020 on a specified schedule and send the output to a restricted fileshare on UKVMPAPP1094.
#>