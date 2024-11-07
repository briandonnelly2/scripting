/* 
	Find staff records in the WF portal data database 

	SystemRoleId	RoleName
	------------	--------
	1				Not Set
	2				Global Admin
	3				Helpdesk Admin
	4				Centre of Excellence Admin
	5				Client Service Team User
	6				Centre of Excellence User
	7				Offshore User
	8				Centre of Excellence Manager
	9				Offshore Manager 
*/

USE [TaxWFPortalData]

DECLARE @RoleID INT
SET @RoleID = 1 --Replace with a value from above

SELECT u.UserId
      ,u.DisplayName
      ,u.UserName
      ,u.StaffId
      ,u.Email
      ,u.IsDeactivated
      ,sr.RoleName
	FROM [User] AS u
		INNER JOIN SystemRole AS sr ON u.SystemRoleId = sr.SystemRoleId
	WHERE u.SystemRoleId = @RoleID 
	--AND UserName IN( --INSERT UserName(s) here)


/* 
	Change 'SystemRoleId' by copy/pasting usernames you want to update
*/
--BEGIN TRANSACTION
--	UPDATE [User]
--	SET SystemRoleId = 1 
--	WHERE UserName IN 
--	(
--		--INSERT UserName(s) here
--	)

--	Rollback
--	--commit

/* 
	Change 'isDeactivated' by copy/pasting usernames you want to update
*/
--BEGIN TRANSACTION
--	UPDATE [User]
--	SET isDeactivated = 1
--	WHERE UserName IN 
--	(
--		--INSERT UserName(s) here
--	)

--	Rollback
--	--commit