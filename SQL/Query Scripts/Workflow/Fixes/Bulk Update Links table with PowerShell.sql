/***
$Clients = Import-Csv -Path 'C:\Users\-oper-briandonnelly2\Desktop\WFUpdates.csv'

$ClusterName = 'UKIXESQL005\DB01'
$DatabaseName = 'TaxWFPortalData'
$OldCode
$NewCode


Invoke-Sqlcmd -AbortOnError -Database $DatabaseName -Query $Query1 -ServerInstance $ClusterName

$Update1 = 'UPDATE [TaxWFPortalData].[dbo].[Links] SET ForeignCode = ' + $NewCode + ' WHERE LinkTypeId = 2 AND ForeignCode = ' + $OldCode
Invoke-Sqlcmd -AbortOnError -Database $DatabaseName -Query $Update1 -ServerInstance $ClusterName

$Query2 = 'SELECT * FROM [TaxWFPortalData].[dbo].[Links] WHERE LinkTypeId = 2 AND ForeignCode = ' + $NewCode
Invoke-Sqlcmd -AbortOnError -Database $DatabaseName -Query $Query2 -ServerInstance $ClusterName
$Client2 = @()

foreach($Client IN $Clients) {
    $OldCode = "'" + $Client.OldCode + "'"
    $NewCode = "'" + $Client.NewCode + "'"

    #$Query1 = 'SELECT * FROM [TaxWFPortalData].[dbo].[Links] WHERE LinkTypeId = 2 AND ForeignCode = ' + $OldCode
    #$Update1 = 'UPDATE [TaxWFPortalData].[dbo].[Links] SET ForeignCode = ' + $NewCode + ' WHERE LinkTypeId = 2 AND ForeignCode = ' + $OldCode
    $Query2 = 'SELECT * FROM [TaxWFPortalData].[dbo].[Links] WHERE LinkTypeId = 2 AND ForeignCode = ' + $NewCode
    $Client2 += Invoke-Sqlcmd -AbortOnError -Database $DatabaseName -Query $Query2 -ServerInstance $ClusterName
}

$Compare2 = $Client2.ForeignCode

$Compare = $Clients.NewCode

If($Compare = $Compare2) { Write-Host "success!"}
***/