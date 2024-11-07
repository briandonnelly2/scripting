USE [TaxWFPortalData]

DECLARE @OldSAPCode NVARCHAR(100) = '60138475'
DECLARE @NewSAPCode NVARCHAR(100) = '60596165'
DECLARE @ClientID NVARCHAR(100)

SELECT ClientID FROM Links WHERE ForeignCode = @OldSAPCode AND LinktypeId = 1

--Uncomment this section to update the SAP link
--BEGIN TRAN

--SET @ClientID = (SELECT ClientID FROM Links WHERE ForeignCode = @OldSAPCode AND LinktypeId = 1)

--UPDATE Links
--SET ForeignCode = @NewSAPCode, ForeignId = @NewSAPCode
--WHERE ClientId = @ClientID AND LinkTypeId = 1

--SELECT ClientID FROM Links WHERE ForeignCode = @NewSAPCode AND LinktypeId = 1

--ROLLBACK
----COMMIT