/* 
	Name: 					get-db-obj-permissions.sql
	Purpose:				This script will return the permissions on all SQL database objects
	Version:                1.0
    Author:                 Brian Donnelly
    Creation Date:          10 February 2019
    Modified Date:          N/A
    Revfiew Date:           10 May 2019
    Future Enhancements:
*/

/*
	This script returns permissions on every single object in the SQL cluster.  I've not leveraged this 
	in the scripts and don't think i need to at this stage.  This one can be considered low priority,
	but I can see how this could potentially be useful information in the future.
	It would be useful to pass in database names so we can reduce the amount of data 
	retuned.
*/
SET NOCOUNT ON

DECLARE @permission TABLE (
	 DBName	        SYSNAME
	,Role           SYSNAME
	,Type	        NVARCHAR(60)
	,Action	        NVARCHAR(128)
	,Permission		NVARCHAR(60)
	,ObjectName		SYSNAME null
	,Object	        NVARCHAR(60)
	)

DECLARE @dbs		TABLE (
	dbname			SYSNAME
	)

DECLARE @Next SYSNAME

INSERT INTO @dbs

/*Use this for all databases*/
SELECT [name] 
FROM sys.databases 
ORDER BY [name]

SELECT TOP 1 @Next = dbname FROM @dbs

WHILE (@@rowcount<>0)

BEGIN

INSERT INTO @permission

EXEC('
	USE [' + @Next + ']
	
	DECLARE @objects TABLE (obj_id int, obj_type char(2))
	INSERT INTO @objects
	SELECT id, xtype FROM master.sys.sysobjects
	INSERT INTO @objects
	SELECT object_id, type FROM sys.objects

	SELECT ''' + @Next + ''', a.name AS ''User or Role Name''
		,a.type_desc AS ''Account Type''
		,d.permission_name AS ''Type of Permission''
		,d.state_desc AS ''State of Permission''
		,OBJECT_SCHEMA_NAME(d.major_id) + ''.'' + object_name(d.major_id) AS ''Object Name''
		,CASE e.obj_type
			WHEN ''AF'' THEN ''Aggregate function (CLR)''
			WHEN ''C''	THEN ''CHECK constraint''
			WHEN ''D''	THEN ''DEFAULT (constraint or stand-alone)''
			WHEN ''F''	THEN ''FOREIGN KEY constraint''
			WHEN ''PK'' THEN ''PRIMARY KEY constraint''
			WHEN ''P''	THEN ''SQL stored procedure''
			WHEN ''PC'' THEN ''Assembly (CLR) stored procedure''
			WHEN ''FN'' THEN ''SQL scalar function''
			WHEN ''FS'' THEN ''Assembly (CLR) scalar function''
			WHEN ''FT'' THEN ''Assembly (CLR) table-valued function''
			WHEN ''R''	THEN ''Rule (old-style, stand-alone)''
			WHEN ''RF'' THEN ''Replication-filter-procedure''
			WHEN ''S''	THEN ''System base table''
			WHEN ''SN'' THEN ''Synonym''
			WHEN ''SQ'' THEN ''Service queue''
			WHEN ''TA'' THEN ''Assembly (CLR) DML trigger''
			WHEN ''TR'' THEN ''SQL DML trigger''
			WHEN ''IF'' THEN ''SQL inline table-valued function''
			WHEN ''TF'' THEN ''SQL table-valued-function''
			WHEN ''U''	THEN ''Table (user-defined)''
			WHEN ''UQ'' THEN ''UNIQUE constraint''
			WHEN ''V''	THEN ''View''
			WHEN ''X''	THEN ''Extended stored procedure''
			WHEN ''IT'' THEN ''Internal table''
			END AS ''Object Type''

	FROM [' + @Next + '].sys.database_principals AS a
		LEFT JOIN [' + @Next + '].sys.database_permissions AS d on a.principal_id = d.grantee_principal_id
		LEFT JOIN @objects AS e ON d.major_id = e.obj_id
	')

DELETE @dbs
WHERE dbname = @Next

SELECT TOP 1 @Next = dbname 
FROM @dbs

END

SET NOCOUNT OFF

SELECT * 
FROM @permission
ORDER BY DBName, [Role]