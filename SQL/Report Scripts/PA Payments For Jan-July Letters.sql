---run on ukvmapp038 as the results have the carriage return known issue---

use [TaxWFPortalDataPA]

declare @TaxYear smallint
Set @TaxYear = '2018'

;with PCCReturns as
(
	select ct.[Description]
		,l.ForeignCode
		,l.ForeignName
		,l.ForeignId
		,witmt.overriddenname as CurrentStatus
		,wimc.changedon as LastSentToClient
		,rou.[Name] as RelationshipOffice
		,pou.[Name] as ProcessingOffice
		,e.OpportunityId as OpportunityId
	from workitems wi with (nolock)
	inner join clientperiods cp with (nolock) on cp.clientperiodid = wi.ClientPeriodId
	inner join Periods p with (nolock) on p.periodid = cp.periodid
	inner join WorkItemOrgUnitIndex wioui with (nolock) on wi.workitemid = wioui.workitemid
	inner join orgunit rou with (nolock) on rou.id = wioui.RelationshipUnitOrgUnitId
	inner join orgunit pou with (nolock) on pou.id = wioui.ProcessingUnitOrgUnitId
	inner join links l with (nolock) on l.clientid = wi.clientid and l.linktypeid = 2
	inner join workitemtypemilestonetype witmt on witmt.workitemmilestonetypeid = wi.workitemmilestonetypeid and witmt.WorkItemTypeId = wi.WorkItemTypeId
	inner join clients c on c.clientid = l.clientid
	inner join clienttypes ct on ct.clienttypeid = c.clienttypeid
	inner join engagements e on e.engagementid = p.engagementid
	left join (select WorkitemId, MAX(ChangedOn) as ChangedOn from WorkItemMilestoneChange with (nolock) where WorkItemMilestoneTypeId = 26 group by workitemid) as wimc on wimc.WorkItemId = wi.workitemid
	where wi.BusinessServiceLineId IN (2, 4)
	and p.TaxYearId = @TaxYear
	and wi.WorkItemStateId not in (3,4)
	and wi.parentworkitemid is null
),

DPMInfo as
(
	select   lc.isactive [Active in DPM]
	        ,p.DateOfDeath [Date of Death]
	        ,Convert(nvarchar(36),be.billableentityid) as billableentityid
			,be.ClientCode
			,be.FileAs
			--,udf.[Family/business group]
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
			--,udf.[Document Password] [Password]
			--,udf.[Exclude from mailshots]
			--,udf.[Email correspondence]
			--,rel.[Staff]
			--,rel.[Manager]

	from [DIGITATAX].PracticeManagementSecure1.dbo.billableentity be 

	inner join [DIGITATAX].PracticeManagementSecure1.dbo.listcache lc on lc.billableentityid = be.billableentityid
	inner join [DIGITATAX].PracticeManagementSecure1.dbo.practiceclient pc on pc.practiceclientid = lc.practiceclientid
	inner join [DIGITATAX].PracticeManagementSecure1.dbo. person p on p.personid = lc.personid
	left join [DIGITATAX].PracticeManagementSecure1.dbo.postalcontact posc on lc.postalcontactid = posc.postalcontactid
	left join [DIGITATAX].PracticeManagementSecure1.dbo.[Country] cou on cou.[CountryID] = posc.[CountryID]
	left join [DIGITATAX].PracticeManagementSecure1.dbo.practiceperson pp on p.personid = pp.personid
	left join [DIGITATAX].PracticeManagementSecure1.dbo.emailcontact email on lc.emailcontactid = email.emailcontactid
	left join [DIGITATAX].PracticeManagementSecure1.dbo.PracticePerson pps ON lc.ClientSignatoryID = pps.PersonID
	left join [DIGITATAX].PracticeManagementSecure1.dbo.PracticeUser pu ON pps.PracticePersonID = pu.PracticePersonID
	left join [DIGITATAX].PracticeManagementSecure1.dbo.Employment emp ON pu.EmploymentID = emp.EmploymentID
	--left join [DIGITATAX].PracticeManagementSecure1.dbo.KPMG_TrackerReporting_UDFs udf on udf.billableentityidudf = be.billableentityid 
	--left join [DIGITATAX].PracticeManagementSecure1.dbo.KPMG_TrackerReporting_Relationships rel on rel.billableentityidrel = be.billableentityid

	--where lc.isactive = '1'
	
),

