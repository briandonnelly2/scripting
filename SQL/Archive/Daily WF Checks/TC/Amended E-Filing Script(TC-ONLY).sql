/**
	Finds any workflows that have stalled due to the last checked efiling response received date is in the past.
	Run the query first with @PerformUpdate set to 0.  If any colums are returned, change this to 1 and execute again.
	Change back to 0 and rerun after 5-10 minutes.  The tasks should have moved on.
**/

USE [Sequence]

SET NOEXEC OFF

DECLARE @PerformUpdate INT = 0
--DECLARE @EFilingResponseReceived DATETIME
--DECLARE @NumberStalled INT
--DECLARE @EFileDate DATETIME

--;WITH EFilingIssues AS (
SELECT	 iw.fldId AS 'WorkflowInstanceId'
		,iw.fldNextRedirectDate AS 'NextRedirectDate' --Add 5 minutes to this date
		,iw.fldLastRedirectDate AS 'LastRedirectDate'
		,es.Updated AS 'LastUpdatedFromKPMGLink'
		,v.TempGTSID AS 'AsigneeGTSID'
		,v.TempGTSIDClient AS 'ClientGTSID'
		,v.WorkItemYear AS 'TaxYear'
		,es.ProjectType AS 'ProjectType'
		,v.WorkItemId AS 'WorkItemID'
		,es.Updated AS 'EFilingResponseReceived'
		,es.[Timestamp] AS 'EFilingResponseProcessed'
		,es.Response AS 'EFilingResponse'
		,v.LastCheckedEFilingResponseReceived AS 'SeqResponseRecived' --Update this value with the value of es.Updated
		,es.irmark AS 'IRMARK'
	
	FROM tblInstanceActivities AS ia --queries instance activities table

	INNER JOIN UWF9f16250dd2be404b9bf0f09c2fe2cba6 AS v ON ia.fldInstanceWfId = v.fldIWfId --join to a variable table matching the associted workflow for the activity.

	RIGHT JOIN TAX_Atlas_KPMGLink..EFilingStatus AS es ON v.TempGTSID = es.AssigneeGTSID --Joins to the link database and only returns entries that have a matching GTS ID from the Link database
	AND v.WorkItemYear = es.TaxYear --and a matching tax year
	AND es.ProjectType = v.EfilingStatusProjectType --and a matching project type
	
	INNER JOIN tblInstanceWorkflows iw on v.fldIWfId = iw.fldId

	WHERE ia.fldCompletionDate IS NULL
	AND ia.fldTemplateActivityGuid = '083C256C-01F3-4929-856C-D99D13ECAE4A' --Has Efile Response been Received
--)

--SELECT @NumberStalled = (SELECT COUNT(*) FROM EFilingIssues)

--SET @EFileDate = (SELECT EFilingResponseReceived FROM EFilingIssues)

--PRINT @NumberStalled
--PRINT @EFileDate

--IF (@PerformUpdate = 0)
--	BEGIN	
--		PRINT N'If any processes '
--	END

--ELSE IF (@PerformUpdate = 1)
--	BEGIN
--		PRINT N'Updating Workitem....'

--		UPDATE UWF9f16250dd2be404b9bf0f09c2fe2cba6
--		SET LastCheckedEFilingResponseReceived = 

--DECLARE @InstanceId INT = 9756118
--DECLARE @EFilingResponseReceived DATETIME = '2020-01-07 05:38:02.000'

--BEGIN TRAN

--	UPDATE UWF9f16250dd2be404b9bf0f09c2fe2cba6 
--	SET LastCheckedEFilingResponseReceived = DATEADD(MINUTE, -2, @EFilingResponseReceived) 
--	WHERE fldiwfid = @InstanceId

--	SELECT LastCheckedEFilingResponseReceived 
--	FROM UWF9f16250dd2be404b9bf0f09c2fe2cba6 
--	WHERE fldiwfid = @InstanceId

--	UPDATE tblInstanceWorkflows
--	SET fldNextRedirectDate = DATEADD(MINUTE, 5, GETDATE())
--	WHERE fldId = @InstanceId

--	SELECT fldNextRedirectDate 
--	FROM tblInstanceWorkflows 
--	WHERE fldId = @InstanceId

----ROLLBACK
--COMMIT
