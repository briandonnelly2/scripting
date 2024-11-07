/****** Script for SelectTopNRows command from SSMS  ******/
USE [PracticeManagementCoE]

SELECT u.[UserID]
      ,u.[Username]
      ,u.[CanViewAllClients]
      ,r.[Name]
  FROM [User] AS u

  INNER JOIN Role AS r ON r.RoleID = u.RoleID

  WHERE u.CanViewAllClients = 1