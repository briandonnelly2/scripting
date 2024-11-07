  --RECIPIENTS:

--Jill Park; Amanda Strachan

--INPUTS:

--@DateFromMinusDaysFromToday = How many days between the date you are running the script and the beginning of the previous month 

--@DateToMinusDaysFromToday = How many days between the date you are running the script and the end of the previous month 

--DECLARE @DateFromMinusDaysFromToday INT = XX 
--DECLARE @DateToMinusDaysFromToday INT = XX 
--DECLARE @DateFrom Date = GETDATE()  - @DateFromMinusDaysFromToday
--DECLARE @DateTo Date = GETDATE() - @DateToMinusDaysFromToday



SELECT  wid.[WorkItemId] AS 'WorkItem ID'
		,CONVERT(VARCHAR, wid.[ClientPeriodEndDate], 103) AS 'Period end...'
		,wid.[WorkItemClientName] AS 'Client'
		,wid.[Description] AS 'Entity'
		,R.[DocumentId], 
		Position AS [ReviewPoint No], CASE WHEN R.Id = 0 THEN 'ReviewPoint' ELSE 'Response' END AS [Item Type], 
		[Type] AS [Category], 
		[SubType] AS [Category Type], 
		Section, 
		Comment, 
		CreateByName, 
		CreatedBy,
		CreatedTimeStamp
		FROM 
(SELECT R.[DocumentId],
		R.Position,
		RP.[Id],
		RP.[Comment],
		U.[Name] AS [CreateByName],
		RP.CreatedBy,
		RP.[CreatedTimeStamp],
		RT.Name AS [Type],
		NULL AS [SubType],
		NULL AS [Section]
		
		
		--,RP.*
  FROM [TaxWFReviewToolData].[dbo].[ReviewPointResponse] RP
  INNER JOIN [TaxWFReviewToolData].[dbo].[ReviewPoint] R ON R.Id = RP.ReviewPointId
  INNER JOIN [TaxWFReviewToolData].[dbo].[User] U ON U.Id = RP.CreatedBy
  INNER JOIN [TaxWFReviewToolData].[dbo].[ResponseType] RT ON RT.Id = RP.ResponseTypeId
  UNION

  SELECT	 R.[DocumentId]
			,R.[Position]
			,0 AS [Id]
			,[Comment]
			,U.Name AS [CreateByName]
			,RH.CreatedBy
			,RH.[CreatedTimeStamp]
			,RT.Name AS [Type]
			,RST.Name AS [SubType]
			,DS.Name AS [Section]
			
  FROM [TaxWFReviewToolData].[dbo].[ReviewPoint] R
  INNER JOIN [TaxWFReviewToolData].[dbo].[ReviewPointStatusHistory] RH ON RH.ReviewPointId = R.Id
  INNER JOIN [TaxWFReviewToolData].[dbo].[User] U ON RH.CreatedBy = U.[Id]
  INNER JOIN [TaxWFReviewToolData].[dbo].[ReviewPointType] RT ON RT.Id = R.ReviewPointTypeId
  LEFT JOIN [TaxWFReviewToolData].[dbo].[ReviewPointSubType] RST ON RST.Id = R.ReviewPointSubTypeId
  INNER JOIN [TaxWFReviewToolData].[dbo].[DocumentSection] DS ON DS.Id = R.DocumentSectionId
  WHERE RH.ReviewPointStatusId = 1) R
    INNER JOIN 
(SELECT 
	Distinct v.WorksiteDocumentId
			,v.ClientId
			,v.ClientName
			,rt.WorkItemInstanceId
FROM
	Sequence..UWFf5acb65a91b54511a1e286f23c37f134 v
JOIN
	Sequence..UACT9fb7f569f014441cb9d8b966ee165672 rt on v.fldIWfId = rt.fldIWfId
WHERE
	v.ServiceLineId = 5) S ON S.WorksiteDocumentId collate SQL_Latin1_General_CP1_CI_AS  = R.[DocumentId] collate SQL_Latin1_General_CP1_CI_AS 
JOIN TaxWFPortalData..WorkItemDetail AS wid ON wid.SequenceInstanceId = s.WorkItemInstanceId

--AND (R.[CreatedTimeStamp] BETWEEN @DateFrom AND @DateTo)

Order by CreatedTimeStamp 
