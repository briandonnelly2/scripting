USE [CCHCentral_Live]

SELECT em.EmployeeID
      ,em.FNameTemp + ' ' + em.SNameTemp AS 'Full Name'
	  --,sg.[Name] AS 'Group Name'
	  --,sg.[Description] AS 'Group Description'
      ,em.UserName AS 'User Name'
      ,CASE em.FullAccess
		WHEN 0 THEN 'False'
		WHEN 1 THEN 'True'
		ELSE 'Undefined'
		END AS 'FullAccess'
      ,em.ContactID
	  ,CASE em.DisabledEmployee
	    WHEN 0 THEN 'False'
		WHEN 1 THEN 'True'
		ELSE 'Undefined'
		END AS 'Disabled'
		,dp.DepartmentName
  FROM Employee AS em
    LEFT JOIN Stationed AS st ON st.EmployeeID = em.EmployeeID 
	INNER JOIN Department AS dp ON dp.DepartmentID = st.DepartmentID
  --LEFT JOIN EmployeeGroups AS eg ON eg.EmployeeID = em.EmployeeID
  --LEFT JOIN SecurityGroup AS sg ON eg.GroupID = sg.SecurityGroupID

  WHERE DisabledEmployee = 'False'

  ORDER BY [Full Name]