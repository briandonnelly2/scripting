/* Find staff records in the WF portal data database */
USE [TaxWFPortalData]

SELECT 'UK\' + u.UserName AS 'WindowsLogin'
      ,u.IsDeactivated AS 'Deactivated'
      ,sr.RoleName AS 'UserRoleName'
	FROM [User] AS u
		INNER JOIN SystemRole AS sr ON u.SystemRoleId = sr.SystemRoleId
	WHERE UserName LIKE '%svc%'