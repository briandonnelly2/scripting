/******  ******/
USE TaxWFPortalData

DECLARE @ClientName NVARCHAR(100) = 'Chevron'

SELECT cl.ClientId
      ,cl.ClientName
	  ,cl1.ClientName AS 'LeadClientName'
	  --,e.OpportunityId
	  --,e.EngagementId
	  --,e.SequenceInstanceId AS 'Engagement SeqInstID'
	  ,sl.Description AS 'ServiceLine'
	  ,e.Description AS 'EngagementName'
	  ,p.PeriodId
	  --,p.SequenceInstanceId AS 'Period SeqInstID'
	  ,p.PeriodStartDate AS 'Start Date'
	  ,p.PeriodEndDate AS 'End Date'
	  ,p.TaxYearId AS 'Tax Year'
	  ,cp.Description AS 'CP Name'
	  ,cp.ClientPeriodId
	  --,cp.SequenceInstanceId AS 'CP SeqInstID'
	  --,wi.WorkItemId
	  --,wi.SequenceInstanceId AS 'WI SeqInstID'
	  ,wis.Name AS 'WI State'
	  ,wmt.OverriddenDescription AS 'Milestone'
	  ,wst.Description AS 'State'
	  ,sst.Name AS 'Stage'


FROM Clients AS cl

INNER JOIN ClientPeriods AS cp ON cl.ClientId = cp.ClientId
INNER JOIN [Periods] AS p ON cp.PeriodId = p.PeriodId
INNER JOIN Engagements AS e ON p.EngagementId = e.EngagementId
INNER JOIN BusinessServiceLine AS sl ON e.BusinessServiceLineId = sl.BusinessServiceLineId
INNER JOIN Clients AS cl1 ON e.LeadClientId = cl1.ClientId
INNER JOIN WorkItems AS wi ON cp.ClientPeriodId = wi.ClientPeriodId
FULL JOIN WorkItemState AS wis ON wi.WorkItemStateId = wis.Id
FULL JOIN WorkItemTypeMilestoneType AS wmt ON wi.WorkItemMilestoneTypeId = wmt.WorkItemMilestoneTypeId
FULL JOIN WorkItemSubType AS wst ON wi.WorkItemSubTypeId = wst.Id
FULL JOIN WorkItemSubStateType AS sst ON wi.WorkItemSubStateTypeId = sst.Id

WHERE cl.ClientName LIKE '%' + @ClientName + '%' --AND wi.WorkItemStateId = 1