USE TaxWFPortalData

DECLARE @ClientID INT = 73089
DECLARE @NewName VARCHAR(100) = 'Pasterfield, Kate'
SELECT [ClientId] ,[ClientName] FROM [Clients] WHERE ClientId = @ClientID
SELECT [ClientId] ,[ForeignName] FROM [Links] WHERE ClientId = @ClientID

BEGIN TRANSACTION
UPDATE [Clients]
SET ClientName = @NewName
WHERE ClientId = @ClientID

UPDATE [Links]
SET ForeignName = @NewName
WHERE ClientId = @ClientID


SELECT [ClientId] ,[ClientName] FROM [Clients] WHERE ClientId = @ClientID
SELECT [ClientId] ,[ForeignName] FROM [Links] WHERE ClientId = @ClientID
--COMMIT
ROLLBACK