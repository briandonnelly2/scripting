<# 
    This script will import a CSV file with CCH Central client information, with client code and UTR.
    This information will then be fed into an SQL script which will use the client code to locate the 
    clkient and update the UTR field.
#>

#Set this to the location of the CSV file with the CCH client info
Set-Location -Path 'E:\Shares\TPL Deployment Share\CCHSuite\Bulk Update UTR Field\Client Data'

#Define the database cluster and database this will run against
$ClusterName = 'UKVMUSQL1006\DB01'
$CCHDatabaseName = 'CCHCentral_UAT'

#Store the CCH client info
$CCHCLientInfo = Import-Csv -Path '.\CCH_UTR_Updates.csv'

#loop through all CCH clients in the list
foreach($CCHClient IN $CCHClientInfo) {
    $CCHQuery = 
    "SELECT cs.clientcode
     FROM dbo.Contact AS c
       INNER JOIN dbo.CLientSupplier AS cs ON c.ContactID = cs.ContactID
       WHERE ClientCode = '" + $CCHClient.clientcode + "'"

    $CCHQuery2 = 
    "SELECT cs.clientcode
     ,UTR
      FROM dbo.Contact AS c
	    INNER JOIN dbo.CLientSupplier AS cs ON c.ContactID = cs.ContactID
        WHERE ClientCode = '" + $CCHClient.clientcode + "'"

    #Update the UTR field in the contact table by joining to the ClientSupplier table to identify the client by their client code
    $CCHUpdate = 
    "UPDATE c
     SET UTR = '" + $CCHCLient.UTR + "'" +
     "FROM dbo.Contact AS c
	    INNER JOIN dbo.ClientSupplier AS cs ON c.ContactID = cs.ContactID
	    WHERE cs.ClientCode = '" + $CCHClient.clientcode + "'"

    #Query the CCH database for the current client
    $CCHQueryResult = Invoke-Sqlcmd -AbortOnError -Database $CCHDatabaseName -Query $CCHQuery -ServerInstance $ClusterName -Encrypt Optional

    #Checks that what we find has the same client code as what is on our CSV file for the current client as a failsafe check
    If($CCHQueryResult.clientcode = $CCHClient.clientcode) {
        #Update the UTR field
        Invoke-Sqlcmd -AbortOnError -Database $CCHDatabaseName -Query $CCHUpdate -ServerInstance $ClusterName -Encrypt Optional

        #Run another query to see the updated client
        $CCHQueryResult2 = Invoke-Sqlcmd -AbortOnError -Database $CCHDatabaseName -Query $CCHQuery2 -ServerInstance $ClusterName -Encrypt Optional

        #Print a message
        Write-Host -Message 'Client Code - ' $CCHQueryResult2.clientcode ' Client UTR - '$CCHQueryResult2.UTR 
    }
    Else {
        #Print a message
        Write-Host -Message "CCH Client codes don't match.  the UTR field was not updated for the following client:"
        Write-Host -Message $CCHQueryResult
    }
}