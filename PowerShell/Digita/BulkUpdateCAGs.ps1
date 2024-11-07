<# 
    This script will import 2 CSV files with DPM & DPT client information and use these to locate clients, strip them of their current client access groups and then assign them new ones.
#>

#Set this to the location of the CSV files with the DPT and DPM information
Set-Location -Path 'C:\Users\briandonnelly2\OneDrive - KPMG\Working Folder\Digita\CAG Updates'

#Define the database cluster and databases this will run against
$ClusterName = 'UKIXESQL382\DB01'
$DPMDatabaseName = 'PracticeManagementCoE_Staging'
$DPTDatabaseName = 'TaxywinCOE_Staging'

#region DPM Updates
#Store the DPM client info
$DPMClientInfo = Import-Csv -Path '.\DPM_Updates.csv'

#GUID's of the IES onshore and offshore client access groups
$DPMOnshoreCAG = '132C0767-1997-4D45-9994-9DEF49B3DA8E'
$DPMOffshoreCAG = '14AC79DF-25FE-4212-9223-681104FA4179'
$DPMCAG

#Locate client using BBE ID and confirm by matching the digita refcode
$DPMQuery = 
"SELECT   be.FileAs
		,be.ClientCode
		,be.BillableEntityID
		,cg.ClientGroupID
FROM BillableEntity AS be
WHERE be.BillableEntityID = " + $DPMClient.BillableEntityID

$DPMQuery2 = 
"SELECT   be.FileAs
		,be.ClientCode
		,be.BillableEntityID
		,cg.ClientGroupID
FROM BillableEntity AS be
LEFT JOIN ClientGroupBillableEntity AS cg ON cg.BillableEntityID = be.BillableEntityID
WHERE be.BillableEntityID = " + $DPMClient.BillableEntityID

$DPMUpdate1 =
"DELETE FROM ClientGroupBillableEntity 
WHERE BillableEntityID = " + $DPMClient.BillableEntityID

$DPMUpdate2 = 
"INSERT INTO ClientGroupBillableEntity (ClientGroupID, BillableEntityID)
VALUES (" + $DPMCAG + "," + $DPMClient.BillableEntityID + ")"

#loop through all DPM clients in the list
foreach($DPMClient IN $DPMClientInfo) {
    #Query the DPM database for the current client
    $DPMQueryResult = Invoke-Sqlcmd -AbortOnError -Database $DPMDatabaseName -Query $DPMQuery -ServerInstance $ClusterName

    #Sets the value of $CAG to the correct client access group we should be using in the update
    If($DPMClient.DPMShouldBe -like 'IES Offshore*') { $DPMCAG = $DPMOffshoreCAG } Else { $DPMCAG = $DPMOnshoreCAG }

    #Checks that what we find has the same ref code as what is on our CSV file for the current client as a failsafe check
    If($DPMQueryResult.ClientCode = $DPMClient.ClientCode) {
        #Remove existing client access groups
        Invoke-Sqlcmd -AbortOnError -Database $DPMDatabaseName -Query $DPMUpdate1 -ServerInstance $ClusterName
    
        #Add new Client access group
        Invoke-Sqlcmd -AbortOnError -Database $DPMDatabaseName -Query $DPMUpdate2 -ServerInstance $ClusterName

        #Run another query to see the updated client
        $DPMQueryResult2 = Invoke-Sqlcmd -AbortOnError -Database $DPMDatabaseName -Query $DPMQuery2 -ServerInstance $ClusterName

        #Print a message
        Write-Verbose -Message "DPM Client groups after change:"
        Write-Verbose -Message $DPMQueryResult2
    
    }
    Else {
        #Print a message
        Write-Verbose -Message "DPM Client codes don't match.  the client groups were not updated for the following client:"
        Write-Verbose -Message $DPMQueryResult
    }
}
#endregion DPM Updates

#region DPT Updates
$DPTClientInfo = Import-Csv -Path '.\DPT_Updates.csv'

$DPTOffshoreCAG = 'IES Offshore'
$DPTOnshoreCAG = 'IES UK'
$DPTCAG

$DPTQuery = 
"SELECT	 c.SURNAME + ' ' + c.FIRSTNAMES AS 'FileAs'
,c.REFCODE AS 'ClientCode'
,c.EntityId AS 'BillableEntityID'
,gc.GroupId AS 'ClientgroupID'
FROM Client AS c
WHERE EntityId = " + $DPTClient.BillableEntityID

$DPTQuery2 = 
"SELECT	 c.SURNAME + ' ' + c.FIRSTNAMES AS 'FileAs'
,c.REFCODE AS 'ClientCode'
,c.EntityId AS 'BillableEntityID'
,gc.GroupId AS 'ClientgroupID'
FROM Client AS c
LEFT JOIN GroupClient AS gc ON gc.Clientid = c.REFCODE
WHERE EntityId = " + $DPTClient.BillableEntityID

$DPTUpdate1 =
"DELETE FROM GroupClient 
WHERE ClientID = " + $DPTClient.BillableEntityID

$DPTUpdate2 =
"INSERT INTO GroupClient (ClientID, GroupID)
VALUES (" + $DPTCAG + "," + $DPTClient.BillableEntityID + ")"

#loop through all DPT clients in the list
foreach($DPTClient IN $DPTClientInfo) {
    #Query the DPM database for the current client
    $DPTQueryResult = Invoke-Sqlcmd -AbortOnError -Database $DPTDatabaseName -Query $DPTQuery -ServerInstance $ClusterName

    #Sets the value of $CAG to the correct client access group we should be using in the update
    If($DPTClient.DPTShouldBe -like 'IES Offshore*') { $DPTCAG = $DPTOffshoreCAG } Else { $DPTCAG = $DPTOnshoreCAG }

    #Checks that what we find has the same ref code as what is on our CSV file for the current client as a failsafe check
    If($DPTQueryResult.ClientCode = $DPTClient.ClientCode) {
        #Remove existing client access groups
        Invoke-Sqlcmd -AbortOnError -Database $DPTDatabaseName -Query $DPTUpdate1 -ServerInstance $ClusterName
    
        #Add new Client access group
        Invoke-Sqlcmd -AbortOnError -Database $DPTDatabaseName -Query $DPTUpdate2 -ServerInstance $ClusterName

        #Run another query to see the updated client
        $DPTQueryResult2 = Invoke-Sqlcmd -AbortOnError -Database $DPTDatabaseName -Query $DPTQuery2 -ServerInstance $ClusterName

        #Print a message
        Write-Verbose -Message "DPT Client groups after change:"
        Write-Verbose -Message $DPTQueryResult2
    }
    Else {
        #Print a message
        Write-Verbose -Message "DPT Client codes don't match.  the client groups were not updated for the following client:"
        Write-Verbose -Message $DPTQueryResult
    }
}
#endregion DPT Updates