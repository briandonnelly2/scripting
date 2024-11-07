/**
	This script finds any tasks that have stalled for some reason and automatically moves them on.
	Occassionally you will see a deadlock error when you run this.  It simply means some other process
	has tried to access a table before you, simply rerun the script and it should work.
**/

USE [SequencePA]

;WITH Stalledprocesses AS (
SELECT * FROM 
(
	SELECT iw.fldid
		   ,MAX(tw.fldname) as WorkflowName
		   ,Max(ta.fldAlias) as StalledActivity
		   ,MAX(iw.fldLastRedirectDate) as LastRedirectDate
		   ,MAX(iw.fldNextRedirectDate) as NextRedirectDate
		   ,MAX(ia.fldTemplateActivityGuid) as ActivityGuid
	
	FROM tblinstanceactivities ia

	inner join tbltemplateactivities ta on ta.fldguid = ia.fldtemplateactivityguid
	inner join tblinstanceworkflows iw on iw.fldid = ia.fldinstancewfid
	inner join tbltemplateworkflows tw on tw.fldguid = iw.fldtemplatewfguid
	where 
	iw.fldstatus not in (7)
	and iw.fldCompletionDate is null
	and
	((
	ta.fldtype = '248AFD02-F0B9-423A-89F5-9EB5A1C4E08A'
	and ia.fldstatus = 3
	and iw.fldnextredirectdate < DATEADD(hh,-24,GETDATE()))
	--update line below with activityid for any we need to exclude
	and ia.fldTemplateActivityGuid not in (
	'FDEEF930-E417-4090-93C8-15DBA04A9477', 
	'BAD3E9C0-44DB-4D05-BB3F-69D159BADF54', 
	'6148DCFB-56AC-44E1-AA4F-017450F5B772',
	'7fe6eab0-2b73-4f70-8126-942924a28e80',
	'654530c0-917d-40ea-95b0-00f07b51bff8',
	'801e55b8-dd8e-4963-a10e-72e540ed3f7c',
	'dd1f09de-e98e-4d35-8995-82d5d793109c',
	'8e3dc8bc-36c6-4c75-b4be-f4dc5d944cda',
	'960c8b33-a201-406d-98fd-be689c3fda5f',
	'7dfcae03-3076-4303-8ce2-e69661027f55',
	'083c256c-01f3-4929-856c-d99d13ecae4a',
	'027931a6-ab53-4743-8ac9-3781c95d9a22',
	'BD00F5B7-320A-42D7-8AD2-DC5A3789A3EB'
	)
	or
	(
	ta.fldtype = 'D4A04280-13C1-4893-8ACE-9800C60EB86B'
	and ia.fldstatus IN (0,2,3) and ia.fldCompletionDate is null)
)
group by iw.fldid, ta.fldAlias) d
WHERE StalledActivity <> 'Refresh Variables' and StalledActivity <> 'Check how long since last update' and StalledActivity <>  'Refresh Variable'
)

update tblInstanceWorkflows
set fldNextRedirectDate = DATEADD(minute, 1, GETDATE())
where fldId in (select fldid from StalledProcesses)