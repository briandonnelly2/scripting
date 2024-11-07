/****** Returns DPM Service Accounts  ******/
USE [PracticeManagementCoE]

SELECT 'PracticeManagementCoE' AS 'Database'
	  ,u.Username AS 'WindowsLogin'
	  ,pu.IsActive AS 'Active'
	  ,r.[Name] AS 'UserRoleName'
  FROM [User] AS u
  FULL JOIN PracticeUser AS pu ON u.PracticeUserID = pu.PracticeUserID
  INNER JOIN [Role] AS r ON u.RoleID = r.RoleID
  --WHERE IsActive IS NULL
  WHERE Username LIKE '%svc%'
  --WHERE u.Username NOT LIKE 'UK\%' AND u.IsSystem != 1