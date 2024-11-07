USE [TaxWFPortalData]

BEGIN TRANSACTION

Declare @WorkItemid int = 298707--298707

IF(EXISTS(SELECT * FROM WorkItems WHERE BusinessServiceLineId = 3 and WorkItemId = @WorkItemid))
BEGIN
	Declare @AssigneeGTSID int = 0, @ClientPeriodId int = 0, @ClientPeriodInstanceId int = 0, @PeriodId int, @WorkItemYear int = 0, @WorkItemClientId int = 0


	SELECT
		@WorkItemClientId = ClientId,
		@ClientPeriodId = ClientPeriodId
	FROM
		WorkItems
	WHERE
		WorkItemId = @WorkItemid


	SELECT
		@ClientPeriodInstanceId = SequenceInstanceId,
		@PeriodId = PeriodId	 
	FROM
		ClientPeriods
	WHERE
		ClientPeriodId = @ClientPeriodId

	SELECT
		@WorkItemYear = TaxYearId
	FROM
		Periods
	WHERE
		PeriodId = @PeriodId

	SELECT
		@AssigneeGTSID = ForeignId
	FROM
		Links
	WHERE
		LinkTypeId = 5
	AND
		ClientId = @WorkItemClientId
	PRINT 'DELETING RECORD FROM Sequence'
	DELETE FROM Sequence..UACT910bad3d040c4db79d241ebe24dd008c
	WHERE TempGTSID = @AssigneeGTSID and WorkItemYear = @WorkItemYear and fldIWfId = @ClientPeriodInstanceId


END
PRINT 'DELETING RECORD FROM Portal'
DELETE FROM [dbo].[UserWorkItemLink] WHERE WorkItemId = @WorkItemid
DELETE FROM [dbo].[WorkItemActiveTaskIndex] WHERE WorkItemId = @WorkItemid
DELETE FROM [dbo].[WorkItemDeadlineChange] WHERE WorkItemId = @WorkItemid
DELETE FROM [dbo].[WorkItemFeedback] WHERE WorkItemId = @WorkItemid
DELETE FROM [dbo].[WorkItemMilestoneChange] WHERE WorkItemId = @WorkItemid
DELETE FROM [dbo].[WorkItemOrgUnitIndex] WHERE WorkItemId = @WorkItemid
DELETE FROM [dbo].[WorkItemOrgUnitLink] WHERE WorkItemId = @WorkItemid
DELETE FROM [dbo].[WorkItemReportData] WHERE WorkItemId = @WorkItemid
DELETE FROM [dbo].[WorkItemStateChange] WHERE WorkItemId = @WorkItemid
DELETE FROM [dbo].[WorkItems] WHERE WorkItemId = @WorkItemid
DELETE FROM [dbo].[WorkItemDeadlines] WHERE WorkItemId = @WorkItemid

--ROLLBACK TRANSACTION
COMMIT TRANSACTION