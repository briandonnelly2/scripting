/****** Script for SelectTopNRows command from SSMS  ******/
SELECT TOP (1000) [UserID]
      ,[UserLoginID]
      ,[FirstName]
      ,[LastName]
      ,[EmailID]
      ,[RoleID]
      ,[Telephone]
      ,[Mobile]
      ,[CreatedBy]
      ,[CreatedDate]
      ,[LastUpdatedBy]
      ,[LastUpdatedDate]
      ,[IsActive]
  FROM [ACE_UAT].[dbo].[GMS_ACEUser]

  BEGIN TRAN

  INSERT INTO [ACE_UAT].[dbo].[GMS_ACEUser] (UserLoginID,FirstName,LastName,EmailID,RoleID,CreatedBy,LastUpdatedBy,IsActive)
  VALUES('briandonnelly2','Brian','Donnelly','brian.donnelly@kpmg.co.uk',1,1,1,1)

  ROLLBACK
  --COMMIT