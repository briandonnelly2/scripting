/****** Script for SelectTopNRows command from SSMS  ******/
SELECT gm.[r_id]
      ,syg.FULLNAME AS 'Group Name'

	  ,CASE syg.[SYSTEM_RIGHTS]
		WHEN 0  THEN 'Read-Only'
		WHEN 1  THEN 'System Management'
		WHEN 2  THEN 'Common File Maintenance'
		WHEN 3  THEN 'System Management, Common File Maintenance'
		WHEN 64 THEN 'Securities Maintenance'
		WHEN 65 THEN 'System Management, Securities Maintenance'
		WHEN 66 THEN 'Common File Maintenance, Securities Maintenance'
		WHEN 67 THEN 'System Management, Common File Maintenance, Securities Maintenance'
	   ELSE CAST(syg.[SYSTEM_RIGHTS] AS NVARCHAR(100)) + ' is an undefined value'
	   END AS 'Group System Rights'

	   ,CASE seg.[LOCAL_RIGHTS]
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
	   ELSE CAST(seg.[LOCAL_RIGHTS] AS NVARCHAR(100)) + ' is an undefined value'
	   END AS 'Group Local Rights'

	   ,gm.[USER_ID] AS 'Group member'

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
	   END AS 'User System Rights'

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
	   END AS 'User Local Rights'

  FROM [trustacc].[dbo].[GROUP_MEMBERS] AS gm

  INNER JOIN [SYSTEM_USERS] AS syg ON syg.[ID] = gm.GROUP_ID
  INNER JOIN [SECTAX_USERS] AS seg ON seg.ID = syg.ID
  INNER JOIN [SYSTEM_USERS] AS syu ON syu.[ID] = gm.[USER_ID]
  INNER JOIN [SECTAX_USERS] AS seu ON seu.ID = syu.ID

  ORDER BY gm.[GROUP_ID], gm.[USER_ID]