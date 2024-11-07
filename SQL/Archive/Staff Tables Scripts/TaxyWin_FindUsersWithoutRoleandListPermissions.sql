	/******   ******/
	USE [Taxywin1]
	SELECT 
		 up.UserName AS 'User'
		,pe.PermissionName AS 'Permission'
		,pe.SubPermissionName AS 'Sub-Permission'
	FROM UserPermissions AS up
	INNER JOIN Permissions AS pe ON up.PermissionID = pe.PermissionID
	WHERE up.Enabled = 1

	ORDER BY up.UserName, pe.PermissionName, pe.SubPermissionOrder