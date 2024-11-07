USE [TaxywinCOE]

GO

DECLARE @Year INT = '2019'

SELECT 

	p.Name
	,p.Refcode
	,c.[FirstNames]
	,c.[Surname]
	,c.[RefCode]
	,pc.[DateJoined] AS [Date Joined P'ship]
	,pin.[Year]
	,pin.[OLR_TradingBroughtForward] AS [Trading Overlap Profits Brought Forward]
	,pin.[OLR_TradingArising] AS [Trading Overlap Profits Arising]
	,pin.[OLR_TradingCarriedForward] AS [Trading Overlap Profits Carried Forward]
	,pin.[OLR_UntaxedCarriedForward] AS [Untaxed Investment Overlap Profits Carried Forward]

FROM [PartnershipIncome] pin

	INNER JOIN [Client] c WITH (NOLOCK) ON pin.[PL_ClientID] = c.[ClientID] AND pin.[Year] = @Year 
	INNER JOIN [Partnership] p WITH (NOLOCK) ON pin.[PL_PClientID] = p.[PClientID]
	LEFT JOIN [PartnershipClients] pc WITH (NOLOCK) ON pin.[PL_ClientID] = pc.[Clientid] 

WHERE

	pin.[Year] = @Year
	AND
	pc.[bIntegrationLocalLink] = 0

ORDER BY

	 p.[Name]
	,c.Surname
	,c.Firstnames
	,c.RefCode
	,pin.[Year]