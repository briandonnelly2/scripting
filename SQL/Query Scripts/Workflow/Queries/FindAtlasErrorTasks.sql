/****** Script for SelectTopNRows command from SSMS  ******/
USE [Sequence]

DECLARE @AWSUnsuc NVARCHAR(100) = 'ADF2B132-4E8D-4CD3-9DFB-1E78C70D18D9'
DECLARE @HelpDeskAWSUnsuc NVARCHAR(100) = '68F98A97-3C02-470A-9EBA-A5A0D9CF1CC7'
DECLARE @AtlasWebGUID NVARCHAR(100) = '68DA1268-183E-416C-A8E7-40593D834625'
DECLARE @AffectedClients TABLE(InstanceID INT)

INSERT INTO @AffectedClients 
SELECT [fldInstanceWfId] 

FROM [tblInstanceActivities]
	WHERE fldTemplateActivityGuid IN (@AWSUnsuc,@HelpDeskAWSUnsuc)
	AND fldStatus IN (0,1,2)
	AND fldCreationDate >= '2019-01-01 00:00:00.000'

SELECT   ia.fldCreationDate AS 'Attempted At'
		,uwf.GTSId AS 'GTS ID'
		,uwf.AtlasStepNumber AS 'Atlas Step Number'
		,c.ClientName
		,uwf.UserFriendlyResponseDescription
FROM [tblInstanceActivities] AS ia
INNER JOIN UWF787418f48bbf421cab89817d09118259 AS uwf on uwf.fldIWfId = ia.fldInstanceWfId
INNER JOIN [TaxWFPortalData]..[Clients] AS c ON c.ClientId = uwf.WorkItemClientId
WHERE fldTemplateActivityGuid = @AtlasWebGUID
AND ia.fldInstanceWfId IN (SELECT * FROM @AffectedClients)

ORDER BY [Attempted At]