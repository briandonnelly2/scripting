/****** Script to cleanup the years left on an engagement after a delete  ******/
GO
SET NOEXEC OFF
SET NOCOUNT ON
/******			User Inputs               ******/
DECLARE @OpportunityID INT = 7654327

/******									  ******/
SET XACT_ABORT ON;


DECLARE @ServiceLine INT = 2 --2 for PCC
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
DECLARE @YearDeleted INT = (SELECT MAX(PeriodYear) FROM [Sequence].[dbo].UWF41793259602e4feebefd7b8036fe91b2 WHERE EngagementInstanceId = @EngSeqId AND EngagementId = @EngId)+1

DECLARE @FirstTaxYear INT 
DECLARE @PeriodLength INT
SELECT @FirstTaxYear= FirstTaxYear, @PeriodLength = LengthValue FROM [Sequence].[dbo].UACT30482307f98f43e0be104b62bf553f45 WHERE fldIWfId = @EngSeqId

DECLARE @RemainingYears INT = @PeriodLength - (@YearDeleted - @FirstTaxYear)

IF(@RemainingYears < 1 OR @RemainingYears > 3)
	BEGIN 
		PRINT '@RemainingYears'+  CONVERT(nvarchar(10),@RemainingYears) + 'is invalid. @YearDeleted is too high or too low. Aborting Execution.'		
		SET NOEXEC ON
	END
	
IF((SELECT EngagementYearsRemaining FROM [Sequence].[dbo].UWF4a5eadb0cd0b419db25fff8b1ffe931d WHERE fldIWfId = @EngSeqId)=@RemainingYears)
	BEGIN
		PRINT 'Remaining years already set correctly. Aborting Execution.'
		SET NOEXEC ON
	END

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

SELECT @WorkflowActivePeriodCount  = @WorkflowActivePeriodCount + COUNT(*)
FROM [Sequence].[dbo].tblInstanceWorkflowsClosed
WHERE fldSourceIWfId = @EngId
AND fldCompletionDate IS NULL
AND fldStatus IN (0, 1, 2)


DECLARE @WorkflowActiveClientPeriodCount int = (
												SELECT COUNT(*) 
												FROM @WorkflowInstance
												WHERE LevelID =2 
												)


IF (@PortalPeriodCount <> (@PeriodLength - @RemainingYears))
	BEGIN
		PRINT 'Too many/little periods kicked off. ' + CONVERT(nvarchar(10),@PortalPeriodCount) +' Portal periods found expected '+ CONVERT(nvarchar(10),(@PeriodLength - @RemainingYears)) +'. Aborting Execution.'
		SET NOEXEC ON
	END

IF (@WorkflowActivePeriodCount <> (@PeriodLength - @RemainingYears))
	BEGIN
		PRINT 'Too many/little periods kicked off. ' + CONVERT(nvarchar(10),@WorkflowActivePeriodCount) +' Sequence periods found expected '+ CONVERT(nvarchar(10),(@PeriodLength - @RemainingYears)) +'. Aborting Execution.'
		SET NOEXEC ON
	END


IF (@WorkflowActiveClientPeriodCount > (@PeriodLength - @RemainingYears))
	BEGIN
		PRINT 'Too many client Periods Kicked off and still active. Aborting Execution.'
		SET NOEXEC ON
	END


SET NOCOUNT OFF
PRINT 'Starting Restore.'

BEGIN TRANSACTION
	UPDATE [Sequence].[dbo].UWF4a5eadb0cd0b419db25fff8b1ffe931d SET EngagementYearsRemaining = @RemainingYears WHERE fldIWfId = @EngSeqId
COMMIT TRANSACTION

PRINT 'Period years left successfully restored.'
SET NOEXEC OFF
GO