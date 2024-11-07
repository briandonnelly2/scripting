/**
661054 - 9F66A0E8-07FD-4E35-B1DE-00A8B193269A - doubler
PracticeManagement
==================
ClientGroup Table
------------------
ClientGroupID							Name
-------------							----
15FAACCB-EDBC-4C36-9B7A-9EBA2703D4EA	IES HOPS Off
89F6A1AC-C31E-40A6-A4AB-936572ADAF55	IES HOPS UK
14AC79DF-25FE-4212-9223-681104FA4179	IES Offshore
132C0767-1997-4D45-9994-9DEF49B3DA8E	IES UK
F9DD3D47-5E95-439F-B8F6-CEE2CBE1267B	PCC Offshore
7238B024-0AF3-44BA-85B5-7BDE668F1B36	PCC UK
68FF4486-5C46-456D-9A29-0F11180FCBEC	Restricted
8919E018-70C5-418D-8BCD-03621741332E	SBA UK
**/

USE [PracticeManagementCoE_Staging]

SET NOEXEC OFF

GO

DECLARE @DigitaRefCode NVARCHAR(100) = '661054' --Digita Refcode

DECLARE @IESHOPSOff NVARCHAR(100) = '15FAACCB-EDBC-4C36-9B7A-9EBA2703D4EA'
DECLARE @IESHOPSUK NVARCHAR(100) = '89F6A1AC-C31E-40A6-A4AB-936572ADAF55'
DECLARE @IESOffshore NVARCHAR(100) = '14AC79DF-25FE-4212-9223-681104FA4179'
DECLARE @IESUK NVARCHAR(100) = '132C0767-1997-4D45-9994-9DEF49B3DA8E'
DECLARE @PCCOffshore NVARCHAR(100) = 'F9DD3D47-5E95-439F-B8F6-CEE2CBE1267B'
DECLARE @PCCUK NVARCHAR(100) = '7238B024-0AF3-44BA-85B5-7BDE668F1B36'
DECLARE @Restricted NVARCHAR(100) = '68FF4486-5C46-456D-9A29-0F11180FCBEC'
DECLARE @SBAUK NVARCHAR(100) = '8919E018-70C5-418D-8BCD-03621741332E'

DECLARE @BillableEntityID NVARCHAR(100) = (SELECT BillableEntityID FROM BillableEntity WHERE ClientCode = @DigitaRefCode)
DECLARE @DPMAccessGroupCount INT = 0
SELECT * FROM ClientGroupBillableEntity WHERE @BillableEntityID = @BillableEntityID

SET @DPMAccessGroupCount = (SELECT COUNT(ClientGroupID) FROM ClientGroup WHERE @BillableEntityID = @BillableEntityID)

BEGIN TRANSACTION;

SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

SET XACT_ABORT ON;

BEGIN TRY

IF(@BillableEntityID IS NULL)
	BEGIN
		PRINT N'A client with this refcode does not exist: ' + @DigitaRefCode
		SET NOEXEC ON
	END

ELSE IF((@BillableEntityID IS NOT NULL) AND (@DPMAccessGroupCount = 0))
	BEGIN
		PRINT N'We did not find a mapping for this particular client code ' + @DigitaRefCode
		PRINT N'Adding new access group to the client with a Digita Ref code of ' + @DigitaRefCode
		INSERT INTO ClientGroupBillableEntity (ClientGroupID, BillableEntityID)
		VALUES (@IESOffshore, @BillableEntityID) --IMPORTANT: Change the first value to the client access group we are changing to
	END

ELSE IF((@BillableEntityID IS NOT NULL) AND (@DPMAccessGroupCount = 1))
	BEGIN
		PRINT N'Updating access group to the client with a Digita Ref code of ' + @DigitaRefCode
		UPDATE ClientGroupBillableEntity
		SET ClientGroupID = @IESOffshore --IMPORTANT: Change the first value to the client access group we are changing to
		WHERE BillableEntityID = @BillableEntityID
	END

ELSE
	BEGIN
		PRINT N'Removing access groups from client with a Digita Ref code of ' + @DigitaRefCode
		DELETE FROM ClientGroupBillableEntity WHERE BillableEntityID = @BillableEntityID

		PRINT N'Adding new access group to the client with a Digita Ref code of ' + @DigitaRefCode
		INSERT INTO ClientGroupBillableEntity (ClientGroupID, BillableEntityID)
		VALUES (@IESOffshore, @BillableEntityID) --IMPORTANT: Change the first value to the client access group we are changing to
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

