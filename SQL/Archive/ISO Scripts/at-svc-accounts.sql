/****** Get Service Accounts in Alphatax User database  ******/
USE AlphataxUserCPC

SELECT	'AlphataxUserCPC' AS 'Database',
		'UK\' + e2ident AS 'WindowsLogin',
		'Unknown' AS 'Active',
		e2typ AS 'UserRoleName'
  FROM e2users
  --WHERE e2typ = 1
  WHERE e2ident LIKE '%-uk%' OR e2ident LIKE '%botOPS%' OR e2ident LIKE '%svc%'
  ORDER BY e2ident