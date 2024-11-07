
DECLARE @Username VARCHAR(100) = 'Rfoster1'
DECLARE @PracticeUserID NVARCHAR(100)

SELECT [Username]
      ,[IsSystem]
      ,[RoleID]
      ,[PracticeUserID]
      ,[CanViewAllClients]
  FROM [PracticeManagementCoE].[dbo].[User]
  WHERE Username = 'UK\' + @Username


SET @PracticeUserID = (SELECT PracticeUserID FROM [PracticeManagementCoE].[dbo].[User] WHERE Username = 'UK\' + @Username)

SELECT *
FROM [PracticeManagementCoE].[dbo].[PracticeUser]
WHERE PracticeUserID = @PracticeUserID

BEGIN TRAN

	UPDATE [PracticeManagementCoE].[dbo].[User]
	SET RoleID = '032C84B3-3388-496C-B8F6-DD243EE45B3E', 
	CanViewAllClients = 0
	WHERE Username = 'UK\' + @Username

	UPDATE [PracticeManagementCoE].[dbo].[PracticeUser]
	SET IsActive = 0
	WHERE PracticeUserID = @PracticeUserID

	SELECT [Username]
      ,[IsSystem]
      ,[RoleID]
      ,[PracticeUserID]
      ,[CanViewAllClients]
	FROM [PracticeManagementCoE].[dbo].[User]
	 WHERE Username = 'UK\' + @Username


	SELECT *
	FROM [PracticeManagementCoE].[dbo].[PracticeUser]
	WHERE PracticeUserID = @PracticeUserID

ROLLBACK
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
