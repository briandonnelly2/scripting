Declare @WorkItemId int = 298707
Declare @OffshoreWorkItemId int
Declare @OSWorkItemCount int 

USE [TaxWFPortalData]
SELECT @OSWorkItemCount = Count(*) FROM WorkItems WHERE CompletedDate IS NULL AND ParentWorkItemId = @WorkItemId 

IF (@OSWOrkItemCount = 1)

BEGIN

SELECT @OffshoreWorkItemId = WorkitemId FROM WorkItems WHERE CompletedDate IS NULL AND ParentWorkItemId = @WorkItemId 

UPDATE WorkItems SET CurrentActiveChildWorkItemId = NULL WHERE WorkItemId = @WorkItemId
PRINT 'Work Item No. '+CONVERT(NVARCHAR(10), @WorkItemId) +' has been updated to remove links to the offshore Work Item.'
DELETE FROM [dbo].[UserWorkItemLink] WHERE WorkItemId = @OffshoreWorkItemId
DELETE FROM [dbo].[WorkItemDeadlines] WHERE WorkItemId = @OffshoreWorkItemId
DELETE FROM [dbo].[WorkItemFeedback] WHERE WorkItemId = @OffshoreWorkItemId
DELETE FROM [dbo].[WorkItemMilestoneChange] WHERE WorkItemId = @OffshoreWorkItemId
DELETE FROM [dbo].[WorkItemOrgUnitLink] WHERE WorkItemId = @OffshoreWorkItemId
DELETE FROM [dbo].[WorkItemReportData] WHERE WorkItemId = @OffshoreWorkItemId
DELETE FROM [dbo].[WorkItemStateChange] WHERE WorkItemId = @OffshoreWorkItemId
DELETE FROM WorkItems WHERE WorkItemId = @OffshoreWorkItemId
PRINT 'Offshore Work Item No. '+CONVERT(NVARCHAR(10), @OffshoreWorkItemId) +' has been deleted.'
END

ELSE
BEGIN
	IF (@OSWOrkItemCount = 0)
	BEGIN
		PRINT 'Warning... No active offshore Work Items have been found for Work Item No. '+CONVERT(NVARCHAR(10), @WorkItemId) +'.'
	END
	ELSE
	BEGIN 
		PRINT 'ERROR... Multiple active offshore Work Items have been found for Work Item No. '+CONVERT(NVARCHAR(10), @WorkItemId) +'.'
	END
END
