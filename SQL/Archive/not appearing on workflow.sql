/****** Script for SelectTopNRows command from SSMS  ******/
SELECT TOP (1000) [ClientGTSID]
      ,[ClientName]
      ,[AssigneeName]
      ,[AssigneeGTSID]
      ,[AssigneeAtlasID]
      ,[PreparingOffice]
      ,[TaxYear]
      ,[Processed]
      ,[VIP]
      ,[Timestamp]
  FROM [TAX_Atlas_KPMGLink].[dbo].[AtlasTaxReturnProjects]

  WHERE AssigneeGTSID IN
  (
	 '230533'--Capill, Deborah
	,'291577'--Christmas, David J
	,'853611'--Menkovic, Bosko
	,'229093'--Mulhern, James R
	,'719527'--Clifford Abrahams
	,'558470'--Abel, Nathan
  )
  AND TaxYear = 2019