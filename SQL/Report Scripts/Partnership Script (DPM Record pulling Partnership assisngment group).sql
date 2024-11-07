USE [TaxywinCOE]
GO

;WITH DPMInfo AS (
SELECT 
	be.[billableentityid]
	,cg.[Name] AS [Group Name]
	,be.ClientCode

FROM [PracticeManagementCoE].[dbo].BillableEntity be

LEFT JOIN [PracticeManagementCoE].[dbo].[ClientGroupBillableEntity] AS cgbe ON cgbe.BillableEntityID = be.billableentityid
LEFT JOIN [PracticeManagementCoE].[dbo].[ClientGroup] AS cg ON cg.ClientGroupID = cgbe.ClientGroupID
)

SELECT

 p.[NAME] AS [Partnership Name]
,p.RefCode AS [Partnership RefCode]
,c.Firstnames + ' ' + c.Surname AS 'Client Name'
,c.[Active]
,c.bHidden
,di.ClientCode AS 'DPM Refcode'
,c.REFCODE AS 'DPT Refcode'
,di.[Group Name] AS 'DPM Group'
,gc.GroupId AS 'DPT Group'

FROM client c

LEFT JOIN partnershipclients pc on pc.clientid = c.clientid
LEFT JOIN Partnership p ON p.pclientid = pc.pclientid
LEFT JOIN DPMInfo di ON c.EntityId = di.BillableEntityID
LEFT JOIN [GroupClient] AS gc ON gc.Clientid = c.CLIENTID

WHERE p.refcode in ('MR60132292DL', 'MR60637172DL') --AND di.[Group Name] IS NULL

ORDER BY c.[Active] DESC