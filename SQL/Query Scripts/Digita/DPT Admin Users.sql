USE [TaxywinFarringdonSecure]

SELECT [strFullName] AS 'Name'
      ,[UserId]
      ,[bActive] AS 'Active?'
      ,[strUserRoleName] AS 'Role'
	  ,bUseWindowsLogin AS 'Windows Logon?'
  FROM [User]

  WHERE strUserRoleName = 'Administrator'