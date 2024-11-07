
DECLARE @Username VARCHAR(100) = 'jsimpson6'
DECLARE @PracticeUserID NVARCHAR(100) --= '3BB7D507-D4EF-439E-A449-B39E56B10FEA' 

SELECT [Username]
      ,[IsSystem]
      ,[RoleID]
      ,[PracticeUserID]
      ,[CanViewAllClients]
  FROM [PracticeManagementSecure1].[dbo].[User]
  WHERE Username = 'UK\' + @Username

SELECT [strFullName]
      ,[UserId]
      ,[bActive]
      ,[strUserRoleName]
  FROM [TaxywinSecure1].[dbo].[User]
  WHERE UserId = @Username

SET @PracticeUserID = (SELECT PracticeUserID FROM [PracticeManagementSecure1].[dbo].[User] WHERE Username = 'UK\' + @Username)

SELECT *
FROM [PracticeManagementSecure1].[dbo].[PracticeUser]
WHERE PracticeUserID = @PracticeUserID

--BEGIN TRAN
	
--	UPDATE [TaxywinSecure1].[dbo].[User]
--	SET bActive = 0--, strUserRoleName = 'Read Only'
--	WHERE UserId = @Username

--	UPDATE [PracticeManagementSecure1].[dbo].[User]
--	SET --RoleID = '032C84B3-3388-496C-B8F6-DD243EE45B3E', 
--	CanViewAllClients = 1
--	WHERE Username = 'UK\' + @Username

--	UPDATE [PracticeManagementSecure1].[dbo].[PracticeUser]
--	SET IsActive = 0
--	WHERE PracticeUserID = @PracticeUserID

--ROLLBACK
--COMMIT

  /**
	strUserRoleName	bSystemRole
Administrator	1
Read Only	1
Standard	1
Super User	1

RoleID	Name
E6066E24-D5A9-4164-AA2F-5C245109C03A	Administrator
F9956301-B308-4D01-BA91-7BAE0F70228F	Super User
FD3D3193-D211-4501-942B-9CD29FA45C45	Standard
032C84B3-3388-496C-B8F6-DD243EE45B3E	Read Only
  **/
