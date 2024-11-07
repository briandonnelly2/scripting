/****** Script for SelectTopNRows command from SSMS  ******/
SELECT [FirstName]
      ,[LastName]
      ,[UserName]
      ,CASE [RestrictedClientAccess]
	  WHEN 0 THEN 'TRUE'
	  WHEN 1 THEN 'FALSE'
	  ELSE 'N/A'
	  END AS [RestrictedClientAccess]
      ,CASE [KGSUser]
	  WHEN 0 THEN 'TRUE'
	  WHEN 1 THEN 'FALSE'
	  ELSE 'N/A'
	  END AS [KGSUser]
	  ,r.RoleName
  FROM [TaxCompAnalyser].[dbo].[Users] AS u

  INNER JOIN UserRoles AS ur ON ur.UserId = u.Id
  INNER JOIN Roles AS r ON r.Id = ur.RoleID

  WHERE Active = 1