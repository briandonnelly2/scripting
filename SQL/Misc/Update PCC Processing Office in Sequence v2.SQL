DECLARE @WorkflowInstanceId int = 9669596
DECLARE @WorkItemId int
DECLARE @SequenceProcessingOffice NVARCHAR(255)

SELECT
	@WorkItemId = WorkItemId, 
	@SequenceProcessingOffice = ProcessingOffice
FROM
	UWF18a906256066421fba66e657330ec713
WHERE
	fldIWfId = @WorkflowInstanceId

DECLARE @PortalProcessingOffice NVARCHAR(255)
SELECT 
	@PortalProcessingOffice = (case when OrgPathDescription like 'PCC > CoE >%' THEn 'CoE' ELSE o.Name END)
FROM
	TaxWFPortalData.dbo.WorkItemOrgUnitLink wol
JOIN
	TaxWFPortalData.dbo.OrgUnit o on wol.OrgUnitId = o.Id
WHERE
	WorkItemId = @WorkItemId
AND
	LinkTypeId = 2
IF(@SequenceProcessingOffice != @PortalProcessingOffice)
BEGIN
	UPDATE
		UWF18a906256066421fba66e657330ec713
	SET
		ProcessingOffice = @PortalProcessingOffice
	WHERE
		fldIWfId = @WorkflowInstanceId

	PRINT 'Processing office updated to: ' + @PortalProcessingOffice
END
ELSE
BEGIN
	PRINT 'Processing office already up-to-date.'
END

