/******   ******/

USE [TaxWFPortalDataPA]

SELECT DISTINCT
	--TOP 10	 
				 cp.ClientId
				,li.ForeignName AS 'Client Name'
				,ci.ComplexityCategory
				,ci.ComplexityDescription
				,li.ForeignCode AS 'Digita Code'
				,li.ForeignId AS 'BBE ID'
				,cag.[Description] AS 'Onshore/Offshore'
	FROM [ClientPeriods] AS cp 
	INNER JOIN WorkItems AS wi ON wi.ClientPeriodId = cp.ClientPeriodId
	INNER JOIN WorkItemComplexityIndex AS ci ON ci.WorkItemId = wi.WorkItemId
	INNER JOIN Links AS li ON li.ClientId = cp.ClientId
	INNER JOIN ClientAccessGroupClients AS cagc ON cagc.ClientId = cp.ClientId
	INNER JOIN ClientAccessGroup AS cag ON cag.ClientAccessGroupId = cagc.ClientAccessGroupId

	WHERE cp.PeriodId = 62 AND li.LinkTypeId = 2

	ORDER BY cp.ClientId