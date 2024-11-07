USE [Sequence]
SET NOEXEC OFF
/**************************************/
/*			  USER INPUTS             */
/**************************************/
DECLARE @OpportunityID INT = X
DECLARE @ServiceLine INT = Y
/**************************************/

DECLARE @EngId INT = (SELECT EngagementId FROM [TaxWFPortalData].[dbo].[Engagements] Where OpportunityId = @OpportunityID AND BusinessServiceLineId = @ServiceLine)

IF(@EngId IS NULL)
	BEGIN 
		PRINT 'Unable to find an engagement with opportunity ID ' + CONVERT(nvarchar(10),@OpportunityID) +' and service line ID ' + CONVERT(nvarchar(10),@ServiceLine)  + '.'		
		SET NOEXEC ON
	END

DECLARE @EngSeqId INT = (SELECT SequenceInstanceId FROM [TaxWFPortalData].[dbo].[Engagements] Where EngagementId = @EngId)
DECLARE @PeriodCount INT = (SELECT COUNT(*) FROM [TaxWFPortalData].[dbo].[Periods] Where EngagementId = @EngId)

DECLARE @level int = 0  
DECLARE @levelCount int = 0

DECLARE @WorkflowInstance TABLE
(
	LevelId int
	,Id int
	,WorkflowIdentifier uniqueidentifier
)

INSERT INTO @WorkflowInstance  
SELECT @level LevelId, fldId, fldTemplateWfGuid 
FROM tblInstanceWorkflows 
WHERE fldId = @EngSeqId
AND fldCompletionDate IS NULL
AND fldStatus IN (0, 1, 2)

SELECT @levelCount = COUNT(Id)
FROM @WorkflowInstance
WHERE LevelId = @level

WHILE(@levelCount > 0)
BEGIN
	SET @level = @level + 1
	
	INSERT INTO @WorkflowInstance 
	SELECT @level LevelId, fldId, fldTemplateWfGuid
	FROM tblInstanceWorkflows 
	WHERE fldSourceIWfId IN( SELECT Id FROM @WorkflowInstance WHERE LevelId = @level -1)
	AND fldCompletionDate IS NULL
	AND fldStatus IN (0, 1, 2)
	
	
	SELECT @levelCount = COUNT(Id)
	FROM @WorkflowInstance
	WHERE LevelId = @level
END

DECLARE @ProcessCount INT = (SELECT COUNT(*) FROM @WorkflowInstance)

IF(@PeriodCount > 0)
	BEGIN
		PRINT 'Unable to delete engagement as ' + CONVERT(nvarchar(10),@PeriodCount) + ' period(s) have already been created.'		
	END
ELSE IF(@ProcessCount > 1)
	BEGIN
		PRINT 'Unable to delete engagement as it has progressed passed the engagement process and there are '+ CONVERT(nvarchar(10),@ProcessCount) + ' related active processes.'
	END
ELSE IF(@ProcessCount = 1)
	BEGIN
		DECLARE @SingleActiveProcess INT = (SELECT TOP 1 Id FROM @WorkflowInstance)

		IF(@SingleActiveProcess = @EngSeqId)
			BEGIN
				SELECT wi.Id, tw.fldName
				FROM @WorkflowInstance wi 
				left join tblTemplateWorkflows tw on wi.workflowidentifier = tw.fldGuid
				ORDER BY Id
				PRINT 'Unable to delete the engagement as the engagement process with ID "'+ CONVERT(nvarchar(10),@EngSeqId) + '" is still active.  Please see the results tab for details of the active process.'		
			END
		ELSE
			BEGIN
				PRINT 'Unable to delete the engagement as there are '+ CONVERT(nvarchar(10),@ProcessCount) + ' processes related to the engagement which are still active.  Please contact the development team for further assistance.'
			END
	END
ELSE IF ((@PeriodCount = 0) AND (@ProcessCount = 0))
	BEGIN
		DELETE FROM [TaxWFPortalData].[dbo].[EngagementOrgUnitLink] WHERE EngagementId = @EngId
		DELETE FROM [TaxWFPortalData].[dbo].[EngagementStaffRoles] WHERE EngagementId = @EngId
		DELETE FROM [TaxWFPortalData].[dbo].[Engagements] WHERE EngagementId = @EngId
		PRINT 'The engagement with Opportunity ID ' + CONVERT(nvarchar(10),@OpportunityID) +' has now been deleted from Workflow.'		 
	END