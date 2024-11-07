/****** Script for SelectTopNRows command from SSMS  ******/
SELECT syg.FULLNAME AS 'Group Name'
      ,gm.[USER_ID] AS 'Group member'
	  ,syu.FULLNAME AS 'Display Name'
  FROM [trustacc].[dbo].[GROUP_MEMBERS] AS gm

  INNER JOIN [SYSTEM_USERS] AS syg ON syg.[ID] = gm.GROUP_ID
  INNER JOIN [SYSTEM_USERS] AS syu ON syu.[ID] = gm.[USER_ID]

  ORDER BY gm.[GROUP_ID], gm.[USER_ID]