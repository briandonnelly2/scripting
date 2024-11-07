USE [Sequence]

DECLARE @ActivityId INT = xxx
DECLARE @WorkflowId INT = xxx

BEGIN TRAN

UPDATE tblInstanceActivities
SET fldStatus = 5, fldCompletionDate = GETDATE(), fldRedirectFlag = 1
WHERE fldId = @ActivityId

SELECT fldStatus, fldCompletionDate, fldRedirectFlag FROM tblInstanceActivities WHERE fldId = @ActivityId

UPDATE tblInstanceWorkflows 
SET fldNextRedirectDate = DATEADD(MINUTE, 2, GETDATE())
WHERE fldId = @WorkflowId

SELECT fldNextRedirectDate FROM tblInstanceWorkflows WHERE fldId = @WorkflowId

--ROLLBACK
COMMIT