USE [TaxWFPortalData]

DECLARE @ClientID INT = 56010

SELECT 	 cp.ClientId AS 'Client ID'
		,e.LeadClientId AS 'Lead Client Id'
		,e.OpportunityId
		,CASE e.BusinessServiceLineId
			WHEN 1 THEN 'CTC'
			WHEN 2 THEN 'PCC'
			WHEN 3 THEN 'GMS'
			WHEN 4 THEN 'Partnership Accounts'
			WHEN 5 THEN 'Transfer Pricing'
			ELSE 'N/A'
			END AS 'Business Stream'
		,e.[Description] AS 'Engagement Descrition'
		,cp.[Description] AS 'Client Period Description'
		,cp.ClientPeriodId 
		,cp.PeriodId
		,p.EngagementId
		,cp.SequenceInstanceId AS 'SeqInstID - ClientPeriod'
		,p.SequenceInstanceId AS 'SeqInstID - Period'
		,e.SequenceInstanceId AS 'SeqInstID - Engagement'
		,p.PeriodStartDate AS 'Period Start'
		,p.PeriodEndDate AS 'Period End'
		,p.TaxYearId AS 'Tax Year'
FROM ClientPeriods AS cp

LEFT JOIN [periods] AS p ON cp.periodid = p.PeriodId
LEFT JOIN Engagements AS e ON e.EngagementId = p.EngagementId

WHERE cp.ClientId = @ClientID