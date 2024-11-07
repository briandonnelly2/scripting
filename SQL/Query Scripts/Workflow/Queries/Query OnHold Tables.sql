USE [TaxWFPortalData]
/****** Returns useful information from the on hold tables (maybe...)  ******/
SELECT wi.[Id]
      ,wi.[OnHoldWorkItemId]
	  ,oht.[Name] AS 'OnHoldType'
	  ,uwf.Active AS 'Active'
	  ,uwf.CreatedBy AS 'CreatedBy'
	  ,uwf.Notes AS 'Notes'
	  ,uwf.OnHoldDate AS 'OnHoldDate'
	  ,cl.ClientName AS 'WorkItemClient'
	  ,cl2.ClientName AS 'PeriodClient'
	  ,bsl.[Description]
  FROM onHold.WorkItem wi
  
  INNER JOIN [Sequence].[dbo].[UWF73cbe5a4529e4fe792880b39def644db] AS uwf WITH (NOLOCK) ON uwf.WorkItemId = wi.OnHoldWorkItemId
  LEFT JOIN onhold.[Type] oht ON uwf.OnHoldTypeId = oht.Id
  INNER JOIN Clients cl ON cl.ClientId = uwf.WorkItemClientId
  INNER JOIN Clients cl2 ON cl2.ClientId = uwf.PeriodClientId
  INNER JOIN Links l ON l.ClientId = uwf.WorkItemClientId AND l.LinkTypeId = 2
  INNER JOIN BusinessServiceLine bsl ON bsl.BusinessServiceLineId = uwf.ServiceLineId

  WHERE ServiceLineId = 3
  --WHERE l.ForeignCode = '588406'
  --WHERE wi.OnHoldWorkItemId = '282543'