/****** Script for getting user access to client groups in workflow  ******/
USE [TaxWFPortalData]

SELECT u.[UserId]
      ,u.[UserName]
      ,u.[DisplayName]
      ,u.[Email]
      ,sr.RoleName
	  ,cag.[Description]
  FROM [User] AS u

  INNER JOIN [SystemRole] AS sr ON sr.SystemRoleId = u.SystemRoleId
  LEFT JOIN [UserClientAccessGroups] AS ucag ON ucag.UserId = u.UserId
  INNER JOIN [ClientAccessGroup] AS cag ON cag.ClientAccessGroupId = ucag.ClientAccessGroupId

  WHERE u.IsDeactivated <> 1
  AND cag.ClientAccessGroupId IN (7,8)

  ORDER BY RoleName