USE [CCHCentral_Live]

SELECT em.EmployeeID
      ,em.FNameTemp + ' ' + em.SNameTemp AS 'Full Name'
	  ,sg.[Name] AS 'Group Name'
	  ,sg.[Description] AS 'Group Description'
      ,em.UserName AS 'User Name'
      ,CASE em.Inactive
		WHEN 0 THEN 'False'
		WHEN 1 THEN 'True'
		ELSE 'Undefined'
		END AS 'Inactive'
      ,em.CDSCode
      ,CASE em.FullAccess
		WHEN 0 THEN 'False'
		WHEN 1 THEN 'True'
		ELSE 'Undefined'
		END AS 'FullAccess'
      ,em.ContactID
	  ,dp.DepartmentName
	  ,ofc.OfficeName
  FROM Employee AS em
  LEFT JOIN EmployeeGroups AS eg ON em.EmployeeID = eg.EmployeeID
  INNER JOIN SecurityGroup AS sg ON eg.GroupID = sg.SecurityGroupID
  INNER JOIN Stationed AS st ON st.EmployeeID = em.EmployeeID
  INNER JOIN Department AS dp ON dp.DepartmentID = st.DepartmentID
  INNER JOIN Office AS ofc ON ofc.OfficeID = st.OfficeID

--  BEGIN TRAN
--  UPDATE Employee
--  SET Inactive = 1
--  WHERE EmployeeCode IN (
--  'ASHARMA',
--'TAX',
--'ALANSWORDS')
--  COMMIT