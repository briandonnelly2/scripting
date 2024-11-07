/**
	Finds any workflows that have stalled matching the criteria below and automatically moves them on.
**/

USE [SequencePA]

UPDATE
	tblInstanceWorkflows
SET
	fldNextRedirectDate = GETDATE()
WHERE
	fldId in (
SELECT 
	fldInstanceWfId
FROM 
	tblInstanceActivities ia
JOIN
	tblInstanceWorkflows iw on ia.fldInstanceWfId = iw.fldId and iw.fldNextRedirectDate < DATEADD(HH, -1, GETDATE()) 
WHERE
	ia.fldTemplateActivityGuid ='BA58FC07-D502-470A-98AD-ED042269096C'--Put On BRS
AND
	ia.fldCompletionDate IS NULL
)
