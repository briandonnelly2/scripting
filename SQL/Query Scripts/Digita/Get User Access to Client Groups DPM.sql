USE [PracticeManagementCoE]

SELECT	u.[Username] 
		,r.[Name] AS 'DPM Role'
		,u.[CanViewAllClients]
		,pu.IsActive
		,cg.[Name]
  FROM [PracticeManagementCoE].[dbo].[User] AS u

  INNER JOIN [Role] AS r ON r.RoleID = u.RoleID
  LEFT JOIN PracticeUser pu ON pu.PracticeUserID = u.PracticeUserID
  LEFT JOIN ClientGroupUser cgu ON cgu.UserID = u.UserID
  INNER JOIN ClientGroup AS cg ON cg.ClientGroupID = cgu.ClientGroupID

  WHERE cgu.ClientGroupID IN (
	'15FAACCB-EDBC-4C36-9B7A-9EBA2703D4EA', --IES HOPS UK
	'89F6A1AC-C31E-40A6-A4AB-936572ADAF55' --IES HOPS Offshore
  )
  --AND IsActive <> 0