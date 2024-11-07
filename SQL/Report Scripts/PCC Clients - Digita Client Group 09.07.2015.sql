USE [PracticeManagementCoE]
GO

SELECT

be.[FileAs] AS [FileAs in DPM]
,be.[ClientCode] AS [Client Code in DPM]
,cg.[Name] AS [Client Group in DPM]
,c.[Firstnames] AS [Firstname in DPT]
,c.[Surname] AS [Surname in DPT]
,c.[refcode] AS [Ref Code in DPT]
,gc.[GroupId] AS [Client Group in DPT]

FROM [BillableEntity] be

INNER JOIN [TaxywinCoE]..[Client] c WITH (NOLOCK) ON c.[EntityID] = be.[BillableEntityID]
INNER JOIN[TaxywinCoE]..[GroupClient] gc ON gc.[Clientid] = c.[CLIENTID]
INNER JOIN ClientGroupBillableEntity cgb ON cgb.billableentityid=be.billableentityid
INNER JOIN Clientgroup cg ON cg.ClientGroupID = cgb.ClientGroupID

WHERE
cg.[ClientGroupID] in ('7238B024-0AF3-44BA-85B5-7BDE668F1B36','F9DD3D47-5E95-439F-B8F6-CEE2CBE1267B') --PCC UK & Offshore
AND
c.[ACTIVE] = 1
AND
be.[ClientCode] IS NOT NULL
AND
be.[ClientCode] NOT LIKE '%unknown%'
AND
c.[refcode] IS NOT NULL
AND
c.[refcode] NOT LIKE '%unknown%'

ORDER BY be.[ClientCode], c.[refcode]