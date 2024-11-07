USE TaxWFPortalData

DECLARE @ClientID NVARCHAR(10)
DECLARE @PeriodID NVARCHAR(10)
DECLARE @EngagementID NVARCHAR(10)
DECLARE @OpportunityId NVARCHAR(10)

SET @ClientID = 3777
SELECT PeriodID FROM ClientPeriods WHERE ClientID = @ClientID
--SET @PeriodID = (SELECT PeriodId FROM ClientPeriods WHERE ClientID = @ClientID)
--SET @EngagementID = (SELECT EngagementId FROM [Periods] WHERE PeriodID = @PeriodID)
--SET @OpportunityId = (SELECT OpportunityId FROM Engagements WHERE EngagementID = @EngagementID)

--PRINT @PeriodID + N' is the PeriodId'
--PRINT @EngagementID + N' is the EngagementId'
--PRINT @OpportunityId + N' is the OpportunityId'

SELECT * FROM ClientPeriods WHERE --[Description] LIKE '%2018/2019%'
ClientID IN
('3619',
'3748',
'3766',
'3777',
'36404',
'36425',
'36464',
'36869',
'36874',
'37546',
'39039',
'39812',
'41193',
'41194',
'41195',
'41618',
'43236',
'44564',
'44888',
'52098')