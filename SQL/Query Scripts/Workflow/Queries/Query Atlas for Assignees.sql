/**
	Queries the Atlas new tax return projects table using Assignee GTS ID and Tax Year.

	Inputs: 
			@TaxYear - The tax year we are investigating.
			@AssigneeGTSID - The Assignee's GTS ID.
**/

USE [TAX_Atlas_KPMGLink]

DECLARE	@TaxYear NVARCHAR(4) = '2019'
DECLARE @AssigneeGTSID NVARCHAR(10) = '257276'

SELECT	 trp.ClientName AS 'Client Name'
		,trp.ClientGTSID AS 'Client GTS ID'
		,trp.AssigneeName AS 'Assignee Name'
		,trp.AssigneeGTSID AS 'Assignee GTS ID'
		,trp.AssigneeAtlasID AS 'Assignee Atlas ID'
		,wid.[WorkItemClientId] AS 'WF Client ID'
		,wid.[WorkItemId] AS 'WorkItem ID'
		,wid.[SequenceInstanceId]
		,wid.[Description] AS 'Client Name & Year'
		,trp.TaxYear AS 'Tax Year'
		,trp.Processed AS 'Is Processed?'
		,ss.OrganiserSentToTaxpayer AS 'Organiser Sent'
		,ss.OrganiserReceived AS 'Organiser Received'
		,ss.CompensationReceived AS 'Comp Received'
		,ss.OutstandingInformationRequested AS 'Outstanding Info Requested'
		,ss.OutstandingInformationReceived AS 'Outstanding Info Received'
		,vs.[Digita Upload Completed]
		,vs.[Missing Information identified through Vault]
		,vs.[Organiser processed through vault]
		,efs.Response AS 'EF Response Received?'
		,efs.DeclineReason AS 'Decline Reason'
		,efs.[Timestamp] AS 'EF Response Timestamp'
		
		FROM AtlasTaxReturnProjects AS trp

			INNER JOIN AtlasStatusSteps AS ss ON ss.AssigneeGTSID = trp.AssigneeGTSID AND ss.TaxYear = @TaxYear
			INNER JOIN EFilingStatus AS efs ON efs.AssigneeGTSID = ss.AssigneeGTSID --AND efs.TaxYear = ss.TaxYear
			INNER JOIN [Sequence].[dbo].[UWF9f16250dd2be404b9bf0f09c2fe2cba6] AS uwf ON uwf.TempGTSID = @AssigneeGTSID --AND uwf.WorkItemYear = @TaxYear
			INNER JOIN [Sequence].[dbo].[WF_Vault_Status] AS vs WITH (NOLOCK) ON ss.AssigneeGTSID = vs.[GTS ID] --AND vs.[TAX YEAR] = @TaxYear
			INNER JOIN [TaxWFPortalData]..[WorkItemDetail] AS wid WITH (NOLOCK) ON wid.SequenceInstanceId = uwf.fldIWfId

		WHERE trp.AssigneeGTSID = @AssigneeGTSID
		AND trp.TaxYear = @TaxYear
  
		ORDER BY trp.Processed, trp.AssigneeName DESC



  /**
  257276	GILLIAN MCCANN - DPDHL - Global Assignments
296542	Jez McQueen - DPDHL - Global Assignments
229088	PEARSON, JOHN - Deutsche Post AG - Mobility
841139	Hugo L Martins - Deutsche Post AG - Mobility

USE [TaxWFPortalData]

DECLARE @TaxYear NVARCHAR(4) = '2019'
DECLARE @GTSID NVARCHAR(10) = '406485'

/****** Script for SelectTopNRows command from SSMS  ******/
SELECT wid.[WorkItemId]
      ,wid.[SequenceInstanceId]
      ,wid.[Description] AS 'Client Name & Year'
	  ,wid.[WorkItemClientId] AS 'WF Client ID'
	  ,l.ForeignCode AS 'GTS ID'
	  
	  ,wid.[WorkItemMilestoneGroupTypeName] AS 'Stack'
      ,wid.[WorkItemMilestoneTypeName] AS 'Milestone'
	  ,wid.[WorkingDaysRemaining]
	  ,wid.[WorkItemStateChangeDate]
      ,wid.[WorkItemMilestoneChangeDate]
      ,wid.[WorkItemMilestoneChangedByUserName]
  FROM WorkItemDetail wid

  INNER JOIN Links l ON l.ClientId = wid.WorkItemClientId AND l.LinkTypeId = 5
  LEFT JOIN [TAX_Atlas_KPMGLink].[dbo].[AtlasStatusSteps] AS ass ON l.ForeignCode = ass.AssigneeGTSID 
  
  

  WHERE 
  wid.[Description] LIKE '%' + @TaxYear + '%'
  AND l.ForeignCode = @GTSID

  **/