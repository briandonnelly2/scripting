/**
	Using much of the same logic that various stored proceedures use to check various parts of 
	the compensation process, returns workitem detail, Atlas status steps, Vault processing data and 
	e-filing status.  If nothing is returned, there is likely no workitem on workflow for this asssignee.
	
	Inputs: 
			@TaxYear - The tax year we are investigating.
			@GTSID - The Assignee's GTS ID
**/

USE [TaxWFPortalData]

DECLARE @TaxYear NVARCHAR(4) = '2019'
DECLARE @GTSID NVARCHAR(10) = '406485'

/****** Script for SelectTopNRows command from SSMS  ******/
SELECT wid.[WorkItemId]
      ,wid.[SequenceInstanceId]
      ,wid.[Description] AS 'Client Name & Year'
	  ,wid.[WorkItemClientId] AS 'WF Client ID'
	  ,l.ForeignCode AS 'GTS ID'
	  ,vs.[Digita Upload Completed]
	  ,vs.[Missing Information identified through Vault]
	  ,vs.[Organiser processed through vault]
	  ,ass.TaxYear
	  ,wid.[WorkItemMilestoneGroupTypeName] AS 'Stack'
      ,wid.[WorkItemMilestoneTypeName] AS 'Milestone'
	  ,wid.[WorkingDaysRemaining]
	  ,ass.OrganiserSentToTaxpayer AS 'Organiser Sent'
	  ,ass.OrganiserReceived AS 'Organiser Received'
	  ,ass.CompensationReceived AS 'Comp Received'
	  ,ass.OutstandingInformationRequested AS 'Outstanding Info Requested'
	  ,ass.OutstandingInformationReceived AS 'Outstanding Info Received'
	  ,wid.[WorkItemStateChangeDate]
      ,wid.[WorkItemMilestoneChangeDate]
      ,wid.[WorkItemMilestoneChangedByUserName]
	  ,efs.AssigneeGTSID
	  ,efs.Response AS 'Response Received?'
	  ,efs.DeclineReason
	  ,efs.[Timestamp]
  FROM WorkItemDetail wid

  INNER JOIN Links l ON l.ClientId = wid.WorkItemClientId AND l.LinkTypeId = 5
  LEFT JOIN [TAX_Atlas_KPMGLink].[dbo].[AtlasStatusSteps] AS ass ON l.ForeignCode = ass.AssigneeGTSID AND ass.TaxYear = @TaxYear
  LEFT JOIN [Sequence].[dbo].[WF_Vault_Status] AS vs ON ass.ClientGTSID = vs.[Client ID] AND ass.AssigneeGTSID = vs.[GTS ID] AND vs.[TAX YEAR] = @TaxYear
  LEFT JOIN [TAX_Atlas_KPMGLink].[dbo].[EFilingStatus] AS efs ON efs.AssigneeGTSID = ass.AssigneeGTSID AND efs.TaxYear = ass.TaxYear

  WHERE 
  wid.[Description] LIKE '%' + @TaxYear + '%'
  AND l.ForeignCode = @GTSID