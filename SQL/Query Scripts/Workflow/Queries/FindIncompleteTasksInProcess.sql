USE [Sequence]

--Main process ID
DECLARE @MainProcessID INT = 9053949

--Template GUID of the actvity you want to locate
DECLARE @TemplateGUID NVARCHAR(100) ='5429F41D-1087-43A3-A4E8-B2C47FBBB59C'

--Status of the task you are searching for
DECLARE @StatusCode TINYINT = 2

SELECT ia.[fldId]
      ,ia.[fldTemplateActivityGuid]
      ,ia.[fldInstanceWfId]
      ,ia.[fldSourceActId]
      ,case ia.fldStatus
			when 0 then 'Created'
			when 1 then 'Executing'
			when 2 then 'Idle'
			when 3 then 'Completed'
			when 4 then 'Deleting'
			when 5 then 'Deleted'
			when 6 then 'Aborting'
			when 7 then 'Aborted'
			else 'n/a'
			end as [Status]
	  ,ia.[fldCreationDate]
	  ,ia.[fldCompletionDate]
	  ,ta.fldName
	  ,ta.fldAlias
	FROM [Sequence].[dbo].[tblInstanceActivities] AS ia

	INNER JOIN [Sequence].[dbo].[tblTemplateActivities] AS ta ON ia.[fldTemplateActivityGuid] = ta.fldGuid

	WHERE ia.fldInstanceWfId = @MainProcessID --AND ia.fldCompletionDate IS NULL

	--WHERE ia.fldTemplateActivityGuid = @TemplateGUID AND ia.fldStatus = @StatusCode AND ia.fldCompletionDate IS NULL

	ORDER BY ia.fldInstanceWfId