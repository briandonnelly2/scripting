USE [Sequence]

DECLARE @WorkflowInstanceId int = x

DELETE FROM
	tblActionItems
WHERE 
	fldId in (

	SELECT
		ai.fldId
	FROM
		tblInstanceWorkflows iw
	JOIN
		tblInstanceActivities ia on iw.fldId = ia.fldInstanceWfId
	JOIN
		tblActionItems ai on ia.fldId = ai.fldIActId
	WHERE
		iw.fldId = @WorkflowInstanceId 
	AND
		ia.fldCompletionDate IS NOT NULL
	AND
		ai.fldCompletionDate IS NULL
)