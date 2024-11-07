USE [TaxWFPortalData]

DECLARE @engName nvarchar(200) = 'Givaudan International SA GMS 2016-2018'

SELECT e.EngagementId, e.BusinessServiceLineId, cp.ClientId, e.SequenceInstanceId [Sequence - Engagement], e.OpportunityId, e.Description, 
p.PeriodId, p.SequenceInstanceId [Sequence - Period], p.Description [Tax Year],
cp.ClientPeriodId, cp.SequenceInstanceId [Sequence - ClientPeriod], cp.Description
FROM Engagements e
LEFT JOIN Periods p on e.EngagementId = p.EngagementId
LEFT JOIN ClientPeriods cp on p.PeriodId = cp.PeriodId

WHERE e.Description = @engName
