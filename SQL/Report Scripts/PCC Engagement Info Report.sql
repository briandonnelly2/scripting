/****** TASK0115272 - Requested By Jill Stewart ******/
USE TaxWFPortalData

;WITH CstManager AS (SELECT [ClientId],
	STUFF((
	SELECT'; '+ u.DisplayAndUserName
	FROM [ServiceLineStaffRoles] sr
	LEFT JOIN [User] u on sr.Userid = u.UserId
	WHERE (ClientId = CSTManager.ClientId)
	AND ServiceLineRoleTypeId = 5
	FOR XML PATH (''))
	,1,2,'') AS Staff	   
  FROM ServiceLineStaffRoles CSTManager
  WHERE ServiceLineRoleTypeId = 5
  GROUP BY ClientId),

  CstStaff AS (SELECT [ClientId],
	STUFF((
	SELECT'; '+ u.DisplayAndUserName
	FROM [ServiceLineStaffRoles] sr
	LEFT JOIN [User] u on sr.Userid = u.UserId
	WHERE (ClientId = CSTManager.ClientId)
	AND ServiceLineRoleTypeId = 6
	FOR XML PATH (''))
	,1,2,'') AS Staff	   
  FROM ServiceLineStaffRoles CSTManager
  WHERE ServiceLineRoleTypeId = 6
  GROUP BY ClientId)

SELECT	 c.ClientName AS 'Client Name'
		,lk.ForeignCode AS 'Digita Client Code'
		,e.Description AS 'Engagement Description'
		,e.OpportunityId AS 'Opportunity Number'
		,p.TaxYearId AS 'Tax Year'
		,ou.OrgPathDescription AS 'Engagement Relationship Office'
		,ou2.OrgPathDescription AS 'Default Processing Office'
		,CASE osr.CanGoOffshore
			WHEN 1 THEN 'Offshore'
			WHEN 0 THEN 'Onshore'
			ELSE 'N/A'
		 END AS 'Portal Offshore Status'
		,cstm.Staff as 'CST Manager'
		,csts.Staff as 'CST Staff'

	FROM ClientPeriods AS cp

	INNER JOIN Clients AS c ON cp.ClientId = c.ClientId
	INNER JOIN Links AS lk ON c.ClientId = lk.ClientId
	INNER JOIN Periods AS p ON cp.PeriodId = p.PeriodId
	INNER JOIN Engagements AS e ON p.EngagementId = e.EngagementId
	INNER JOIN EngagementOrgUnitLink AS eoul ON e.EngagementId = eoul.EngagementId
	INNER JOIN OrgUnit AS ou ON eoul.OrgUnitId = ou.Id
	INNER JOIN ClientOrgUnitLink AS coul ON c.ClientId = coul.ClientId
	INNER JOIN OrgUnit AS ou2 ON coul.OrgUnitId = ou2.Id
	INNER JOIN ClientOSRCodes AS osr ON c.ClientId = osr.ClientId
	 LEFT JOIN CstStaff csts on osr.ClientId = csts.ClientId 
	 LEFT JOIN CstManager cstm on osr.ClientId = cstm.ClientId

	WHERE e.BusinessServiceLineId = 2 AND lk.LinkTypeId = 2 AND coul.LinkTypeId = 3 AND osr.BusinessServiceLineId = 2

	ORDER BY c.ClientName