USE [TaxWFPortalData]
SET NOEXEC OFF

/**************************************/
/*			  USER INPUTS             */
/**************************************/
DECLARE @opportunityId int = 70120437
DECLARE @periodEndDate nvarchar(50) = '2019-04-05'
DECLARE @BusinessServiceLineId int = 3
/**************************************/

DECLARE @engagementId int, @periodId int, @periodInstanceId int
DECLARE @clientPeriodCount int = 0

SELECT @engagementId = EngagementId
FROM Engagements
WHERE OpportunityId = @opportunityId
AND BusinessServiceLineId = @BusinessServiceLineId

IF(@engagementId IS NULL)
BEGIN	
	PRINT 'Unable to find an engagement with opportunity ID ' + CONVERT(nvarchar(10),@OpportunityID) +' and service line ID 1.'		
	SET NOEXEC ON
END

SELECT @periodId = PeriodId, @periodInstanceId = SequenceInstanceId
FROM Periods
WHERE EngagementId = @engagementId
AND PeriodEndDate = @periodEndDate

IF(@periodId IS NULL)
BEGIN	
	PRINT 'Unable to find a period ending ' + @periodEndDate +'.'		
	SET NOEXEC ON
END

SELECT @clientPeriodCount = COUNT(ClientPeriodId)
FROM ClientPeriods
WHERE PeriodId = @periodId

IF(@clientPeriodCount = 1)
BEGIN	
	PRINT 'Unable to delete period as there is still 1 active work item attached to this period.'		
	SET NOEXEC ON
END
IF(@clientPeriodCount > 1)
BEGIN	
	PRINT 'Unable to delete period as there are still ' + CONVERT(nvarchar(10), @clientPeriodCount) + ' active work items attached to this period.'		
	SET NOEXEC ON
END

DELETE FROM Sequence.dbo.tblInstanceWorkflows
WHERE fldId = @periodInstanceId
PRINT 'Deleted Period process Id ' + CONVERT(NVARCHAR(10), @periodInstanceId)


DELETE FROM Periods
WHERE PeriodId = @periodId
PRINT 'Deleted Period ending' + @periodEndDate
