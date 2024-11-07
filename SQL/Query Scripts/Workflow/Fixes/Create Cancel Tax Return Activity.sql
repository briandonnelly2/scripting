USE [Sequence]

SET NOEXEC OFF

DECLARE @MainProcessID INT = 9677398 --he main process ID
DECLARE @SetProcOfficeGUID NVARCHAR(100) = '8E7D182B-FCD1-4072-A08D-A9E2B3CF8E78' --Set Processing Office Activity (This generates the cancel tax return activity)
DECLARE @CancelTaxReturnGUID NVARCHAR(100) = 'DF052D34-5F1D-4386-ABD4-9431353B2C32' --Cancel Tax Return Activity
DECLARE @SPOActivityID INT
DECLARE @CTRActivityID INT


SET @SPOActivityID = (SELECT fldid FROM tblInstanceActivities WHERE fldInstanceWFID = @MainProcessID AND fldTemplateActivityGuid = @SetProcOfficeGUID)
SET @CTRActivityID = (SELECT fldid FROM tblInstanceActivities WHERE fldInstanceWFID = @MainProcessID AND fldTemplateActivityGuid = @CancelTaxReturnGUID)

IF(@CTRActivityID IS NOT NULL)
	BEGIN
		PRINT N'The cancel tax return activity already exists for this workitem.'
		PRINT N'Terminating script'
		SET NOEXEC ON
	END
ELSE
	BEGIN
		PRINT N'The cancel tax return activity does not exist for this workitem.'
		PRINT N'Updating the activities table...'

		UPDATE tblInstanceActivities
		SET fldStatus = 3, fldCompletionDate = NULL, fldRedirectFlag = 1
		WHERE fldTemplateActivityGUID = @SetProcOfficeGUID AND fldid = @SPOActivityID

		PRINT N'Complete!'
		PRINT N'Updating workflows table...'

		UPDATE tblInstanceWorkflows
		SET fldNextRedirectDate = DATEADD(minute, 2, GETDATE())
		WHERE fldid = @MainProcessID

		PRINT N'Complete!'
		PRINT N'Please allow a few minutes to pass before trying to cancel the workitem again.'
	END