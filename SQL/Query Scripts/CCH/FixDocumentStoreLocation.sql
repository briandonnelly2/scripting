USE [CCHCentral_UAT]
Select * from dbo.documentstorelocation

BEGIN TRAN
UPDATE dbo.documentstorelocation

SET Location = 'net.tcp://UKVMURDS1002:20555/FileStoreManager'

WHERE [Location] = 'net.tcp://UKWATWTS167:20555/FileStoreManager'

Select * from dbo.documentstorelocation
--ROLLBACK

COMMIT