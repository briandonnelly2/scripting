/**
	Given an opportunity ID and tax year, this script will pull back milestone information for PCC clients.
	This will give the workflow timestamps for info recieved, sent to prep, sent to client and completion date.
	Requested gby Aimee Elsby on TASK0132388 for the Osborne Clarke partnership
**/

USE [TaxWFPortalData]

DECLARE @OpportunityID INT = '70098351' --Opportunity number from SAP
DECLARE @TaxYear INT = '2019' --The tax year the info is required for

SELECT   e.[OpportunityId] AS [Opp Number]
		,p.[TaxYearId] AS [Tax Year]
		,wi.WorkItemId AS [Workitem ID]
		,c.ClientName AS [Partner Name]
		,l.ForeignCode AS [Client Code]
		,msinfo.ChangedOn AS [Info Received]
		,msprep.ChangedOn AS [Sent for Prep]
		,msstc.ChangedOn AS [Sent to Client]
		,wi.CompletedDate AS [Date Completed]

FROM [Engagements] AS e

INNER JOIN [Periods] AS p ON p.[EngagementId] = e.[EngagementId]
INNER JOIN [ClientPeriods] AS cp ON cp.[PeriodId] = p.[PeriodId]
INNER JOIN [Clients] AS c ON c.ClientId = cp.ClientId
INNER JOIN [Links] AS l ON l.ClientId = c.ClientId AND l.LinkTypeId = 2
INNER JOIN WorkItems AS wi ON wi.ClientPeriodId = cp.ClientPeriodId
LEFT JOIN WorkItemMilestoneChange AS msinfo ON msinfo.WorkItemId = wi.WorkItemId AND msinfo.WorkItemMilestoneTypeId = 10 --Complete information received
LEFT JOIN WorkItemMilestoneChange AS msprep ON msprep.WorkItemId = wi.WorkItemId AND msprep.WorkItemMilestoneTypeId IN (43,11) --Ready for preparation, Sent Offshore for preparation
LEFT JOIN WorkItemMilestoneChange AS msstc ON msstc.WorkItemId = wi.WorkItemId AND msstc.WorkItemMilestoneTypeId IN (26,339) --Sent via other method, Sent to client (Client Portal)



WHERE OpportunityId = @OpportunityID
AND p.[TaxYearId] = @TaxYear
AND wi.WorkItemTypeId = 2 --PCC

ORDER BY [Partner Name]