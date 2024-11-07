USE [AlphataxCoE]

SELECT
--TOP 10 --Use for testing
	 e1.e1nam AS 'Node'
	,k2.k2Group AS 'Group'
	,f1.f1ctxident AS 'Company'
	,convert(varchar(10),g1perbdte,6) 'Period start'
	,convert(varchar(10),g1peredte,6) 'Period end'
	,f1.[f1ctxid] AS 'Company Number'
	,k2.[k2Taxref1] AS 'Tax Office'
	,k2.[k2Taxref2] + k2.[k2Taxref3] AS 'UTR'

FROM e1nodes e1
			   
			   INNER JOIN f1ctxfiles AS f1 ON e1.e1ident = f1.f1nodeid  
			   	INNER JOIN g1periods AS g1 ON f1.f1ctxid = g1.g1ctxid	      	
				INNER JOIN [k2taxwarehouse] k2 on k2.[k2perid]= g1.[g1perid]

WHERE f1.f1ctxid = 36967 --Enter a company number to search the database

--WHERE f1.f1nodeid NOT IN (88,91,92) --Removes JP Morgan, Restricted Clients, Slaters
--AND e1.e1nam != 'JP Morgan Archive' --Removes JP Morgan Archive Node

ORDER BY f1.[f1ctxid]