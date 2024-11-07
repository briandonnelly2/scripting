/****** Script for SelectTopNRows command from SSMS  ******/
SELECT wid.[WorkItemId] AS 'ID'
      --,[BusinessServiceLineId]
      --,[WorkItemTypeId]
      --,[CompletedDate]
	  --,CONVERT(VARCHAR, [ClientPeriodStartDate], 103) AS 'Period start...'
      ,CONVERT(VARCHAR, [ClientPeriodEndDate], 103) AS 'Period end...'
	  ,[WorkItemClientName] AS 'Client'
	  ,wid.[Description] AS 'Entity'
	  ,[WorkItemMilestoneGroupTypeName] + ' - ' + [WorkItemMilestoneTypeName] AS 'Milestone'
	  ,CONVERT(VARCHAR, [DueDate], 103) + ' - ' + [SlaBandTypeName] AS 'Deadline'
	  ,dt.[Name] AS 'Deadline type'
	  ,oupu.[Name] + ' - ' + oupo.[Name] AS 'Processing Unit'
	  --,[WorkItemStateChangeDate]
   --   ,[WorkItemMilestoneChangeDate]
   --   ,[WorkingDaysRemaining]
   --   ,[WorkItemSubTypeName]
   --   ,[WorkItemClientId]
   --   ,[ClientPeriodClientName]
   --   ,[EngagementLeadClientName]
   --   ,[WorkItemStateName]
   --   ,[PeriodDescription]
   --   ,[TaxYearId]
	  --,[ComplexityDescription]
   --   ,[ComplexityCategory]
   --   ,[ComplexityLastUpdated]
  FROM [TaxWFPortalData].[dbo].[WorkItemDetail] AS wid
  
  LEFT JOIN WorkItemDeadlineTypes AS dt ON dt.DeadlineTypeId = wid.[DeadlineTypeId]
  LEFT JOIN WorkItemOrgUnitIndexView AS ouv ON ouv.WorkItemId = wid.WorkItemId
  LEFT JOIN OrgUnit AS oupu ON oupu.Id = ouv.ProcessingUnitOrgUnitId
  LEFT JOIN OrgUnit AS oupo ON oupo.Id = ouv.ProcessingOfficeOrgUnitId

  WHERE WorkItemTypeId = '17'