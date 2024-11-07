/****** Get Service Accounts in DPT database  ******/
USE [TaxywinCOE]

SELECT 'TaxywinCOE' AS 'Database'
	  ,[strWindowsLogin] AS 'WindowsLogin'
      ,[bActive] AS 'Active'
      ,[strUserRoleName] AS 'UserRoleName'
  FROM [User]
  WHERE UserId LIKE '%svc%' OR UserId LIKE '%botOPS%'
  --WHERE strWindowsLogin NOT LIKE 'UK\%' --AND u.IsSystem != 1
 