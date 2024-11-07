/**
	Finds any workflows that have stalled matching the criteria below and automatically moves them on.
**/

USE [Sequence]

UPDATE tblInstanceWorkflows --update statement moves any that are found on
SET	fldNextRedirectDate = GETDATE()
WHERE fldId IN (
	SELECT fldInstanceWfId --Gets the workflow id
	
	FROM tblInstanceActivities ia --from the instance activities table
	
	INNER JOIN tblInstanceWorkflows iw ON ia.fldInstanceWfId = iw.fldId --Joins in the relevant matching workflow...
	AND iw.fldNextRedirectDate < DATEADD(HH, -1, GETDATE()) --...only if the last redirect date is in the past.

	WHERE ia.fldTemplateActivityGuid ='e1b9b87e-cae8-4645-8b6a-84c43a83c171' --Only checks activities matching Set Active Flag...
	AND ia.fldCompletionDate IS NULL --...and have no completion date...
	AND iw.fldStatus = 2 --...and the workflow status is pending
)
