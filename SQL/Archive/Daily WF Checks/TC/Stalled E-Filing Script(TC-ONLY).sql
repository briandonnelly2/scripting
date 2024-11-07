/** 
	Find workflows that have an incomplete business rule and no active task recipients where the next redirect date is in the past
	Automatically moves these on for you.
**/
USE [Sequence]

;WITH StalledEFiling AS (
	SELECT iw.[fldid] AS 'InstanceId'
		,tw.fldName AS 'WorkflowName'
		,iw.fldLastRedirectDate AS 'LastRedirectDate'
		,iw.fldNextRedirectDate AS 'NextRedirectDate'
		,ta.fldAlias AS 'ActivityName'
		,wi.[Description]
		,efs.Response
		,efs.Updated
		,efs.ProjectType
	FROM tblinstanceworkflows iw WITH (NOLOCK)
	INNER JOIN tbltemplateworkflows tw WITH (NOLOCK) ON iw.fldtemplatewfguid = tw.fldguid
	INNER JOIN tblInstanceActivities ia WITH (NOLOCK) ON ia.fldInstanceWfId = iw.fldid
	INNER JOIN tblTemplateActivities ta WITH (NOLOCK) ON ta.fldGuid = ia.fldTemplateActivityGuid
	INNER JOIN TaxWFPortalData..Workitems wi WITH (NOLOCK) ON wi.SequenceInstanceId = iw.fldid
	INNER JOIN TaxWFPortalData..ClientPeriods cp WITH (NOLOCK) ON cp.ClientPeriodId = wi.clientperiodid
	INNER JOIN TaxWFPortalData..[periods] p WITH (NOLOCK) ON p.Periodid = cp.periodid
	INNER JOIN TaxWFPortalData..Links l WITH (NOLOCK) ON l.ClientId = wi.clientid and l.linktypeid = 5
	LEFT JOIN Tax_Atlas_KPMGLink..EfilingStatus efs WITH (NOLOCK) ON efs.AssigneeGTSID = l.foreignid and efs.taxyear = p.taxyearid

	WHERE iw.fldpending = ''
	AND iw.fldnextredirectdate < DATEADD(hh,-5,GETDATE())
	AND iw.fldStatus NOT IN (3, 7)
	AND ta.fldtype = '248AFD02-F0B9-423A-89F5-9EB5A1C4E08A'
	AND ia.fldstatus = 3
	AND ta.fldAlias = 'Has Efile Response been Received'
)

UPDATE tblInstanceWorkflows
SET fldNextRedirectDate = DATEADD(minute, 5, GETDATE())
WHERE fldId IN (SELECT InstanceId FROM StalledEFiling)

