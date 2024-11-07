USE [trustacc]

SELECT syu.[r_id]
      ,syu.[TYPE]
      ,syu.[ID] AS 'Username'
      ,syu.[FULLNAME] AS 'Full Name'

      ,CASE syu.[SYSTEM_RIGHTS]
		WHEN 0  THEN 'Read-Only'
		WHEN 1  THEN 'System Management'
		WHEN 2  THEN 'Common File Maintenance'
		WHEN 3  THEN 'System Management, Common File Maintenance'
		WHEN 64 THEN 'Securities Maintenance'
		WHEN 65 THEN 'System Management, Securities Maintenance'
		WHEN 66 THEN 'Common File Maintenance, Securities Maintenance'
		WHEN 67 THEN 'System Management, Common File Maintenance, Securities Maintenance'
	   ELSE CAST(syu.[SYSTEM_RIGHTS] AS NVARCHAR(100)) + ' is an undefined value'
	   END AS 'System Rights'

	  ,CASE seu.[LOCAL_RIGHTS]
		WHEN 0    THEN 'None'
		WHEN 1032 THEN 'Master Account'
		WHEN 16   THEN 'Master Account (Read-Only)'
		WHEN 4    THEN 'Client creation'
		WHEN 32   THEN 'Database Supervisor'
		WHEN 1024 THEN 'Tick edit/delete'
		WHEN 20   THEN 'Master Account (Read-Only), Client creation'
		WHEN 48   THEN 'Master Account (Read-Only), Database Supervisor'
		WHEN 36   THEN 'Client creation, Database Supervisor'
		WHEN 1028 THEN 'Client creation, Tick edit/delete'
		WHEN 1056 THEN 'Database Supervisor, Tick edit/delete'
		WHEN 52   THEN 'Master Account (Read-Only), Client creation, Database Supervisor'
		WHEN 1060 THEN 'Client creation, Database Supervisor, Tick edit/delete'
		WHEN 8 THEN 'Master Account, Master Account (Read-Only), Client creation, Database Supervisor (Only built-in admin account can have this)'
	   ELSE CAST(seu.[LOCAL_RIGHTS] AS NVARCHAR(100)) + ' is an undefined value'
	   END AS 'Local Rights'
  FROM [SYSTEM_USERS] AS syu

  LEFT JOIN [SECTAX_USERS] AS seu ON seu.ID = syu.ID

  --WHERE syu.ID = 'UKRCASYED01'


  --LOCAL RIGHTS
    --None - (0)
	--Master Account - (1)
	--Master Account (Read-Only) - (2)
	--Client creation - (3)
	--Database Supervisor - (4)
	--Tick edit/delete - (5)
		  --(0) - 0
		  --(1) - 1032 - Master Account
		  --(2) - 16 - Master Account (Read-Only)
		  --(3) - 4 - Client creation
		  --(4) - 32 - Database Supervisor
		  --(5) - 1024 - Tick edit/delete
		  --(1,2) - N/A - Master Account supersedes all other permissions
		  --(1,3) - N/A - Master Account supersedes all other permissions
		  --(1,4) - N/A - Master Account supersedes all other permissions
		  --(1,5) - N/A - Master Account supersedes all other permissions
		  --(2,1) - N/A - Master Account supersedes all other permissions
		  --(2,3) - 20 - Master Account (Read-Only), Client creation
		  --(2,4) - 48 - Master Account (Read-Only), Database Supervisor
		  --(2,5) - N/A - Master Account (Read-Only) cannot be combined with Tick edit/delete
		  --(3,4) - 36 - Client creation, Database Supervisor
		  --(3,5) - 1028 - Client creation, Tick edit/delete
		  --(4,5) - 1056 - Database Supervisor, Tick edit/delete
		  --(1,2,3) - N/A - Master Account supersedes all other permissions
		  --(1,2,4) - N/A - Master Account supersedes all other permissions
		  --(1,2,5) - N/A - Master Account supersedes all other permissions
		  --(2,3,4) - 52 - Master Account (Read-Only), Client creation, Database Supervisor
		  --(2,3,5) - N/A - Master Account (Read-Only) cannot be combined with Tick edit/delete
		  --(3,4,5) - 1060 - Client creation, Database Supervisor, Tick edit/delete
		  --(1,2,3,4) - 8 - Master Account, Master Account (Read-Only), Client creation, Database Supervisor (Only built-in admin account can have this)
		  --(2,3,4,5) - N/A - Master Account (Read-Only) cannot be combined with Tick edit/delete




  --SYSTEM RIGHTS
    --Read-Only - (0)
	--System Management - (1)
	--Common file Maintenance - (2)
	--Securities Maintenance - (3)
		  --(0) - 0 - Read-Only
		  --(1) - 1 - System Management
		  --(2) - 2 - Common file Maintenance
		  --(3) - 64 - Securities Maintenance
		  --(1,2) - 3 - System Management, Common file Maintenance
		  --(1,3) - 65 - System Management, Securities Maintenance
		  --(2,3) - 66 - Common file Maintenance, Securities Maintenance
		  --(1,2,3) - 67 - System Management, Common file Maintenance, Securities Maintenance
