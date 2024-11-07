USE [TaxWFPortalData]

GO
SET NOEXEC OFF
/* ----------------------------------------------------------- */
/* A. REQUIRED INPUTS: The information provided to us on the   */
/* setup sheet. You need to enter this data for the script to  */
/* return valid Information.  Missing details should be        */
/* obtained from the requestor if required.                    */
/* ----------------------------------------------------------- */

DECLARE @MSDOppNumber NVARCHAR(100) = '90029119'--'11768466' --SAP/MSD opportunity number
DECLARE @AtlasID NVARCHAR(100) = '6048' --Atlas ID
DECLARE @MSDClientNumber NVARCHAR(100) = '60623435' --SAP/MSD client number
DECLARE @SuppliedClientName NVARCHAR(100) = '6048 eResearch Technology' --The supplied client name
DECLARE @CanGoOffshore NVARCHAR(100) = 'False' --Is the client permitted to be worked on offshore? (True/False)

/* --------------------------------------------------- */
/* B. The information we will obtain using this script */
/* Variables are declared to hold these values.        */
/* --------------------------------------------------- */

DECLARE @ReturnedClientNumber NVARCHAR(100) --SAP/MSD client number linked to the SAP/MSD opportunity number provided (if it exists)
DECLARE @LeadClientID NVARCHAR(100) --Workflow ID of the lead client (if it exists)
DECLARE @WFLeadClientName NVARCHAR(100) --Name of the lead client on workflow (if it exists)
DECLARE @ClientID NVARCHAR(100) --Workflow ID of the client (if it exists)
DECLARE @WFClientName NVARCHAR(100) --Client name from workflow (if it exists)
DECLARE @BBEID NVARCHAR(100) -- The billable entity ID of the client in Digita (if it exists)
DECLARE @DigitaClientName NVARCHAR(100) --Name of the client in Digita (if it exists)
DECLARE @MSDLeadClientName NVARCHAR(100) --Lead client name from SAP/MSD extract DB (if it exists)
DECLARE @ClientGroupName NVARCHAR(100) --Client access group to be assigned to this client (if this exists). 

/* ---------------------------------------------------- */
/* C. The queries that obtain the information we        */
/* require These are stored in variables for later use. */
/* ---------------------------------------------------- */

--1. Retrieves the SAP/MSD client number from the SAP extract database for the supplied opportunity ID.
SET @ReturnedClientNumber = ( SELECT ClientNumber FROM  [UKDTASQLCLU05\MSSQLUKDTADB07].[SAPExtract].[dbo].[TaxWorkflow_TaxComplianceOpportunities] WHERE OpportunityNumber = @MSDOppNumber )
--2. Gets the SAP/MSD client name that is returned from the SAP extract database for the supplied opportunity ID.
SET @MSDLeadClientName = ( SELECT ClientName FROM  [UKDTASQLCLU05\MSSQLUKDTADB07].[SAPExtract].[dbo].[TaxWorkflow_TaxComplianceOpportunities] WHERE OpportunityNumber = @MSDOppNumber )
--3. Checks if the lead client on the opportunity exists in workflow and returns the workflow ID if it does.
SET @LeadClientID = ( SELECT DISTINCT ClientID FROM Links WHERE ForeignCode = @ReturnedClientNumber AND LinkTypeID = 1 )
--4. Stores the name of the lead client in worflow if it exists
SET @WFLeadClientName = ( SELECT DISTINCT ForeignName FROM Links WHERE ForeignCode = @ReturnedClientNumber AND LinkTypeID = 1 )
--5. Checks if the client we are being asked to setup exists in workflow and returns the workflow ID if it does.
SET @ClientID = ( SELECT DISTINCT ClientID FROM Links WHERE ForeignCode = @AtlasID AND LinkTypeID IN (2,5,6) )
--6. Stores the name of the client in workflow if it exists
SET @WFClientName = ( SELECT DISTINCT ForeignName FROM Links WHERE ForeignCode = @AtlasID  AND LinkTypeID IN (2,5,6) )
--7. Checks if the client we are being asked to setup exists in DPM and returns the billable entity ID if it does.
SET @BBEID = ( SELECT be.billableentityid FROM DigitaTax.PracticeManagementCoE.dbo.billableentity AS be WITH (NOLOCK) wHERE be.clientcode = @AtlasID )
--8. Grabs the name of the client from DPM if it exists.
SET @DigitaClientName = ( SELECT be.fileas FROM DigitaTax.PracticeManagementCoE.dbo.billableentity AS be WITH (NOLOCK) WHERE be.clientcode = @AtlasID )
--9. Based on the value provided in @CanGoOffshore, will tell the user which client access group to select.
IF (@CanGoOffshore IN ('True','true','TRUE') ) 
	BEGIN SET @ClientGroupName = 'IES Offshore' END 
ELSE IF(@CanGoOffshore IN ('False','false','FALSE') ) 
	BEGIN	SET @ClientGroupName = 'IES UK'END
