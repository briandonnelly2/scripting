/* 
	Name: 					get-db-permissions.sql
	Purpose:				This script will return a list of database usernames mapped to database level roles
	Version:                1.0
    Author:                 Brian Donnelly
    Creation Date:          10 February 2019
    Modified Date:          N/A
    Revfiew Date:           10 May 2019
    Future Enhancements:
*/

/*
	This script does not work at the moment!  It did previously, so 
	I think I have removed/added something I shouldn't have!
	the script returns all database level permissions for a SQL cluster
	It would be vwery useful to be able to pass in database names to this one
	as we don't need the permissions on every database.
*/

DECLARE @SQLStatement VARCHAR(4000) 

DECLARE @T_DBuser			TABLE (
		 DBName				SYSNAME
		,UserName			SYSNAME
		,AssociatedDBRole	NVARCHAR(256)
		) 

SET @SQLStatement = '

	SELECT 
		 ''?'' AS DBName
		,dp.name AS UserName
		,case
		,USER_NAME(drm.role_principal_id) AS AssociatedDBRole

	FROM ?.sys.database_principals AS dp
		LEFT OUTER JOIN ?.sys.database_role_members AS drm ON dp.principal_id = drm.member_principal_id 

	WHERE dp.sid NOT IN (0x01) 
	AND dp.sid IS NOT NULL 
	AND dp.type NOT IN (''C'') 
	AND dp.is_fixed_role <> 1 
	AND dp.name NOT LIKE ''##%'' 
	AND ''?'' NOT IN (''master'',''msdb'',''model'',''tempdb'') 
	'
INSERT @T_DBuser

EXEC sp_MSforeachdb @SQLStatement --Think this is a stored proceedure that loops through every database.

SELECT * 
FROM @T_DBuser 
ORDER BY UserName