
USE TaxywinCOE

SELECT C.REFCODE AS [Client Code],
	C.FIRSTNAMES , 
	C.SURNAME ,
	C.Partner, 
	C.Manager,
	C.Senior, 
	C.Assistant,
	N.strName AS [Employer Name],
	ISNULL(N.cPaymentsMinusReliefs,0) AS [AI Box 5 Redundancy],
	ISNULL(N.cTaxDeducted,0) AS [AI Box 6 Tax Taken Off],
	ISNULL(N.cGeneralExemption,0) AS [AI Box 9 Compensation],
	ISNULL(N.cDisabAndForeignServRelief,0) AS [AI Box 10 Disability],
	ISNULL(EF.cAmount,0) AS [AI Box 12 Not Taxable],
	ISNULL(ORI.cForeignTaxCreditRelief,0) AS [FP Box 2 FTCR],
	ISNULL(N.strCountryCode,'') AS [FP6A Country Code],
	ISNULL(EF1.cAmount,0) AS [FP6C Foreign Tax Paid],
	ISNULL(EE.cAmount,0) AS [E Box 17 Travel Expenses],
	ISNULL(R.bNotResidentUKThisYear, 0) As [RR1 Box 1 Not UK Resident 1718],
	ISNULL(R.bEligibleOverseasWorkdayReliefCY, 0) As [RR1 Box 2 Eligible OWR 1718],
	ISNULL(R.bSomeForeignEarningsEarlierYear,  0) AS [RR1 Box 5 Foreign Earnings For EY],
	ISNULL(R.bPersonalAllowancesOther,0) AS [RR2 Box 16 - Claim PA Other],
	ISNULL(R.[sCountryNatResOneCode],'') AS [RR2 Box 17 Country 1],
	ISNULL(R.[sCountryNatRestwoCode],'') AS [RR2 Box 17 Country 2],
	ISNULL(R.[sCountryNatResThreeCode],'') AS [RR2 Box 17 Country 3],
	ISNULL(R.bDomicileOutsideUK,0) AS [RR2 Box 23 - Domicile Outside UK],
	ISNULL(CONVERT(NVARCHAR(MAX),R.dtBornOutsideUK,103),'') AS [RR2 Box 27 - Date Came To UK],
	CASE WHEN ISNULL(TF.cOverallTaxDueTotal,0) < 0 THEN ISNULL(0-TF.cOverallTaxDueTotal,0) ELSE 0 END  AS [TC1 Box 2 Total Tax Overpaid],
	N.Year 
FROM Client C
	INNER JOIN TaxForm TF ON C.CLIENTID = TF.CLIENTID
	INNER JOIN NewEmploy N ON TF.CLIENTID = N.ClientID AND TF.YEAR = N.Year
	LEFT JOIN (SELECT lEmployID, cAmount FROM EmployForeign WHERE lRefID = 20) EF ON N.lEmployID = EF.lEmployID
	INNER JOIN OtherReturnInfo ORI ON C.CLIENTID = ORI.lClientID  AND TF.Year = ORI.nYear
	LEFT JOIN (SELECT lEmployID, cAmount FROM EmployForeign WHERE lRefID =70) EF1 ON N.lEmployID = EF1.lEmployID
	LEFT JOIN (SELECT lEmployID, cAmount FROM EmployExpenses WHERE lRefID = 10) EE ON N.lEmployID = EE.lEmployID
	LEFT JOIN Residence R ON TF.ClientID = R.lClientID AND TF.Year = R.nYear
--optional employer name clause
WHERE  TF.YEAR = 2018
--ANDN.strName LIKE 'Global Mobility%'

AND


c.refcode 

 IN
 (
 ''
 )

order by c.surname

/**
	AI2Box12 as
(
	select 
	ne.lemployid
	,ne.clientid
	,ef.cAmount
	,ne.cBenefitsTotalRemittance
	,ne.cDisabAndForeignServRelief
	--,ne.cForeignServiceReduction
	--,ne.cForeignServiceLumpSum
	,ne.cGeneralExemption
	--,ne.cLumpSumLimit
	,ne.cEQPensionAATaxDue
	from NewEmploy ne 
	left join EmployForeign ef on ef.lemployid = ne.lemployid
	where ef.lrefid = 20 AND [year] = @Year
),

	AI2Box12v2 as
(
	select 
	ne.lemployid
	,ne.clientid
	,ef.cAmount
	,ne.bTravelAndSubs
	from NewEmploy ne 
	left join EmployForeign ef on ef.lemployid = ne.lemployid
	where ef.lrefid = 10 AND [year] = @Year
),
)

LEFT JOIN AI2Box12 a on a.clientid = c.clientid
LEFT JOIN AI2Box12v2 av2 on av2.clientid = c.clientid

,isnull(a.cAmount,0) + isnull(a.cBenefitsTotalRemittance,0) + isnull(av2.cAmount,0) AS [AI2Box12]
**/