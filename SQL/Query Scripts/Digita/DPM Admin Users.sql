/****** Script for SelectTopNRows command from SSMS  ******/
USE [PracticeManagementCOE]

SELECT u.[Username]
      ,u.[CanViewAllClients]
      ,r.[Name]
	  ,pu.IsActive
  FROM [User] AS u

  INNER JOIN Role AS r ON r.RoleID = u.RoleID
  LEFT JOIN PracticeUser AS pu ON pu.PracticeUserID = u.PracticeUserID

  --WHERE u.CanViewAllClients = 1
  WHERE r.[Name] = 'Administrator'