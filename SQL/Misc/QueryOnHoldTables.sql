USE [TaxWFPortalData]
/****** Returns useful information from the on hold tables (maybe...)  ******/
SELECT wi.[Id]
      ,wi.[OnHoldWorkItemId]
	  ,oht.[Name] AS 'OnHoldType'
	  ,uwf.Active AS 'Seq Active'
	  ,uwf.ServiceLineId AS 'Business Stream'
	  ,uwf.CreatedBy AS 'Seq CreatedBy'
	  ,uwf.Notes AS 'Seq Notes'
	  ,uwf.OnHoldDate AS 'Seq OnHoldDate'
	  ,uwf.OnHoldId AS 'Seq OnHoldId'
	  ,cl.ClientName AS 'WorkItemClient'
	  ,cl2.ClientName AS 'PeriodClient'
	  ,wt.TypeId
	  ,oht.[Name]
	  ,oht.CanBeSelected
	  ,oht.AvailableInPortal
	  ,oht.BusinessServiceLineId
	  ,oht.ParentId
	  ,oht.RequiresDeadlineRecalculation
  FROM onHold.WorkItem wi
  
  INNER JOIN [Sequence].[dbo].[UWF73cbe5a4529e4fe792880b39def644db] AS uwf WITH (NOLOCK) ON uwf.WorkItemId = wi.OnHoldWorkItemId
  INNER JOIN onhold.[Type] oht ON uwf.OnHoldTypeId = oht.Id
  INNER JOIN Clients cl ON cl.ClientId = uwf.WorkItemClientId
  INNER JOIN Clients cl2 ON cl2.ClientId = uwf.PeriodClientId

  INNER JOIN onhold.WorkItemType wt ON wi.Id = wt.WorkItemId
  INNER JOIN onhold.WorkItemTypeInstance wti ON wt.Id = wti.WorkItemTypeId

  --WHERE uwf.OnHoldId = '11f1ddbf-b79a-410a-bbc1-ba7cfc4179db'
  --WHERE oht.[Name] = 'Partnership'
  WHERE wi.OnHoldWorkItemId = '303388'