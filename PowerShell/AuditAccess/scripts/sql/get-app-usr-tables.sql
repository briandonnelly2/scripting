/* 
	Name: 					get-app-usr-tables.sql
	Purpose:				This script will return the user tables for the application in scope.
	Version:                1.0
    Author:                 Brian Donnelly
    Creation Date:          10 February 2019
    Modified Date:          N/A
    Revfiew Date:           10 May 2019
    Future Enhancements:
*/

/*
	With this script (or scripts) I want to dump the contents of the user tables for an application
	I don't think it would be possible to pass database names etc to this as the column names etc.
	would be different for each app.  My thought was to create a stored proceedure per database that
	can be triggered from the powershell scripts I created.  The name of the script/proceedure would
	either need to be the same on every db we add it to or I can also include it in a config file my 
	script reads.  Currently, I'm only referencing the 'fldEmpUseName' & 'fldGlobalAdmin' columns from
	the powershell end.
*/
USE [StgWFPortalData]

SELECT usr.[UserId]
      ,usr.[UserName]
      ,usr.[DisplayName]
      ,usr.[DomainGroup]
      ,usr.[Guid]
      ,usr.[StaffId]
      ,usr.[Email]
      ,usr.[IsDeactivated]
      ,sr.RoleName
      ,usr.[DisplayAndUserName]
  FROM [User] AS usr
  INNER JOIN SystemRole AS sr ON sr.SystemRoleId = usr.SystemRoleId
  WHERE RoleName = 'Global Admin'
  ORDER BY IsDeactivated, RoleName

USE [SequenceSTG]

SELECT [fldEmployeeId]
      ,[fldEmpName]
      ,[fldEmpLastName]
      ,[fldEmpUseName]
      ,[fldEmail]
      ,[fldGroup]
      ,[fldId]
      ,[fldGlobalAdmin]
      ,[fldDeveloper]
      ,[fldActive]
      ,[fldIsFromAD]
      ,[whenChanged]
      ,[employeeID]
  FROM tblEmployees
  WHERE fldGlobalAdmin = 1
  ORDER BY fldGlobalAdmin DESC, fldActive DESC