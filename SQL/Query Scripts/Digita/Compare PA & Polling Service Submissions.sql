/****** Script for SelectTopNRows command from SSMS  ******/
DECLARE @ClientCode VARCHAR(100) = '108205'
DECLARE @TaxYear NVARCHAR(100) = '2021'

SELECT TOP (1000) [Id]
      ,[ClientCode]
      ,[TaxYear]
      ,fs.strStatus AS [Polling Service Status]
      ,es.[CreatedDate] AS [Polling Service Created]
      ,es.[UpdatedDate] AS [Polling Service Updated]
      ,[MasterWorkflowId]
      ,[UserName]
      ,fs2.strStatus AS [Digita Status]
      ,fbs.dtSubmitted AS [Digita Submitted]
      ,fbs.dtNextCheck AS [Digita Next Check]

  FROM [DigitaService_Partnership_Live].[dbo].[EFiling_Submissions] es

  INNER JOIN [DigitaService_Partnership_Live].[dbo].[EFiling_SubmissionStatus] ss ON ss.SubmissionStatusId = es.SubmissionStatusId
  INNER JOIN [TaxywinSecure1].[dbo].[FBIStatusRef] fs WITH (NOLOCK) ON fs.lID = ss.SubmissionStatus
  INNER JOIN [TaxywinSecure1].[dbo].[Client] c WITH (NOLOCK) ON c.REFCODE = es.ClientCode
  INNER JOIN [TaxywinSecure1].[dbo].[FBISubmissions] fbs WITH (NOLOCK) ON fbs.lClientID = c.CLIENTID
  INNER JOIN [TaxywinSecure1].[dbo].[FBIStatusRef] fs2 WITH (NOLOCK) ON fs2.lID = fbs.lStatusID

  WHERE ClientCode = @ClientCode AND fbs.nYear = @TaxYear AND es.TaxYear = @TaxYear