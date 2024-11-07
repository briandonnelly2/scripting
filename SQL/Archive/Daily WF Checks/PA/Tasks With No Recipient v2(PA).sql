/**
	Returns a list of tasks that have no recipient.
	These need to be debugged and inestigated.  
	Often no one has been confirgured to recive the task.

**/

USE [SequencePA]

SELECT	tw.fldAlias AS 'WorkflowAlias',
		ia.fldInstanceWfId AS 'WorkflowInstanceId',
		ta.fldName AS 'TaskName',
		ta.fldGuid,
		ia.fldCreationDate

FROM	tblInstanceActivities AS ia WITH (NOLOCK)

		INNER JOIN tblTemplateActivities ta WITH (NOLOCK) on ia.fldTemplateActivityGuid = ta.fldGuid AND fldType = '1B60824B-51E5-4B55-AC28-AA7B7A60DF90'

		INNER JOIN tblInstanceWorkflows iw WITH (NOLOCK) ON ia.fldInstanceWfId = iw.fldid AND iw.fldStatus NOT IN (3,4,5,6,7)

		INNER JOIN tblTemplateWorkflows tw WITH (NOLOCK) ON iw.fldTemplateWfGuid = tw.fldGuid

		LEFT JOIN tblActionItems ai WITH (NOLOCK) ON ia.fldid = ai.fldIActId

WHERE	ia.fldCompletionDate IS NULL

		AND ai.fldId IS NULL 
		AND ia.fldstatus NOT IN (6,7) /*Excluding the deleted (6) and rolledback activities (7)*/
		AND ia.fldTemplateActivityGuid NOT IN	(
													'4E8A1BEB-2E2F-4B78-983F-3E1BE160B4F2' --Validate Return for Efiling
												)
		AND ia.fldCreationDate >= '2019-01-01'

ORDER BY 1,3,2