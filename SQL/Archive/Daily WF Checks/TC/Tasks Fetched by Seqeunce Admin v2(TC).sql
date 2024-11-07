/**
	This script finds any tasks that have been fetched by the sequence admin windows service.
	This often indicates no one is configured to receive the task.  
	These need to be debugged and investigated using the process instance ID.
**/

USE [Sequence]

;with activities As
(
select fldIActId from tblActionItems where fldIActId in(

select fldIActId from tblActionItems where fldToId = 5349 and 
fldMessageType = 2 and fldCreationDate < DATEADD(MINUTE, -10, GETDATE()) 
)
group by fldIActId
having COUNT(fldId) = 1 
)

select 
	iw.fldid [Process Instance ID], 
	tw.fldAlias,
	ai.fldid [Message Instance ID],
	'http://taxworkflowportal:8080/_layouts/runTime.aspx?messageInstanceId=' + CONVERT(NVARCHAR(255), ai.fldid) [TaskURL],  
	ai.fldSubject,
	ai.fldToId [Task Recipient ID],
	ai.fldCreationDate,
	iw.fldCreationDate, 
	iw.fldLastUpdated, 
	iw.fldStatus, 
	iw.fldPending
from tblinstanceworkflows iw
LEFT JOIN tblTemplateWorkflows tw on iw.fldTemplateWfGuid = tw.fldguid
RIGHT JOIN tblactionitems ai on iw.fldid = ai.fldiwfid
JOIn activities a on a.fldIActId = ai.fldIActId
WHERE ai.fldCompletionDate IS NULL
AND ai.fldMessageType = 2
AND iw.fldstatus = 2