USE [TaxWFPortalData]

SET NOEXEC OFF

GO

DECLARE @ClientName NVARCHAR(100)			= 'NSK Europe Ltd' --Client name from setup sheet
DECLARE @LeadClientName NVARCHAR(100)		= 'NSK Europe Ltd' --lead client name from setup sheet
DECLARE @WFCLientID INT
DECLARE @BusinessServiceLine INT			= 3 --3 GMS
DECLARE @ClientAccessGroupId INT			= 3 --3 GMS Onshore, 4 GMS Offshore
DECLARE @OwnLeadClient INT					= 1 --Choose 0 if the lead client already exists, 1 if this is it's own lead client, 2 if the lead client needs setup separately.
DECLARE @OffshoreBit INT					= ( 
												CASE @ClientAccessGroupId
												WHEN 3 THEN 0 
												WHEN 4 THEN 1
												ELSE 0 END 
											  )
DECLARE @AtlasID NVARCHAR(100)				= '41032' --Atlas ID
DECLARE @MSDClientNumber NVARCHAR(100)		= '60144260' --SAP/MSD client number
DECLARE @BBEID NVARCHAR(100)

--Grabs the new client billiable entity ID
SET @BBEID = ( SELECT billableentityid FROM DigitaTax.PracticeManagementCoE.dbo.billableentity WITH (NOLOCK) WHERE clientcode = @AtlasID)
IF (@BBEID IS NULL)
	BEGIN
		PRINT N'The billable entity ID of the supplied client is null.  This suggests you have noit yet created the client in DPM.'
		PRINT N'Please correct this error before continuing.'

		SET NOEXEC ON
	END

ELSE

BEGIN TRANSACTION;

SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

SET XACT_ABORT ON;

BEGIN TRY

IF (@OwnLeadClient = 0)
	BEGIN
		--Create client in Workflow
		INSERT INTO Clients (ClientName, ClientTypeId)
		VALUES (@ClientName, 1)

		--Grab workflow client ID
		SET @WFCLientID = (SELECT ClientId FROM Clients WHERE ClientName = @ClientName)

		IF (@WFCLientID IS NULL)
		BEGIN
			PRINT N'The Workflow Client ID of the supplied client is null.  This suggests the client has not been created in Workflow properly.'
			PRINT N'Terminating script.  Please setup manually.'

			SET NOEXEC ON
		END

		ELSE
		--Add client access groups
		INSERT INTO ClientAccessGroupClients (ClientAccessGroupId, ClientId)
		VALUES ( @ClientAccessGroupId , @WFClientID )

		--Set offshore restriction
		INSERT INTO ClientOSRCodes (ClientId, BusinessServiceLineId, CanGoOffshore)
		VALUES (@WFCLientID, @BusinessServiceLine, @OffshoreBit)

		--Create Digita link
		INSERT INTO Links (LinkTypeId, ForeignId, ClientId, IsPrimaryLink, ForeignName, ForeignCode)
		VALUES (2, @BBEID, @WFCLientID, 1, @ClientName, @AtlasID)

		--Create IESClient Link
		INSERT INTO Links (LinkTypeId, ForeignId, ClientId, IsPrimaryLink, ForeignName, ForeignCode)
		VALUES (6, @AtlasID, @WFCLientID, 0, @ClientName, @AtlasID)

		--Create SAP Worksite Link
		INSERT INTO Links (LinkTypeId, ForeignId, ClientId, IsPrimaryLink, ForeignName, ForeignCode)
		VALUES (7, @MSDClientNumber, @WFCLientID, 0, @LeadClientName, @MSDClientNumber)

		--Create org unit

		--Add processing unit to client.
	END
ELSE IF (@OwnLeadClient = 1)

	BEGIN
		--Create client in Workflow
		INSERT INTO Clients (ClientName, ClientTypeId)
		VALUES (@ClientName, 1)

		--Grab workflow client ID
		SET @WFCLientID = (SELECT ClientId FROM Clients WHERE ClientName = @ClientName)

		IF (@WFCLientID IS NULL)
		BEGIN
			PRINT N'The Workflow Client ID of the supplied client is null.  This suggests the client has not been created in Workflow properly.'
			PRINT N'Terminating script.  Please setup manually.'

			SET NOEXEC ON
		END

		ELSE
		--Add client access groups
		INSERT INTO ClientAccessGroupClients (ClientAccessGroupId, ClientId)
		VALUES ( @ClientAccessGroupId , @WFClientID )

		--Set offshore restriction
		INSERT INTO ClientOSRCodes (ClientId, BusinessServiceLineId, CanGoOffshore)
		VALUES (@WFCLientID, @BusinessServiceLine, @OffshoreBit)

		--Create SAP link
		INSERT INTO Links (LinkTypeId, ForeignId, ClientId, IsPrimaryLink, ForeignName, ForeignCode)
		VALUES (1, @MSDClientNumber, @WFCLientID, 1, @LeadClientName, @MSDClientNumber)

		--Create Digita link
		INSERT INTO Links (LinkTypeId, ForeignId, ClientId, IsPrimaryLink, ForeignName, ForeignCode)
		VALUES (2, @BBEID, @WFCLientID, 0, @ClientName, @AtlasID)

		--Create IESClient Link
		INSERT INTO Links (LinkTypeId, ForeignId, ClientId, IsPrimaryLink, ForeignName, ForeignCode)
		VALUES (6, @AtlasID, @WFCLientID, 0, @ClientName, @AtlasID)

		--Create SAP Worksite Link
		INSERT INTO Links (LinkTypeId, ForeignId, ClientId, IsPrimaryLink, ForeignName, ForeignCode)
		VALUES (7, @MSDClientNumber, @WFCLientID, 0, @LeadClientName, @MSDClientNumber)

		--Create org unit

		--Add processing unit to client.
	END

ELSE IF (@OwnLeadClient = 2)
	BEGIN
		PRINT N'You should seek advice before setting this particular client up'
		
		SET NOEXEC ON
	END
ELSE
	BEGIN
		PRINT N'You have made an error.  Please check yuour values.'

		SET NOEXEC ON
	END

END TRY

BEGIN CATCH  
    SELECT   
        ERROR_NUMBER() AS ErrorNumber  
        ,ERROR_SEVERITY() AS ErrorSeverity  
        ,ERROR_STATE() AS ErrorState  
        ,ERROR_PROCEDURE() AS ErrorProcedure  
        ,ERROR_LINE() AS ErrorLine  
        ,ERROR_MESSAGE() AS ErrorMessage;  
    IF @@TRANCOUNT > 0  
        ROLLBACK TRANSACTION;  
END CATCH;  

IF @@TRANCOUNT > 0  
    COMMIT TRANSACTION;
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED;    
GO


