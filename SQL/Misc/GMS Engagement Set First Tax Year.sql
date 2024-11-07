/****** Script to update the first year and length of an engagement already kicked off  ******/
GO
SET NOEXEC OFF
SET NOCOUNT ON
/******			User Inputs               ******/
DECLARE @OpportunityID INT = 70085520
DECLARE @NewFirstYear INT = 2015
DECLARE @EngagementLength INT = 3
/******									  ******/
SET XACT_ABORT ON;


DECLARE @RemainingYears INT = @EngagementLength

IF(@EngagementLength >3 OR @EngagementLength < 1)
	BEGIN
		PRINT 'Engagement Lenth must be less than 3 years and at least one year. Aborting Execution.'
		SET NOEXEC ON
	END

IF(@RemainingYears > @EngagementLength)
	BEGIN
		PRINT 'Remaining Years must be less or equal to the Engagement Lenth. Aborting Execution.'
		SET NOEXEC ON
	END

DECLARE @ServiceLine INT = 3 --2 for PCC
DECLARE @EngId INT = (
						SELECT EngagementId 
						FROM [TaxWFPortalData].[dbo].[Engagements] 
						WHERE OpportunityId = @OpportunityID 
						AND BusinessServiceLineId = @ServiceLine
						)

IF(@EngId IS NULL)
	BEGIN 
		PRINT 'Unable to find an engagement with opportunity ID ' + CONVERT(nvarchar(10),@OpportunityID) +' for PCC Service Line.'		
		SET NOEXEC ON
	END

DECLARE @EngSeqId INT = (
						SELECT SequenceInstanceId 
						FROM [TaxWFPortalData].[dbo].[Engagements] 
						Where EngagementId = @EngId
						)

/*START OF CURRENT ACTIVE WORKFLOWS*/
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
FROM [Sequence].[dbo].tblInstanceWorkflows 
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
	FROM [Sequence].[dbo].tblInstanceWorkflows 
	WHERE fldSourceIWfId IN( SELECT Id FROM @WorkflowInstance WHERE LevelId = @level -1)
	AND fldCompletionDate IS NULL
	AND fldStatus IN (0, 1, 2)
	
	
	SELECT @levelCount = COUNT(Id)
	FROM @WorkflowInstance
	WHERE LevelId = @level
END
/*END OF CURRENT ACTIVE WORKFLOWS */



DECLARE @PortalPeriodCount INT = (
									SELECT COUNT(*) 
									FROM [TaxWFPortalData].[dbo].[Periods] 
									WHERE EngagementId = @EngId
									)



DECLARE @WorkflowActivePeriodCount int = (
											SELECT COUNT(*) 
											FROM @WorkflowInstance
											WHERE LevelID =1 
											)

DECLARE @WorkflowActiveClientPeriodCount int = (
												SELECT COUNT(*) 
												FROM @WorkflowInstance
												WHERE LevelID =2 
												)

IF (@PortalPeriodCount > 0)
	BEGIN
		PRINT 'This script does not yet support updating periods once kicked off. ' + CONVERT(nvarchar(10),@PortalPeriodCount) +' Portal Periods Found. '
		SET NOEXEC ON
	END

IF (@WorkflowActivePeriodCount>0)
	BEGIN
		PRINT 'This script does not yet support updating periods once kicked off. ' + CONVERT(nvarchar(10),@WorkflowActivePeriodCount) +' Sequence Periods Found. '
		SET NOEXEC ON
	END


IF (@WorkflowActiveClientPeriodCount > 0)
	BEGIN
		PRINT 'Client Periods Kicked off and still active. Aborting Execution.'
		SET NOEXEC ON
	END

IF (@WorkflowActiveClientPeriodCount != 0 AND @PortalPeriodCount !=0)
	BEGIN
		PRINT 'No Periods to delete. Aborting Execution.'
		SET NOEXEC ON
	END


SET NOCOUNT OFF

BEGIN TRANSACTION
	UPDATE [Sequence].[dbo].UWFc290eda2ea4a4d10aae393cd9755d309 SET EngagementYearsRemaining = @RemainingYears WHERE fldIWfId = @EngSeqId
	UPDATE [Sequence].[dbo].UACT4fa794a5131f4051a1085abaf6303419 SET FirstTaxYear = @NewFirstYear, LengthValue = @EngagementLength WHERE fldIWfId =@EngSeqId
COMMIT TRANSACTION


SET NOEXEC OFF
GO