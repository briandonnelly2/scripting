--script amended by Brian - removed old workflow and this script now pulls from Digita-TASK0157153
--script updated by Brian - Commented out document password field and added in date of birth at request of Michelle Gordon on TASK0211017

USE [PracticeManagementCoE]

declare @TaxYear smallint
Set @TaxYear = '2020'

;WITH DPMInfo as
(
	select   lc.isactive [Active in DPM]
			,p.DateOfBirth [Date of Birth]
	        ,p.DateOfDeath [Date of Death]
	        ,Convert(nvarchar(36),be.billableentityid) as billableentityid
			,be.ClientCode
			,be.FileAs
			,udf.[Family/business group]
			,lc.ClientSignatoryName AS [Signatory is]
			,emp.Position AS [Signatory position]
			,p.UniqueTaxReference AS [Tax reference]
			,isnull(pp.personal,'') as 'Personal'
			,isnull(pp.envelope,'') as 'Envelope'
			,isnull(posc.addressline1,'') as 'AddressLine1'
			,isnull(posc.addressline2,'') as 'AddressLine2'
			,isnull(posc.addressline3,'') as 'AddressLine3'
			,isnull(posc.town,'') as 'Town'
			,isnull(posc.county,'') as 'County'
			,isnull(posc.postcode,'') as 'Postcode'
			,isnull(cou.[Name],'') as 'Country'
			,email.Address AS Email
			,udf.[Document Password] [Password]
			,udf.[Exclude from mailshots]
			,udf.[Email correspondence]
			,rel.[Staff]
			,rel.[Manager]

	from billableentity be 

	inner join listcache lc on lc.billableentityid = be.billableentityid
	inner join practiceclient pc on pc.practiceclientid = lc.practiceclientid
	inner join  person p on p.personid = lc.personid
	left join postalcontact posc on lc.postalcontactid = posc.postalcontactid
	left join [Country] cou on cou.[CountryID] = posc.[CountryID]
	left join practiceperson pp on p.personid = pp.personid
	left join emailcontact email on lc.emailcontactid = email.emailcontactid
	left join PracticePerson pps ON lc.ClientSignatoryID = pps.PersonID
	left join PracticeUser pu ON pps.PracticePersonID = pu.PracticePersonID
	left join Employment emp ON pu.EmploymentID = emp.EmploymentID
	left join KPMG_TrackerReporting_UDFs udf on udf.billableentityidudf = be.billableentityid 
	left join KPMG_TrackerReporting_Relationships rel on rel.billableentityidrel = be.billableentityid
	inner join ClientGroupBillableEntity cgb on cgb.billableentityid=be.billableentityid
	inner join clientgroup cg on cg.ClientGroupID = cgb.ClientGroupID

	where lc.isactive = '1'
	and cg.[ClientGroupID] in ('7238B024-0AF3-44BA-85B5-7BDE668F1B36','F9DD3D47-5E95-439F-B8F6-CEE2CBE1267B')
	
),

FinalInstallment as --January 
(
	select c.EntityId
		,max(pi2.description) as InstalmentDescription
		,max(pi2.amount) as InstalmentAmount
		,sum(pa.amount) as AdjustmentAmount
	from  TaxywinCoE.dbo.client as c 
	inner join TaxywinCoE.dbo.paymentinstalment as pi2 on c.CLIENTID = pi2.ClientID
	left join TaxywinCoE.dbo.paymentadjustment pa on pa.installmentid = pi2.installmentid
	where (pi2.[Year] = @TaxYear + 1)
	and pi2.type = 3 
	group by c.entityid 
),

InterimInstallment as --January 
(
	select c.EntityId
		,max(pi2.description) as InstalmentDescription
		,max(pi2.amount) as InstalmentAmount
		,sum(pa.amount) as AdjustmentAmount
	from  TaxywinCoE.dbo.client as c 
	inner join TaxywinCoE.dbo.paymentinstalment as pi2 on c.CLIENTID = pi2.ClientID
	left join TaxywinCoE.dbo.paymentadjustment pa on pa.installmentid = pi2.installmentid
	where (pi2.[Year] = @TaxYear + 1)
	and pi2.type = 1 
	group by c.entityid 
),

InterimInstallment2 as --July
(
	select c.EntityId
		,max(pi2.description) as InstalmentDescription
		,max(pi2.amount) as InstalmentAmount
		,sum(pa.amount) as AdjustmentAmount
	from  TaxywinCoE.dbo.client as c 
	inner join TaxywinCoE.dbo.paymentinstalment as pi2 on c.CLIENTID = pi2.ClientID
	left join TaxywinCoE.dbo.paymentadjustment pa on pa.installmentid = pi2.installmentid
	where (pi2.[Year] = @TaxYear + 1)
	and pi2.type = 2
	group by c.entityid 
),

OtherReturnInfo As
(
	select c.EntityId
		,ori.bCollectedTaxThroughPAYE
	from  TaxywinCoE.dbo.client as c 
	inner join TaxywinCoE.dbo.otherreturninfo as ori on c.CLIENTID = ori.lClientID
	where ori.nYear = @TaxYear
),

