/****** Script for SelectTopNRows command from SSMS  ******/
SELECT [UserLoginID]
      ,[FirstName]
      ,[LastName]
      ,[EmailID]
	  ,ur.[Role]
      ,CASE [IsActive]
	  WHEN 0 THEN 'TRUE'
	  WHEN 1 THEN 'FALSE'
	  ELSE 'N/A'
	  END AS [Active]
      ,CASE [CorpUser]
	  WHEN 0 THEN 'TRUE'
	  WHEN 1 THEN 'FALSE'
	  ELSE 'N/A'
	  END AS [CorpUser]
      ,CASE [TPUser]
	  WHEN 0 THEN 'TRUE'
	  WHEN 1 THEN 'FALSE'
	  ELSE 'N/A'
	  END AS [TPUser]
  FROM [ACE].[dbo].[ACEUser] AS au

  INNER JOIN UserRole AS ur ON ur.RoleID = au.RoleID

  ORDER BY Active DESC