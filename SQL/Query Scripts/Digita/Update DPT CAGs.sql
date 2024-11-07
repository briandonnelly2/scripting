USE [TaxywinCOE_Staging]

SET NOEXEC OFF

GO

DECLARE @DigitaRefCode NVARCHAR(100) = '661054' --Digita Refcode

DECLARE @AllStaff NVARCHAR(100) = 'All Staff'
DECLARE @IESHOPSOff NVARCHAR(100) = 'IES HOPS Off'
DECLARE @IESHOPSUK NVARCHAR(100) = 'IES HOPS UK'
DECLARE @IESOffshore NVARCHAR(100) = 'IES Offshore'
DECLARE @IESUK NVARCHAR(100) = 'IES UK'
DECLARE @NoClients NVARCHAR(100) = 'No Clients'
DECLARE @PCCOffshore NVARCHAR(100) = 'PCC Offshore'
DECLARE @PCCUK NVARCHAR(100) = 'PCC UK'
DECLARE @SBAUK NVARCHAR(100) = 'SBA UK'

DECLARE @BillableEntityID NVARCHAR(100) = (SELECT BillableEntityID FROM [PracticeManagementCoE_Staging].[dbo].[BillableEntity] WHERE ClientCode = @DigitaRefCode)
DECLARE @DPTClientCode NVARCHAR(100) = (SELECT CLIENTID FROM Client WHERE EntityId = @BillableEntityID)
DECLARE @DPTAccessGroupCount INT = 0

SET @DPTAccessGroupCount = (SELECT COUNT(GroupId) FROM [TaxywinCOE_Staging].[dbo].[GroupClient] WHERE Clientid = @DPTClientCode)

BEGIN TRANSACTION;

SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

SET XACT_ABORT ON;

BEGIN TRY

IF(@DPTClientCode IS NULL)
	BEGIN
		PRINT N'A client with this refcode does not exist: ' + @DigitaRefCode
		SET NOEXEC ON
	END

ELSE IF((@DPTClientCode IS NOT NULL) AND (@DPTAccessGroupCount = 0))
	BEGIN
		PRINT N'We did not find a mapping for this particular client code ' + @DigitaRefCode
		PRINT N'Adding new access group to the client with a Digita Ref code of ' + @DigitaRefCode
		INSERT INTO GroupClient (ClientID, GroupID)
		VALUES (@DPTClientCode, @IESOffshore) --IMPORTANT: Change the first value to the client access group we are changing to
	END

ELSE IF((@DPTClientCode IS NOT NULL) AND (@DPTAccessGroupCount = 1))
	BEGIN
		PRINT N'Updating access group to the client with a Digita Ref code of ' + @DigitaRefCode
		UPDATE GroupClient
		SET GroupID = @IESOffshore --IMPORTANT: Change the first value to the client access group we are changing to
		WHERE ClientID = @DPTClientCode
	END

ELSE
	BEGIN
		PRINT N'Removing access groups from client with a Digita Ref code of ' + @DigitaRefCode
		DELETE FROM GroupClient WHERE ClientID = @DPTClientCode

		PRINT N'Adding new access group to the client with a Digita Ref code of ' + @DigitaRefCode
		INSERT INTO GroupClient (ClientID, GroupID)
		VALUES (@DPTClientCode, @IESOffshore) --IMPORTANT: Change the first value to the client access group we are changing to
	END
PRINT N'Update complete.';

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