ELSE
BEGIN PRINT N'Client group not set properly.  Defaulting to IES UK.' END

/* ----------------------------------------------------------- */
/* D. Check to see if the SAP/MSD client code provided matches */
/* what is returned from the SAP/MSD extract database and      */
/* prints a suitble message to user.                           */
/* ----------------------------------------------------------- */
PRINT N'For the supplied opportunity ID of: ' + @MSDOppNumber + '...'
PRINT N''

--1. If the SAP/MSD client code found for the opp does not match the one supplied on the setup sheet...
IF (@MSDClientNumber <> @ReturnedClientNumber)
BEGIN
	PRINT N'The MSD/SAP Lead Client number provided on the setup sheet, ' + @MSDClientNumber + ', does not match the client number that is found, ' + @ReturnedClientNumber
	PRINT N'Please escalate this case.'
	PRINT N''
END
--2. Else-if the supplied SAP/MSD client code matches the SAP/MSD code in the extract database...
ELSE IF (@MSDClientNumber = @ReturnedClientNumber)
BEGIN
	PRINT N'The MSD/SAP Lead Client number provided on the setup sheet, ' + @MSDClientNumber + ', matches the code that is found, ' + @ReturnedClientNumber + ' and is named ' + @MSDLeadClientName
	PRINT N''
END
--3. Else the supplied SAP/MSD opportunity code returns no results from the extract database.
ELSE
BEGIN
	PRINT N'The supplied opportunity ID of: ' + @MSDOppNumber + ' does not match any existing SAP/MSD engagements'
	PRINT N'Please escalate this case if you do not understand what to do at this point.'
	PRINT N''
END

/* ----------------------------------------------------------- */
/* E. Check to see if a lead client already exists in workflow */
/* (Matches returned client ID to any existing primary SAP/MSD */
/* links and prints a suitable message to the user.            */
/* ----------------------------------------------------------- */

--1. If a primary SAP link IS NOT be found using the returned client number...
IF (@LeadClientID IS NULL)
BEGIN
	PRINT N'The MSD/SAP Lead Client with code, ' + @ReturnedClientNumber + ', and name ' + @MSDLeadClientName + ' does not exist on workflow yet.'
	PRINT N'Ask the processing team if we need to setup this lead client as a seperate entity from the one we are being asked to setup'
	PRINT N''
END
--2. Else a primary SAP link IS found using the returned client number...
ELSE
BEGIN
	PRINT N'The MSD/SAP Lead Client with code, ' + @ReturnedClientNumber + ', already exists on workflow. This has a workflow ID of ' + @LeadClientID + ' and is named ' + @WFLeadClientName
	PRINT N''
END

/* ----------------------------------------------------------- */
/* F. Check to see if the client we are being asked to setup   */
/* already exists in workflow (Matches supplied Atlas ID to    */
/* any existing Digita(2), GTS(5) or IESClient(6) links and    */
/* prints a suitable message to the user.                      */
/* ----------------------------------------------------------- */

--1. If there IS a match for any existing entries in the links table...
IF (@ClientID IS NOT NULL)
BEGIN
	PRINT N'A client already exists on workflow with the workflow client ID of ' + @ClientID + ' and is named ' + @WFClientName
	PRINT N''
END
--2. If there IS NOT a match for any existing entries in the links table...
ELSE
BEGIN
	PRINT N'A client with these details does not yet exist on workflow.  This can be setup in workflow provided all other details check out'
	PRINT N''
END

/* ----------------------------------------------------------- */
/* G. Check to see if the client we are being asked to setup   */
/* already exists in Digita Practice Management DB:            */  
/* SQL Cluster: UKIXESQL023\DB01							   */
/* DB Name: [PracticeManagementCoE]							   */
/* The supplied Atlas ID is used to check the [billableentity] */
/* table and prints a suitable message to the user.            */
/* ----------------------------------------------------------- */

--1. If the supplied Atlas ID DOES matche an existing client in DPM...
IF (@BBEID IS NOT NULL)
BEGIN
	PRINT N'The Atlas ID provided in the setup sheet, ' + @AtlasID + ', matches an existing client in Digita with billable entity ID, ' + @BBEID + ' and client name of, ' + @DigitaClientName 
	PRINT N'If you did not set this up as part of this request, ask the processing team if this is the same client and advise we cannot setup clients with duplicate details'
	PRINT N'If setup by you, proceed with creating the client in workflow now.'
	PRINT N''
END
--2. If the supplied Atlas ID DOES NOT matche an existing client in DPM...
ELSE
BEGIN
	PRINT N'A client with these details does not yet exist in Digita.  This should be created in DPM by selecting "New Company Client", using ' + @AtlasID
	PRINT N'as the clients Digita code, ' + @SuppliedClientName + ' as the clients name and as the can go offshore value is' + @CanGoOffshore 
		  + ', ensure this client is set to the ' + 'IES UK' + ' client access group.'
	PRINT N'Once client has been created, please run this script again to obtain the billable entity ID for client setup in workflow.'
	PRINT N''
END

SET NOEXEC ON