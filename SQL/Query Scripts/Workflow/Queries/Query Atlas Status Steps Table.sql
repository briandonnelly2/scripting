/**
	Queries the Atlas status steps table using Assignee GTS ID and Tax Year.

	Inputs: 
			@TaxYear - The tax year we are investigating.
			@GTSID - The Assignee's GTS ID
**/

USE [TAX_Atlas_KPMGLink]

DECLARE @TaxYear NVARCHAR(4) = '2019'
DECLARE @GTSID NVARCHAR(10) = '9019207'

SELECT TOP (1000) [ClientGTSID]
      ,[ClientName]
      ,[AssigneeName]
      ,[AssigneeGTSID]
      ,[AssigneeAtlasID]
      ,[TaxYear]
      ,[ProjectType]
      ,[OrganiserSentToTaxpayer]
      ,[OrganiserUndeliverable]
      ,[OrganiserReceived]
      ,[OutstandingInformationRequested]
      ,[OutstandingInformationReceived]
      ,[CompleteInformationReceived]
      ,[CompensationReceived]
      ,[EfilePermissionReceived]
      ,[EfilePermissionDenied]
      ,[No Tax Return Required]
      ,[Timestamp]
      ,[TAX RETURN SENT TO TAXPAYER]
      ,[Method Sent]
      ,[Submitted to HMRC Gateway]
      ,[Tax Authority Acceptance Acknowledgement Received]
      ,[Tax Authority Rejection Acknowledgement Received]
  FROM [TAX_Atlas_KPMGLink].[dbo].[AtlasStatusSteps]

  WHERE TaxYear = @TaxYear
  AND AssigneeGTSID = @GTSID
  --AND ClientGTSID IN ('17747','40738')


  --BEGIN TRAN

  --DELETE FROM [TAX_Atlas_KPMGLink].[dbo].[AtlasStatusSteps]
  --WHERE TaxYear = @TaxYear
  --AND AssigneeGTSID = @GTSID
  --AND ClientGTSID IN ('17747','40738')

  --DELETE FROM [TAX_Atlas_KPMGLink].[dbo].[AtlasTaxReturnProjects]
  --WHERE AssigneeGTSID = @GTSID
  --AND TaxYear = @TaxYear
  --AND ClientGTSID IN ('17747','40738')

  --SELECT [ClientGTSID],[ClientName],[AssigneeName] FROM [TAX_Atlas_KPMGLink].[dbo].[AtlasStatusSteps] WHERE TaxYear = @TaxYear AND AssigneeGTSID = @GTSID
  --SELECT [ClientGTSID],[ClientName],[AssigneeName] FROM [TAX_Atlas_KPMGLink].[dbo].[AtlasTaxReturnProjects] WHERE TaxYear = @TaxYear AND AssigneeGTSID = @GTSID

  --ROLLBACK
  ----COMMIT