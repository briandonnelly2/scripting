USE [Sequence]

DECLARE @WFInstanceID NVARCHAR(100) = '9810179'
DECLARE @TaxYear INT = 2019
DECLARE @WorkItemID NVARCHAR(100) = '293419'
DECLARE @GTSID NVARCHAR(10) = '553185'
DECLARE @ClientPeriodInstance int


select @ClientPeriodInstance = cp.SequenceInstanceId
from [TaxWFPortalData].[dbo].[WorkItems]  wi
join [TaxWFPortalData].[dbo].ClientPeriods cp on wi.ClientPeriodId = cp.ClientPeriodId
where wi.WorkItemId = @WorkItemID

SELECT [fldId]
      ,[fldTemplateWfGuid]
      ,[fldSourceIWfId]
      ,[fldSourceIActId]
  FROM tblInstanceWorkflows
  WHERE fldId = @WFInstanceID OR fldSourceIWfId = @WFInstanceID

SELECT [fldId]
      ,[fldTemplateWfGuid]
      ,[fldSourceIWfId]
      ,[fldSourceIActId]
  FROM tblInstanceWorkflowsClosed
  WHERE fldId = @WFInstanceID OR fldSourceIWfId = @WFInstanceID

  SELECT [fldId]
		,[fldTemplateActivityGuid]
		,[fldInstanceWfId]
		,[fldSourceActId]
  FROM tblInstanceActivities
  WHERE fldInstanceWFId = @WFInstanceID

  SELECT   [fldId]
		  ,[fldToId]
		  ,[fldIActId]
		  ,[fldSubject]
		  ,[fldIWFId]
		  ,[fldSource]
  FROM tblActionItems
  WHERE fldIWFId = @WFInstanceID

  SELECT * 
  FROM [TaxWFPortalData]..[WorkItems] 
  WHERE WorkItemId = @WorkItemId OR ParentWorkItemId = @WorkItemId

  SELECT *
  FROM [Sequence]..[UACT910bad3d040c4db79d241ebe24dd008c]
  WHERE TempGTSID = @GTSID and fldIWfId = @ClientPeriodInstance


  --BEGIN TRAN

  --DELETE FROM tblInstanceWorkflows
  --WHERE fldId = @WFInstanceID OR fldSourceIWfId = @WFInstanceID

  --DELETE FROM tblInstanceWorkflowsClosed
  --WHERE fldId = @WFInstanceID OR fldSourceIWfId = @WFInstanceID

  --DELETE FROM tblInstanceActivities
  --WHERE fldInstanceWFId = @WFInstanceID
  
  --DELETE FROM tblActionItems
  --WHERE fldIWFId = @WFInstanceID

  --DELETE FROM [TaxWFPortalData].[dbo].[WorkItems] 
  --WHERE WorkItemId = @WorkItemId OR ParentWorkItemId = @WorkItemId

  --DELETE FROM UWF9f16250dd2be404b9bf0f09c2fe2cba6
  --WHERE fldIWfId = @WFInstanceID

  --DELETE FROM [Sequence].[dbo].[UACT910bad3d040c4db79d241ebe24dd008c]
  --WHERE TempGTSID = @GTSID and fldIWfId = @ClientPeriodInstance

  ----ROLLBACK
  --COMMIT