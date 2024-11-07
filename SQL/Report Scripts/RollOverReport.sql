/******   ******/

USE [TaxWFPortalData]

SELECT 
	--TOP 10	 
				 p.TaxYearId AS 'Year'
				,e.OpportunityId AS 'OppNumber'
				,e.EngagementId
				,e.[Description]
				,c.ClientName AS 'Lead Client Name'
				,b.[Description]
				,p.PeriodStartDate
				,p.PeriodEndDate
	FROM Engagements AS e
	INNER JOIN [Periods] AS p ON p.EngagementId = e.EngagementId
		INNER JOIN Clients AS c ON c.ClientId = e.LeadClientId
			INNER JOIN BusinessServiceLine AS b ON b.BusinessServiceLineId = e.BusinessServiceLineId
	WHERE p.TaxYearId = 2019 AND e.BusinessServiceLineId = 2