ResidenceInfo AS
(
	select	 c.EntityId
			,r.[bNotDomiciledinUK]  --SA109, Domicile section, box 23
			,r.[dtBornOutsideUK] --SA109, Domicile section, box 27
			,crs.[RemittanceBasis] --SA109, Remittance basis section, box 28
			,r.bukresidentsevenyears --SA109, Remittance basis section, box 32
			,r.bUKResidentTwelveYears  --SA109, Remittance basis section, box 31
			,r.bUKResidentSeventeenYears  --SA109, Remittance basis section, box 30
			,crtr.RemittanceBasisCharge
	from  TaxywinCoE.dbo.client as c 
		LEFT JOIN TaxywinCoE.dbo.[Residence] r WITH (NOLOCK) ON c.[CLIENTID] = r.[lClientID] AND r.[nYear] = @TaxYear
		LEFT JOIN TaxywinCoE.dbo.[CRSA100] crs WITH (NOLOCK) ON c.[CLIENTID] = crs.[ClientID] AND crs.[TaxYear] = @TaxYear
		LEFT JOIN TaxywinCoE.dbo.[CRTaxRates] crtr WITH (NOLOCK) ON c.[CLIENTID] = crtr.clientid and crtr.taxyear = @TaxYear
	where 
		crs.[TaxYear] = @TaxYear
),

DPTClientCode AS
(
	select 		c.EntityId
				,c.[refcode]
	from  TaxywinCoE.dbo.client as c
)

select 
     di.FileAs
	,dpt.[refcode] AS [Client Code in DPT]
	,di.[Tax Reference]
	,di.[Family/business group]
	,di.[Manager]
	,di.[Staff]
	,di.[Signatory Is]
	,di.[Email correspondence]
	,isnull(fi.InstalmentDescription,'') as 'InstalmentDescription' 
	,isnull(fi.InstalmentAmount, '') as 'InstalmentAmount'
	,isnull(fi.AdjustmentAmount,'') as 'AdjustmentAmount'
	,isnull(ii.Instalmentdescription,'') as 'InstalmentDescription' 
	,isnull(ii.Instalmentamount, '') as 'InstalmentAmount'
	,isnull(ii.adjustmentamount,'') as 'AdjustmentAmount'
	,isnull(fi.InstalmentAmount,0) + isnull(fi.AdjustmentAmount,0) + isnull(ii.Instalmentamount,0) + isnull(ii.adjustmentamount,0) As 'Total Jan Payment'	
	,isnull(ii2.Instalmentdescription,'') as 'InstalmentDescription' 
	,isnull(ii2.Instalmentamount, '') as 'InstalmentAmount'
	,isnull(ii2.adjustmentamount,'') as 'AdjustmentAmount'
    ,CASE WHEN pay.Adjustment < 0 THEN 'Y' ELSE 'N' END AS 'Payment Reduced'
    ,CASE WHEN pay.Adjustment < 0 THEN pay.Amount + pay.Adjustment END AS 'Net Due'
	,resi.[RemittanceBasisCharge] AS 'RemittanceBasisCharge' -- Backing schedule, Other Charges - RBC	
	,resi.[bNotDomiciledinUK]  AS [SA109, Domicile section, box 23]
	,resi.[dtBornOutsideUK] AS [SA109, Domicile section, box 27]
	,resi.[RemittanceBasis] AS [SA109, Remittance basis section, box 28]
	,resi.[bUKResidentSeventeenYears] AS [UK Resident 17 of 20 Years -SA109, Remittance basis section, box 30]
	,resi.bUKResidentTwelveYears as [Resident 12 of 14 - SA109, Remittance basis section, box 31] 
	,isnull(resi.bukresidentsevenyears,0) as [UK Resident 7 of 9 Years -SA109, Remittance basis section, box 32]	
	,di.[Signatory position]
	,di.[Personal]
	,di.[Envelope]
	,di.[AddressLine1]
	,di.[AddressLine2]
	,di.[AddressLine3]
	,di.[Town]
	,di.[County]
	,di.[Postcode]
	,di.[Country]
	,di.[Email]
	,di.ClientCode AS [Client Code in DPM]
	,di.[Active in DPM]
	,di.[Date of Birth]
	,di.[Date of Death]
	--,di.[Password] [Document Password]
	

from DPMInfo di

left join FinalInstallment fi on fi.entityid = di.billableentityid --COLLATE Latin1_General_CI_AS_KS_WS
left join InterimInstallment ii on ii.entityid = di.billableentityid --COLLATE Latin1_General_CI_AS_KS_WS
left join InterimInstallment2 ii2 on ii2.entityid = di.billableentityid --COLLATE Latin1_General_CI_AS_KS_WS
left join otherreturninfo ori on ori.entityid = di.billableentityid --COLLATE Latin1_General_CI_AS_KS_WS
left join ResidenceInfo resi on resi.entityid = di.billableentityid --COLLATE Latin1_General_CI_AS_KS_WS
left join DPTClientCode dpt on dpt.entityid = di.billableentityid --COLLATE Latin1_General_CI_AS_KS_WS

        LEFT JOIN (
                SELECT
                        c.EntityID,
                        SUM(payi.Amount) AS Amount,
                        SUM(paya.Amount) AS Adjustment,
                        MAX(paya.Description) AS Reason
                FROM
                        TaxywinCoE.dbo.Client c
                        LEFT JOIN TaxywinCoE.dbo.PaymentInstalment payi ON c.ClientID = payi.ClientID
                        LEFT JOIN TaxywinCoE.dbo.PaymentAdjustment paya ON payi.InstallmentID = paya.InstallmentID
                WHERE
                        (payi.[Year] = @TaxYear + 1)
                        AND payi.[Description] = '2nd Interim instalment'
                GROUP BY
                        c.EntityID) pay ON di.BillableEntityID = pay.EntityID

order by
	 di.FileAs
	,di.ClientCode 
	,dpt.[refcode]
	

--where pr.lastsenttoclient is not null