USE [TaxywinCoE]

GO
;WITH ftc AS (
	SELECT DISTINCT lclientid
					,[strCountry]
					,[strDescription]
					,[cForeignTaxPaid]
					,[cGross]
					,[nYear]
					,[cForeignTaxCreditRelief]

	FROM [ForeignTaxCreditRelief]

	WHERE nYear in ('2017','2018')
	AND [strDescription] like '%jpmorgan%'
	OR [strDescription] like '%JP Morgan%'
	OR [strDescription] like '%JPMC%'
)
SELECT DISTINCT  c.Surname
				,c.Firstnames
				,c.refcode AS [GTS ID]
				,c.[taxref] AS [UTR]
				,ftc.[strDescription] AS [Employer]
				,ftc.nYear
				,ftc.[strCountry] AS [Country Code - A]
				,ftc.[cForeignTaxPaid] AS [Foreign Tax Paid - C]
				--,ofi.bClaimForeigntaxAsDeduction AS [FTC Relief Claimed - E]
				,ftc.[cGross] AS [Taxable Amount - F]
				,ftc.cForeignTaxCreditRelief

FROM client c

INNER JOIN ftc ON ftc.lclientid = c.clientid  and ftc.nyear in ('2017','2018')

--LEFT JOIN OtherForeignIncome ofi ON c.CLIENTID = ofi.CLIENTID AND ofi.[YEAR]  = '2018'

ORDER BY c.Surname,ftc.nYear

