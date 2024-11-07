/* ------------------------------------------------------------------------------- */
/* REQUIRED:																	   */
/* No Inputs																	   */
/* Pulls back all the active process with multiple active tasks					   */
/*																				   */
/* ------------------------------------------------------------------------------- */

USE [Sequence]

SELECT TOP 10 fldInstanceWfId
INTO #tmpInstanceActivities
FROM tblInstanceActivities a
JOIN tblInstanceWorkflows w ON a.fldInstanceWfId = w.fldId
WHERE a.fldStatus = 2
AND w.fldStatus = 2
AND a.fldTemplateActivityGuid IN
								(
								SELECT top 2000 fldGuid
								FROM tblTemplateActivities
								WHERE fldType IN (SELECT DISTINCT(fldGuid) FROM tblActivityTypes WHERE fldType LIKE '%Task%')
								--Excluded tasks due to having multiple instances by design
								AND fldGuid NOT IN ('d86afe1d-125f-4f0f-adba-1bb94ebc34b2') 
								 )
GROUP BY  fldInstanceWfId
HAVING COUNT(*) > 1

Select i.fldId AS 'Activity Instance ID'
, i.fldInstanceWfId AS 'Workflow Instance ID'
, t.fldAlias AS 'Task Name'
, i.fldTemplateActivityGuid AS 'Activity Guid'
, w.fldName AS 'Workflow Process Name'
FROM tblInstanceActivities i
LEFT JOIN tblTemplateActivities t ON t.fldGuid = i.fldTemplateActivityGuid
LEFT JOIN tblTemplateWorkflows w ON t.fldTWfGuid = w.fldGuid
WHERE i.fldInstanceWfId IN (SELECT tmp.fldInstanceWfId FROM #tmpInstanceActivities tmp) 
AND i.fldStatus = 2 
AND i.fldTemplateActivityGuid IN
								(
								SELECT top 2000 fldGuid
								FROM tblTemplateActivities
								WHERE fldType IN (SELECT DISTINCT(fldGuid) FROM tblActivityTypes WHERE fldType LIKE '%Task%')
								--Excluded tasks due to having multiple instances by design
								AND fldGuid NOT IN ('d86afe1d-125f-4f0f-adba-1bb94ebc34b2') 
								 )
								 
DROP TABLE #tmpInstanceActivities