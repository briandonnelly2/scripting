USE [TaxSRTv2_Web_Test2]
GO

INSERT INTO [dbo].[User]
           ([FirstName]
           ,[LastName]
           ,[UserName]
           ,[AuthenticationTypeID]
           ,[Active]
           ,[Deleted]
           ,[IsTemp]
           ,[IsLocked])
     VALUES
		   ('Pawan','Jahagirdar', 'pawanjahagirdar', '1', '1','0','0','0'),
		   ('Philip','Ratcliff', 'pratcliff', '1', '1','0','0','0'),
		   ('Kartikey','Srivastava', 'ukrcsrivastav', '1', '1','0','0','0')
GO
