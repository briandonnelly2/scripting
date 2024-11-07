/****** Script for SelectTopNRows command from SSMS  ******/
USE [PracticeManagementCoE]

SELECT be.[FileAs] AS 'Client Name'
	  ,cl.CLIENTTYPE AS 'Client Type'
      ,be.[ClientCode] AS 'DPM Refcode'
	  ,cl.REFCODE AS 'DPT Refcode'
	  ,cg.[Name] AS 'DPM Group'
	  ,gc.GroupId AS 'DPT Group'
	  ,be.[BillableEntityID]
  FROM [BillableEntity] AS be

  INNER JOIN [ClientGroupBillableEntity] AS cgbe ON cgbe.BillableEntityID = be.BillableEntityID
  INNER JOIN [ClientGroup] AS cg ON cg.ClientGroupID = cgbe.ClientGroupID

  INNER JOIN [TaxywinCOE].[dbo].[Client] AS cl WITH (NOLOCK) ON cl.[EntityId] = be.BillableEntityID
  INNER JOIN [TaxywinCOE].[dbo].[GroupClient] AS gc WITH (NOLOCK) ON gc.Clientid = cl.CLIENTID

  WHERE cg.[Name] IN ('IES UK', 'IES Offshore') 

  ORDER BY [Client Name]