begin transaction
DECLARE @WorkflowInstanceId int = 9684543

UPDATE tblInstanceActivities 
SET fldCompletionDate = NULL, 
	fldStatus = 3, 
	fldRedirectFlag = 1
WHERE fldInstanceWfId = @WorkflowInstanceId and fldTemplateActivityGuid = '22549A4F-0B23-4E54-9A29-D8018062C23E'

rollback
commit


--Status 	Value 	Description 
--Created 	0 	The workflow instance was created. 
--Executing 	1 	The workflow instance waits to resume its execution. 
--Idle 	2 	The workflow instance finished its execution and waits for user\system input. 
--Completed 	3 	The workflow instance was completed. 
--Deleting 	4 	The workflow instance deletion process has started. 
--Deleted 	5 	The workflow instance deletion process has finished. 
--Aborting 	6 	The workflow instance abort process has started. 
--Aborted 	7 	The workflow instance was aborted. 
