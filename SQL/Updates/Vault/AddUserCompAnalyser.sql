USE [CompensationAnalyser_Dev]
GO

INSERT INTO [dbo].[Users]
           ([FirstName]
           ,[LastName]
           ,[UserName]
           ,[RestrictedClientAccess]
           ,[UsFtcReviewer]
           ,[KGSUser]
           ,[EmailAddress]
           ,[Active])
     VALUES
           ('Pawan','Jahagirdar', 'pawanjahagirdar', '1', '0', '0', 'Pawan.Jahagirdar@kpmg.co.uk', '1'),
		   ('Philip','Ratcliff', 'pratcliff', '1', '0', '0', 'Philip.Ratcliff@kpmg.co.uk', '1'),
		   ('Kartikey','Srivastava', 'ukrcsrivastav', '1', '0', '0', 'Kartikey.Srivastava@kpmg.co.uk', '1')
GO