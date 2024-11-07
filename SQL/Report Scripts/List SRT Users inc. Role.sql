/****** Script for SelectTopNRows command from SSMS  ******/
SELECT [FirstName]
      ,[LastName]
      ,[UserName]
	  ,r.RoleName
	  ,r.RoleDescription
  FROM [TaxSRTv2_Web].[dbo].[User] AS u

  INNER JOIN UserRole AS ur ON ur.UserId = u.UserID
  INNER JOIN [Role] AS r ON r.RoleID = ur.RoleID

  WHERE Active = 1