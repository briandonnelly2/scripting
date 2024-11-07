USE [Sequence]

--Enter the main process ID to see all activities for the process
DECLARE @MainProcessID INT = 9694003
DECLARE @SubWFActivityID INT = 327521037 

SELECT ia.[fldId]
      ,ia.[fldTemplateActivityGuid]
      ,ia.[fldInstanceWfId]
      ,ia.[fldSourceActId]
      ,case ia.[fldStatus]
			when 0 then 'Created'
			--when 1 then 'Executing'
			when 2 then 'Pending'
			when 3 then 'Executed'
			when 4 then 'Redirected'
			when 5 then 'Completed'
			when 6 then 'Deleted'
			when 7 then 'Rolled Back'
			else 'n/a'
			end AS [Status]
	  ,ta.[fldName]
	  ,ta.[fldAlias]
      ,ia.[fldCreationDate]
      ,ia.[fldLastUpdateDate]
      ,ia.[fldCompletionDate]
      ,ia.[fldRedirectFlag]
  FROM tblInstanceActivities AS ia

  INNER JOIN tblTemplateActivities AS ta ON ia.[fldTemplateActivityGuid] = ta.[fldGuid]

  WHERE ia.[fldInstanceWfId] = @MainProcessID
  --WHERE ia.fldSourceActId = 327521037
  --AND fldCompletionDate IS NULL

  ORDER BY ia.[fldCreationDate]

 -- BEGIN TRAN
	--UPDATE tblInstanceActivities
	--SET  fldCompletionDate = GETDATE()
	--	,fldRedirectFlag = 1
	--	,fldStatus = 5
	--WHERE ia.fldSourceActId = 