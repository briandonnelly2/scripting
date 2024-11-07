/**
	This script pulls back the permissions that exist on clients in the Trust Accounts database.

	Results are ordered by client code.

	Where there is more than  one result for an individual client, more than one group/user has access to this client.

	Every client should be assigned to at least one group, otherwise all users can see that client in Trust Accounts.

	The permissions are built out of a code in the database, I have worked out what each code means in terms of permissions through a process of elimination.
**/

USE [trustacc]

SELECT cl.USERCODE AS 'Client Code'
	  ,cl.TITLE AS 'Title'
	  ,cl.FORENAMES AS 'Forename'
	  ,cl.SURNAME AS 'Surname'
      ,syu.FULLNAME AS 'Group/User Name'
      ,CASE sa.[RIGHTS]
	    WHEN 2  THEN 'Read'
		WHEN 3  THEN 'Read, Supervisor'
		WHEN 6  THEN 'Read, Write'
		WHEN 10 THEN 'Read, Delete'
		WHEN 7  THEN 'Read, Supervisor, Write'
		WHEN 11 THEN 'Read, Supervisor, Delete'
		WHEN 14 THEN 'Read, Write, Delete'
		WHEN 15  THEN 'Read, Supervisor, Write, Delete'
		ELSE CAST(sa.[RIGHTS] AS NVARCHAR(100)) + ' is an undefined value'
	   END AS 'Client Rights'
  FROM [trustacc].[dbo].[SECTAX_ACCESS] AS sa

  INNER JOIN CLIENTS AS cl ON cl.CODE = sa.CLIENT
  INNER JOIN [SYSTEM_USERS] AS syu ON syu.[ID] = sa.ID

  ORDER BY cl.USERCODE

    --CLIENT RIGHTS
	  --Read - (1)
	  --Supervisor - (2)
	  --Write - (3)
	  --Delete - (4)
			--(1) - 2 - Read
			--(1,2) - 3 - Read, Supervisor
			--(1,3) - 6 - Read, Write
			--(1,4) - 10 - Read, Delete
			--(1,2,3) - 7 - Read, Supervisor, Write
			--(1,2,4) - 11 - Read, Supervisor, Delete
			--(1,3,4) - 14 - Read, Write, Delete
			--(1,2,3,4) - 15 - Read, Supervisor, Write,Delete