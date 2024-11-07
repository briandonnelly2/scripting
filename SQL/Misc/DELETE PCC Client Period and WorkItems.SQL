GO
SET NOEXEC OFF
SET NOCOUNT ON

/**************************************/
/*			  USER INPUTS             */
/**************************************/
DECLARE @ClientPeriodId int = XXXX
/**************************************/



DECLARE @ClientsTableId int, @WorkItemInstanceId int, @WorkItemId int, @ClientPeriodInstanceId int
SELECT
	@ClientsTableId = c.fldId,
	@ClientPeriodInstanceId = cpv.fldIWfId,
	@WorkItemInstanceId = wiv.fldIWfId,
	@WorkItemId = wiv.WorkItemId
FROM
	UACT0a89d55ffca74e318adecc3fe3ab40a7 c	
JOIN
	UWF41793259602e4feebefd7b8036fe91b2 v on c.fldIWfId = v.fldIWfId
JOIN
	UWF4f56c5c2b0cc48a391f00af171e50c91 cpv on cpv.WorkItemYear = v.PeriodYear and c.ClientID = cpv.PeriodClientId and v.fldIwfId = cpv.PeriodInstanceId
LEFT JOIN
	UWF18a906256066421fba66e657330ec713 wiv on cpv.fldIWfId = wiv.ClientPeriodWorkflowInstanceId
WHERE
	cpv.PortalClientPeriodId = @ClientPeriodId
	

	
If(@ClientsTableId IS NULL)
BEGIN 
	PRINT 'Unable to find client period details'		
	SET NOEXEC ON
END

DECLARE @WorkItemStatus int 

SELECT 
	@WorkItemStatus = WorkItemStateId
FROM TaxWFPortalData.dbo.WorkItems
WHERE
	WorkItemId = @WorkItemId

IF(@WorkItemStatus = 2)
BEGIN
	PRINT 'The work item for this client period has been completed'		
	SET NOEXEC ON
END

DECLARE @SubWorkItemCount int = 0
IF(@WorkItemId > 0)
BEGIN
	DECLARE @DeleteInstanceId int
	
	DECLARE WorkItemCursor CURSOR FOR		
	SELECT
		SequenceInstanceId
	FROM TaxWFPortalData.dbo.WorkItems
	WHERE
		WorkItemId = @WorkItemId
	OR
		ParentWorkItemId = @WorkItemId
		
	OPEN WorkItemCursor
	
	FETCH NEXT FROM WorkItemCursor
	INTO @DeleteInstanceId
	 
	WHILE @@FETCH_STATUS = 0
	BEGIN
		DELETE FROM tblInstanceWorkflows
		WHERE fldId = @DeleteInstanceId
		
		DELETE FROM tblInstanceWorkflowsClosed
		WHERE fldId = @DeleteInstanceId
		
		FETCH NEXT FROM WorkItemCursor
		INTO @DeleteInstanceId
	END
	
	CLOSE WorkItemCursor
	DEALLOCATE WorkItemCursor
	
	DELETE FROM TaxWFPortalData.dbo.WorkItems
	WHERE
		WorkItemId = @WorkItemId
	OR
		ParentWorkItemId = @WorkItemId
		
	PRINT '---------------------------------------------------------'	
	PRINT 'Work Item and Sub Work Items Deleted'
	PRINT '---------------------------------------------------------'
END

DELETE FROM tblInstanceWorkflows
WHERE fldId = @ClientPeriodInstanceId

DELETE FROM tblInstanceWorkflowsClosed
WHERE fldId = @ClientPeriodInstanceId

DELETE FROM TaxWFPortalData.dbo.ClientPeriods
WHERE
	ClientPeriodId = @ClientPeriodId
	
DELETE FROM UACT0a89d55ffca74e318adecc3fe3ab40a7
WHERE fldId = @ClientsTableId
PRINT '---------------------------------------------------------'
PRINT 'Client Period Deleted'
PRINT '---------------------------------------------------------'

PRINT 'Success'
SET NOCOUNT OFF
