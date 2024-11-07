
DECLARE @UserName NVARCHAR (100) = '-oper-agray3'

SELECT [fldEmployeeId]
      ,[fldEmpUseName]
      ,[fldGlobalAdmin]
      ,[fldActive]
  FROM [SequenceSTG].[dbo].[tblEmployees]
  WHERE fldEmpUsename = @UserName

SELECT *
  FROM [StgWFPortalData].[dbo].[User]
  WHERE UserName = @UserName

  DECLARE @UserId INT  = 6693

  --BEGIN TRAN

  --UPDATE [SequenceSTG].[dbo].[tblEmployees]
  --SET fldGlobalAdmin = 0, fldActive = 0
  --WHERE fldEmployeeId = @UserId

  --UPDATE [StgWFPortalData].[dbo].[User]
  --SET SystemRoleId = 1, IsDeactivated = 1
  --WHERE UserId = @UserId

  --ROLLBACK
  --COMMIT

  /**
  SystemRoleId	RoleName
1	Not Set
2	Global Admin
3	Helpdesk Admin
4	Centre of Excellence Admin
5	Client Service Team User
6	Centre of Excellence User
7	Offshore User
8	Centre of Excellence Manager
9	Offshore Manager
  **/