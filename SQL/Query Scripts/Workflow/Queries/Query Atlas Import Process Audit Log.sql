/****** Script for SelectTopNRows command from SSMS  ******/
SELECT TOP (1000) [Processed]
      ,[FileName]
      ,[ReportDate]
      ,[TaxYear]
      ,[PreparingOffice]
      ,[NumberofRecords]
      ,[SuccessfullyProcessed]
      ,[ErrorMessage]
      ,[ReportType]
  FROM [TAX_Atlas_KPMGLink].[dbo].[ImportProcessAudit]

  WHERE Processed >= '2019-01-01' 
  AND ReportType = 'UK Preparing Office Status' 
  AND TaxYear = 2019