USE [Sequence]

DECLARE @MainProcessID INT = 7556699
DECLARE @And1GUID NVARCHAR(100) = '5429F41D-1087-43A3-A4E8-B2C47FBBB59C'
DECLARE @CompRec1GUID NVARCHAR(100) = 'E6184A6A-CC36-4279-81D2-2659552B62B7'
DECLARE @CompRec2GUID NVARCHAR(100) = '91999483-7BB2-48C9-990B-CDB3EC991400'
DECLARE @CompRec3GUID NVARCHAR(100) = '9A9612E6-B990-4A91-895D-BFD489E5588C'
DECLARE @CompOrgRecGUID NVARCHAR(100) = 'CF5DB0EC-57C4-41E5-AB67-FBB6A07C6585'

SELECT ia.[fldId]
      ,ia.[fldTemplateActivityGuid]
      ,ia.[fldInstanceWfId]
      ,case ia.fldStatus
			when 0 then 'Created'
			when 1 then 'Executing'
			when 2 then 'Idle'
			when 3 then 'Completed'
			when 4 then 'Deleting'
			when 5 then 'Deleted'
			when 6 then 'Aborting'
			when 7 then 'Aborted'
			else 'n/a'
			end as [Status]
	  ,ia.[fldCreationDate]
	  ,ia.[fldCompletionDate]
	  ,ta.fldName
	  ,ta.fldAlias
	FROM [Sequence].[dbo].[tblInstanceActivities] AS ia

	INNER JOIN [Sequence].[dbo].[tblTemplateActivities] AS ta ON ia.[fldTemplateActivityGuid] = ta.fldGuid

	WHERE ia.fldTemplateActivityGuid IN  (	'91498401-E844-4114-B5CE-16A1B6278093',
											'3680DAF4-FF34-407E-AF34-2537C2EB4A66',
											'C127D722-861C-4633-B6C7-3BC65BF36294',
											'65688C36-D08B-426A-8867-3E95C3617D97',
											'DB2515ED-4EFF-42F1-9C48-41A17F94C2C3',
											'E5108131-29D6-49E3-B578-43E77968ECC5',
											'6D80CABD-D492-442F-8A35-4E5A8B1D2F9C',
											'EF6291CD-3050-41F9-8115-50E4D365E67A',
											'E506D9B6-60DF-4CDD-B229-60C75907B213',
											'C3F88670-D8EE-4968-87A2-6EA485732A07',
											'0701BF98-AD4B-4D3C-B1F4-743912A61B1E',
											'1DB32AEA-DF5F-42A8-B23B-79AA383052D3',
											'4D75DFCB-C305-4875-BF73-7AD280030949',
											'1D7183AE-D72D-45BB-835F-97978ED66070',
											'26008202-C914-4697-BD0E-9EDAE97E2214',
											'31B15236-6296-4017-A780-B8CDF5C989BC',
											'A1CA760E-EA7C-4B58-819A-BB0AF153EDA4',
											'963B6285-464C-4F27-9993-BC155B10EC31',
											'7DFFAD99-B7C9-463A-8F87-DEAD8C68DB93',
											'5829879E-4C07-44C1-8DE3-E493A5B2E646',
											'9FE0C665-BACD-4E61-9F57-FC7D1A1B4B1F',
											'01AD006B-86FD-439E-919A-0FE3E607E687', --MS Ready for finalise prescreen
											'775B6416-8E9B-449D-A26A-4E0BE8DF1190', --MS OrganiserReceived
											'099B55A2-7461-46F2-8ABD-C89679AE8524', --MS Front Load Vault Upload Complete
											'72E33B0F-09AF-4D98-A9F4-D69ECA228D55', --MS FL Ready for Vault Upload
											'5A2202D1-00D9-4F2D-9937-918A098AA131', --swCreate Client In Digita
											'64FACBAE-84BD-41FD-B6C9-19017CE9DD55', --swInitial Review EXL Rework
											'096491D9-65A9-479E-9F31-76C68FE93F26', --MS ClientApproved
											'7937F5B4-3C78-4115-B8A6-81107E783502')  --Set Statutory Deadline
	--AND ia.fldStatus IN (0,1,2)
	AND ia.fldStatus = 0 AND ia.fldCreationDate >= '2019-01-01 00:00:00.000'


	--WHERE ia.fldTemplateActivityGuid = @And1GUID 
	--	AND ia.fldInstanceWfId = @MainProcessID

	ORDER BY ta.fldName