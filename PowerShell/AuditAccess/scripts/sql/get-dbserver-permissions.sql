/* 

	Name: 					get-dbserver-permissions.sql
	Purpose:				This script will return the permissions to the server
	Version:                1.0
    Author:                 Brian Donnelly
    Creation Date:          10 February 2019
    Modified Date:          N/A
    Revfiew Date:           10 May 2019
    Future Enhancements:


*/

/*
	This script returns all server level permissions on the SQL cluster.
	I am using it to confirm that no one has any server level permissions
	in our team, especially developers.  Don't think this one needs much,
	but it could maybe be useful to be able to pass in a login name perhaps
	so we can search for individual accounts.
*/
SELECT 
	 sp.name					AS 'LoginName'
	,sp.type_desc				AS 'LoginType'
	,sp.default_database_name	AS 'DefaultDatabase'
	,slog.sysadmin				AS 'SysAdmin'
	,slog.securityadmin			AS 'SecurityAdmin'
	,slog.serveradmin			AS 'ServerAdmin'
	,slog.setupadmin			AS 'SetupAdmin'
	,slog.processadmin			AS 'ProcessAdmin'
	,slog.diskadmin				AS 'DiskAdmin'
	,slog.dbcreator				AS 'DBCreator'
	,slog.bulkadmin				AS 'BulkAdmin'

FROM sys.server_principals AS sp 
	INNER JOIN master..syslogins AS slog ON sp.sid = slog.sid 
	
	WHERE sp.type <> 'R' AND sp.name NOT LIKE '##%'