USE [TaxWFPortalData]

SELECT   p.[TaxYearId] AS [Tax Year]
		,wi.WorkItemId AS [Workitem ID]
		,c.ClientName AS [Partner Name]
		,l.ForeignCode AS [Client Code]
		,ou.[Name] AS [Org Unit]
		,ou.[OrgPathDescription] AS [Org Unit Path]
		,msinfo.ChangedOn AS [Info Received]
		,msprep.ChangedOn AS [Sent for Prep]
		,msstc.ChangedOn AS [Sent to Client]
		,wi.CompletedDate AS [Date Completed]
		,ci.ComplexityCategory AS [Complexity Category]
		,ci.ComplexityDescription AS [Complexity Level]
		

FROM Clients AS c

INNER JOIN [ClientPeriods] AS cp ON cp.ClientId = c.ClientId
INNER JOIN [Periods] AS p ON p.PeriodId = cp.PeriodId
INNER JOIN WorkItems AS wi ON wi.ClientPeriodId = cp.ClientPeriodId
INNER JOIN [Links] AS l ON l.ClientId = c.ClientId AND l.LinkTypeId = 2
INNER JOIN [ClientOrgUnitLink] col ON col.ClientId = wi.ClientId AND OrgUnitId IN ('20902','100088')
INNER JOIN [OrgUnit] ou ON ou.id = col.OrgUnitId
INNER JOIN [WorkItemComplexityIndex] AS ci ON ci.WorkItemId = wi.WorkItemId
LEFT JOIN WorkItemMilestoneChange AS msinfo ON msinfo.WorkItemId = wi.WorkItemId AND msinfo.WorkItemMilestoneTypeId = 10 --Complete information received
LEFT JOIN WorkItemMilestoneChange AS msprep ON msprep.WorkItemId = wi.WorkItemId AND msprep.WorkItemMilestoneTypeId IN (43,11) --Ready for preparation, Sent Offshore for preparation
LEFT JOIN WorkItemMilestoneChange AS msstc ON msstc.WorkItemId = wi.WorkItemId AND msstc.WorkItemMilestoneTypeId IN (26,339) --Sent via other method, Sent to client (Client Portal)
 
WHERE p.TaxYearId = '2019'
AND wi.WorkItemTypeId = 2 --PCC
ORDER By c.ClientName