/**
	Finds and automatically fixes stalled milestone processes.
**/

USE [Sequence]

UPDATE tblInstanceWorkflows
SET fldNextRedirectDate = GETDATE()
WHERE fldId in (
	SELECT fldInstanceWfId

	FROM tblInstanceActivities ia

	INNER JOIN tblInstanceWorkflows iw ON ia.fldInstanceWfId = iw.fldId AND iw.fldNextRedirectDate < DATEADD(HH, -1, GETDATE()) 

	WHERE ia.fldTemplateActivityGuid ='BA58FC07-D502-470A-98AD-ED042269096C' --Put On BRS
	AND ia.fldCompletionDate IS NULL
)
