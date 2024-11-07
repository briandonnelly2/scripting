USE [TaxWFPortalData]

/*********************************************/
/*            USER INPUTS                    */
/*********************************************/
DECLARE @ClientId INT = 61896
DECLARE @Offshore bit = 1
DECLARE @OldDigitaCode nvarchar(100) = '140143'
DECLARE @NewDigitaCode nvarchar(100) = 'BL60647762LN'
DECLARE @RemoveGMSAccessGroups bit = 1
/*********************************************/

DECLARE @ClientCount INT = (SELECT Count(*) FROM Links WHERE ClientId = @ClientId AND ForeignCode = @OldDigitaCode AND LinkTypeId = 2)

IF(@ClientCount <> 1)
	BEGIN
		PRINT 'INFORMATION... No clients were found with the information provided.'
	END
ELSE
	BEGIN 
		UPDATE Links SET ForeignCode = @NewDigitaCode WHERE ClientId = @ClientId AND ForeignCode = @OldDigitaCode AND LinkTypeId = 2
		PRINT 'INFORMATION... Updated the Digita client code.'

		IF(@Offshore = 1)
			BEGIN
				DELETE FROM ClientAccessGroupClients WHERE ClientId = @ClientId and ClientAccessGroupId IN (1,2)
				INSERT INTO [dbo].[ClientAccessGroupClients] ([ClientAccessGroupId],[ClientId]) VALUES (2,@ClientId)
				PRINT 'INFORMATION... Added the client to the PCC offshore client access group.'
				UPDATE ClientOSRCodes SET CanGoOffshore = @Offshore WHERE ClientId = @ClientId AND BusinessServiceLineId = 2
				PRINT 'INFORMATION... The PCC OSR code has been updated.'
			END
		ELSE
			BEGIN 
				DELETE FROM ClientAccessGroupClients WHERE ClientId = @ClientId and ClientAccessGroupId IN (1,2)
				INSERT INTO [dbo].[ClientAccessGroupClients] ([ClientAccessGroupId],[ClientId]) VALUES (1,@ClientId)
				PRINT 'INFORMATION... Added the client to the PCC onshore client access group.'
				UPDATE ClientOSRCodes SET CanGoOffshore = @Offshore WHERE ClientId = @ClientId AND BusinessServiceLineId = 2
				PRINT 'INFORMATION... The PCC OSR code has been updated.'
			END

		IF(@RemoveGMSAccessGroups = 1)
			BEGIN
				DELETE FROM ClientAccessGroupClients WHERE ClientId = @ClientId and ClientAccessGroupId IN (3,4)
				PRINT 'INFORMATION... Deleted the GMS client access groups.'
				UPDATE ClientOSRCodes SET CanGoOffshore = 0 WHERE ClientId = @ClientId AND BusinessServiceLineId = 3
				PRINT 'INFORMATION... Reset the GMS OSR code.'
			END
	END