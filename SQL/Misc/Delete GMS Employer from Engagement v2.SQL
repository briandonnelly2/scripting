USE [TaxWFPortalData]
SET NOEXEC OFF
/**************************************/
/*			  USER INPUTS             */
/**************************************/
DECLARE @clientPeriodId int = 18252
/**************************************/

DECLARE @periodId int, @clientPeriodInstanceId int, @clientPeriodClientId int, @WorkItemCount int, @periodInstanceId int, @workItemYear int, @SequenceWorkItemCount int

SELECT @clientPeriodInstanceId = SequenceInstanceId, @periodId = PeriodId, @clientPeriodClientId = ClientId
FROM ClientPeriods
WHERE ClientPeriodId = @clientPeriodId

IF (@periodId IS NULL)
BEGIN
	PRINT 'No Client Period could be found for Id ' + CONVERT(NVARCHAR(100),@clientPeriodId) + '.  Please contact the development team for further assistance.'
	SET NOEXEC ON
END

SELECT @WorkItemCount = Count(*)  
FROM WorkItems
WHERE ClientPeriodId = @clientPeriodId

SELECT @SequenceWorkItemCount = Count(*)
FROM
	Sequence.dbo.tblInstanceWorkflows
WHERE 
	fldTemplateWfGuid = '9f16250d-d2be-404b-9bf0-f09c2fe2cba6'
AND
	fldSourceIWfId = @clientPeriodInstanceId
AND
	fldStatus != 7

IF (@WorkItemCount > 0)
BEGIN
	PRINT 'UNABLE TO DELETE - Work Items still exist for this client period.'
	SET NOEXEC ON
END

IF(@SequenceWorkItemCount > 0)
BEGIN
	PRINT 'UNABLE TO DELETE - Child GMS Tax Return Processes exist for this client period.' 
	SET NOEXEC ON
END

SELECT @periodInstanceId = SequenceInstanceId
FROM Periods
WHERE PeriodId = @periodId

SELECT @workItemYear = WorkItemYear 
FROM Sequence.dbo.uwffa14bc632fcd462ab88bff03a3757948
WHERE fldIWfId = @clientPeriodInstanceId

DELETE FROM ClientPeriods
WHERE ClientPeriodId = @clientPeriodId
PRINT 'Client Period ('+CONVERT(NVARCHAR(100),@clientPeriodId)+') deleted'

DELETE FROM Sequence.dbo.tblInstanceWorkflows
WHERE fldId = @clientPeriodInstanceId
PRINT 'Client Period Process ('+CONVERT(NVARCHAR(100),@clientPeriodInstanceId)+') deleted'

DELETE FROM Sequence.dbo.UACT910bad3d040c4db79d241ebe24dd008c
WHERE PeriodClientId = @clientPeriodClientId and fldIWfId = @clientPeriodInstanceId and WorkItemYear = @workItemYear
PRINT 'Work items to be created deleted'

DELETE FROM Sequence.dbo.UACT6df269f3b3b34b85a68640cc044e9925
WHERE ClientId = @clientPeriodClientId and fldIWfId = @periodInstanceId
PRINT 'Company Period deleted'

DELETE FROM Sequence.dbo.uwffa14bc632fcd462ab88bff03a3757948
WHERE fldIWfId = @clientPeriodInstanceId
PRINT 'Variables for Client Period Process ('+CONVERT(NVARCHAR(100),@clientPeriodInstanceId)+') deleted'

PRINT 'Update Completed'