FinalInstallment as --January 
(
	select c.EntityId
		,max(pi2.description) as InstalmentDescription
		,max(pi2.amount) as InstalmentAmount
		,sum(pa.amount) as AdjustmentAmount
	from  [DIGITATAX].TaxywinSecure1.dbo.client as c 
	inner join [DIGITATAX].TaxywinSecure1.dbo.paymentinstalment as pi2 on c.CLIENTID = pi2.ClientID
	left join [DIGITATAX].TaxywinSecure1.dbo.paymentadjustment pa on pa.installmentid = pi2.installmentid
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
	from  [DIGITATAX].TaxywinSecure1.dbo.client as c 
	inner join [DIGITATAX].TaxywinSecure1.dbo.paymentinstalment as pi2 on c.CLIENTID = pi2.ClientID
	left join [DIGITATAX].TaxywinSecure1.dbo.paymentadjustment pa on pa.installmentid = pi2.installmentid
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
	from  [DIGITATAX].TaxywinSecure1.dbo.client as c 
	inner join [DIGITATAX].TaxywinSecure1.dbo.paymentinstalment as pi2 on c.CLIENTID = pi2.ClientID
	left join [DIGITATAX].TaxywinSecure1.dbo.paymentadjustment pa on pa.installmentid = pi2.installmentid
	where (pi2.[Year] = @TaxYear + 1)
	and pi2.type = 2
	group by c.entityid 
),

OtherReturnInfo As
(
	select c.EntityId
		,ori.bCollectedTaxThroughPAYE
	from  [DIGITATAX].TaxywinSecure1.dbo.client as c 
	inner join [DIGITATAX].TaxywinSecure1.dbo.otherreturninfo as ori on c.CLIENTID = ori.lClientID
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
	from  [DIGITATAX].TaxywinSecure1.dbo.client as c 
		LEFT JOIN [DIGITATAX].TaxywinSecure1.dbo.[Residence] r WITH (NOLOCK) ON c.[CLIENTID] = r.[lClientID] AND r.[nYear] = @TaxYear
		LEFT JOIN [DIGITATAX].TaxywinSecure1.dbo.[CRSA100] crs WITH (NOLOCK) ON c.[CLIENTID] = crs.[ClientID] AND crs.[TaxYear] = @TaxYear
		LEFT JOIN [DIGITATAX].TaxywinSecure1.dbo.[CRTaxRates] crtr WITH (NOLOCK) ON c.[CLIENTID] = crtr.clientid and crtr.taxyear = @TaxYear
	where 
		crs.[TaxYear] = @TaxYear
),

DPTClientCode AS
(
	select 		c.EntityId
				,c.[refcode]
	from  [DIGITATAX].TaxywinSecure1.dbo.client as c
)

select 
     di.FileAs
	,dpt.[refcode] AS [Client Code in DPT]
	,di.[Tax Reference]
	--,di.[Family/business group]
	--,di.[Manager]
	--,di.[Staff]
	,di.[Signatory Is]
	--,di.[Email correspondence]
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
	,pr.RelationshipOffice
	,pr.ProcessingOffice
	,pr.[Description] as ClientType
	,pr.OpportunityId
	,pr.CurrentStatus
	,pr.LastSentToClient
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
	,di.[Date of Death]
	--,di.[Password] [Document Password]
	

from PCCReturns pr

inner join DPMInfo di on di.billableentityid = pr.foreignid
left join FinalInstallment fi on fi.entityid = pr.foreignid COLLATE Latin1_General_CI_AS_KS_WS
left join InterimInstallment ii on ii.entityid = pr.foreignid COLLATE Latin1_General_CI_AS_KS_WS
left join InterimInstallment2 ii2 on ii2.entityid = pr.foreignid COLLATE Latin1_General_CI_AS_KS_WS
left join otherreturninfo ori on ori.entityid = pr.foreignid COLLATE Latin1_General_CI_AS_KS_WS
left join ResidenceInfo resi on resi.entityid = pr.foreignid COLLATE Latin1_General_CI_AS_KS_WS
left join DPTClientCode dpt on dpt.entityid = pr.foreignid COLLATE Latin1_General_CI_AS_KS_WS

        LEFT JOIN (
                SELECT
                        c.EntityID,
                        SUM(payi.Amount) AS Amount,
                        SUM(paya.Amount) AS Adjustment,
                        MAX(paya.Description) AS Reason
                FROM
                        [DIGITATAX].TaxywinSecure1.dbo.Client c
                        LEFT JOIN [DIGITATAX].TaxywinSecure1.dbo.PaymentInstalment payi ON c.ClientID = payi.ClientID
                        LEFT JOIN [DIGITATAX].TaxywinSecure1.dbo.PaymentAdjustment paya ON payi.InstallmentID = paya.InstallmentID
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