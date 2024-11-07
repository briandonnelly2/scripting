USE [ATLoaderUAT]

DECLARE @UserName NVARCHAR(100) = 'agray3'

SELECT [Id]
      ,[UserGroupId]
      ,[UserId]
      ,[IsDeleted]
  FROM [UserGroupMember]
  WHERE UserId = @UserName

  BEGIN TRAN

  UPDATE [UserGroupMember]
  SET IsDeleted = 1
  WHERE UserId = @UserName

  --ROLLBACK
  COMMIT