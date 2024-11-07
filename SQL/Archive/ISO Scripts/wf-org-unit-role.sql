/****** Searches workfl;ow uisers based on their system role or org unit permission ******/
USE [TaxWFPortalData]

DECLARE @SystemRole INT = 13
DECLARE @OrgUnitPermission INT = 11

SELECT	 u.DisplayName
		,u.UserName
		,sr.RoleName AS 'System Role'
		,ou.OrgPathDescription AS 'Org Unit'
		,olt.[Name] AS 'Permission Name'
  FROM UserOrgUnitLink AS uol
	INNER JOIN [User] AS u ON uol.UserId = u.UserId
	INNER JOIN SystemRole AS sr ON u.SystemRoleId = sr.SystemRoleId
	INNER JOIN UserOrgUnitLinkType AS olt ON uol.LinkTypeId = olt.Id
	INNER JOIN OrgUnit AS ou ON uol.OrgUnitId = ou.Id

	WHERE uol.LinkTypeId = @OrgUnitPermission AND
			ou.OrgPathDescription IN ('GMS', 'GMS > CoE')

	--WHERE	u.SystemRoleId = @SystemRole --AND
			--ou.OrgPathDescription IN ('GMS', 'GMS > CoE')

	ORDER BY ou.OrgPathDescription, sr.RoleName DESC

/****** 
System Permissions:

Id	RoleName
--  --------

1	Not Set
2	Global Admin
3	Helpdesk Admin
4	Centre of Excellence Admin
5	Client Service Team User
6	Centre of Excellence User
7	Offshore User
8	Centre of Excellence Manager
9	Offshore Manager


Org-Unit Permissions:

Id	Name						Description
--  ----						-----------

1	Reporting					Displays the Management Dashboard for this Organisational Unit and its subsidiaries
2	Preparer					An assigned work item preparer for an org unit
3	First Reviewer				An assigned work item reviewer for an org unit
4	Second Reviewer				An assigned work item second reviewer for an org unit
5	Client Administrator		The Client Administrator can, through the Client Administration functionality, change client details such as Client Access Groups. 
6	Manager						A manager
7	Team Leader					A team leader
8	Complex Preparer			A preparer of complex tax returns
9	C Grade First Reviewer		A reviewer of complex tax returns
11	User Role Administrator		User Role Administration allows a user to add users or change the rights for existing users for the Organisational Unit and its subsidiaries
12	E Grade First Reviewer		A reviewer of simple tax returns
13	User Task Administrator		User Task Administrators can access Task Administration and reassign or return to the task queue other users' tasks.
15	Front Loader				An assigned work item front loader for an org unit
16	Client Co-Ordinator			Client Co-Ordinators are responsible for handling the Missing Information tasks
17	Tax Experts 1				Internal review for tax purposes level 1
18	Tax Experts 2				Internal review for tax purposes level 2
19	Preparer L1					An assigned work item preparer for an org unit level 1
20	Preparer L2					An assigned work item preparer for an org unit level 2
21	Onshore Reviewer L1			A level 1 onshore reviewer
22	Onshore Reviewer L2			A level 2 onshore reviewer
23	Onshore Reviewer L3			A level 3 onshore reviewer
24	GMS Management Reporting	Shows onshore management dashboard

 ******/