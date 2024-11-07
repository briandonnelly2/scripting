USE [TaxWFPortalData]
SELECT usr.[UserId]
      ,usr.[UserName]
      ,usr.[DisplayName]
      ,usr.[DomainGroup]
      ,usr.[Guid]
      ,usr.[StaffId]
      ,usr.[Email]
      ,usr.[IsDeactivated]
      ,sr.RoleName
      ,usr.[DisplayAndUserName]
  FROM [User] AS usr
  INNER JOIN SystemRole AS sr ON sr.SystemRoleId = usr.SystemRoleId
  WHERE RoleName = 'Global Admin'
  ORDER BY IsDeactivated, RoleName