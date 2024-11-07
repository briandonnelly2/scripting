USE TaxWFPortalData

DECLARE @BBEID NVARCHAR(40) = '9831013B-0174-4733-A086-D9D3D9DABFA6'
DECLARE @ClientCode NVARCHAR(10) = '9053977'
DECLARE @ClientId NVARCHAR(10)
DECLARE @ClientName NVARCHAR(100) = 'Maxwell-Timmins, Zoe'
DECLARE @WfID INT = '12092765'

SET @ClientId = (SELECT ClientId FROM Links WHERE ForeignCode = @CLientCode AND LinkTypeId = 5)

SELECT * FROM Links WHERE ClientId = @ClientId

SELECT WcfForeignCode,WcfForeignId,WcfForeignName FROM [Sequence]..[UWF8f7af218fe6940d88aa39d9a0754a9b0] WHERE fldiwfid = @WfID

--UPDATE [Sequence]..[UWF8f7af218fe6940d88aa39d9a0754a9b0]
--SET WcfForeignCode = @ClientCode, WcfForeignId = @BBEID, WcfForeignName = @ClientName
--WHERE fldiwfid = @WfId

--DELETE FROM Links
--WHERE ClientId = @ClientId
--AND LinkTypeId = 2

--INSERT INTO Links (LinkTypeId,ForeignId,ClientId,IsPrimaryLink,ForeignName,ForeignCode)
--VALUES(2,@BBEID,@ClientId,1,@ClientName,@ClientCode)

--UPDATE Links 
--SET IsPrimaryLink = 0
--WHERE ClientId = @ClientId
--AND LinkTypeId = 5

--SELECT * FROM Links WHERE ForeignCode = @CLientCode

--UPDATE Links 
--SET ForeignId = @BBEID
--WHERE ClientId = @ClientId
--AND LinkTypeId = 2