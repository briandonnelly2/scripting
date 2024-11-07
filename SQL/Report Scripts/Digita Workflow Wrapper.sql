use [TaxWFPortalData]

declare @TaxYear int = 2019

;WITH DigitaInfo AS
(
SELECT  C.REFCODE AS [Client Code],
              C.FIRSTNAMES AS [First Name], 
              C.SURNAME AS [Surname],
              C.TaxRef AS [Tax ref], 
              C.[Partner] AS [Parter],  
              C.Manager AS [Manager],
              C.Senior AS [Senior], 
              C.Assistant AS [Assistant],
              N.strName AS [Employer Name],
              ISNULL(ORI.cForeignTaxCreditRelief,0) AS [FTCR],
              ISNULL(EE.cAmount,0) AS [Travel Expenses],
              ISNULL(N.cTaxDeducted,0) AS [Tax Deducted Box 6],
              ISNULL(N.bCompensationTaxDeducted,0) AS [Tax Included In PAYE Box 7],
              ISNULL(N.cGeneralExemption,0) AS [General Exemption Box 9],
              ISNULL(N.cForeignServiceExemption,0) AS [Foreign Service Exemption Box 10],
              ISNULL(N.cDisabilityExemption,0) AS [Disability Exemption Box 10],
              ISNULL(EF.cAmount,0) AS [Foreign Earnings Not Taxable Box 12],
              N.[Year] AS [TaxYear]

              FROM [DIGITATAX].TaxywinCoE.dbo.Client C
              INNER JOIN [DIGITATAX].TaxywinCoE.dbo.TaxForm TF ON c.CLIENTID = TF.CLIENTID
              INNER JOIN [DIGITATAX].TaxywinCoE.dbo.NewEmploy N ON TF.CLIENTID = N.ClientID AND TF.YEAR = N.Year
              LEFT JOIN (SELECT lEmployID, cAmount FROM [DIGITATAX].TaxywinCoE.dbo.EmployForeign WHERE lRefID = 20) EF ON N.lEmployID = EF.lEmployID
              INNER JOIN [DIGITATAX].TaxywinCoE.dbo.OtherReturnInfo ORI ON C.CLIENTID = ORI.lClientID  AND TF.Year = ORI.nYear
              LEFT JOIN (SELECT lEmployID, cAmount FROM [DIGITATAX].TaxywinCoE.dbo.EmployExpenses WHERE lRefID = 10) EE ON N.lEmployID = EE.lEmployID

              WHERE TF.[Year] = @TaxYear
       )

select cl.ForeignCode as ClientId
       ,cl.ForeignName as ClientName
       ,l.ForeignCode as AssigneeGTSID
       ,l.ForeignName as AssigneeName
       ,di.[Client Code]
       ,di.[First Name]
       ,di.[Surname]
       ,di.[Tax ref] 
       ,di.[Parter]  
       ,di.[Manager]
       ,di.[Senior] 
       ,di.[Assistant]
       ,di.[Employer Name]
       ,di.[FTCR]
       ,di.[Travel Expenses]
       ,di.[Tax Deducted Box 6]
       ,di.[Tax Included In PAYE Box 7]
       ,di.[General Exemption Box 9]
       ,di.[Foreign Service Exemption Box 10]
       ,di.[Disability Exemption Box 10]
       ,di.[Foreign Earnings Not Taxable Box 12]
       ,di.[TaxYear]

from Engagements e
inner join Periods p on p.EngagementId = e.engagementid
inner join ClientPeriods cp on cp.PeriodId = p.PeriodId
inner join WorkItems wi on wi.clientperiodid = cp.clientperiodid
inner join links cl on cl.clientid = cp.clientid and cl.linktypeid = 6
inner join links l on l.clientid = wi.clientid and l.linktypeid = 5
inner join links dl on dl.clientid = wi.clientid and dl.linktypeid = 2
LEFT JOIN DigitaInfo AS di ON di.[Client Code] COLLATE DATABASE_DEFAULT = dl.ForeignCode COLLATE DATABASE_DEFAULT

where e.businessservicelineid = 3
and p.TaxYearId = @TaxYear
and wi.WorkItemTypeid = 3
--and cl.ForeignName = @ClientName

and l.ForeignCode IN
