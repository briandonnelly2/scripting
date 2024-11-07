use [TaxWFPortalData]

declare @TaxYear int
set @TaxYear = 2016
declare @DigitaInfo table (entityid nvarchar(50), Employer nvarchar(255), TR4Box4 money, TR4Box5 money
, AI2Box12GrossForeignPay money, AI2Box12AmountNotTaxable money, AI2Box12SeafarersForeignEarningsDeduction money, AI2Box12LessSeafarersDeductionRestriction money
, AI2Box12ForeignTaxClaimedDeduction money, AI2Box12AssessableForeignIncome money, AI2Box12ForeignTaxAvailableForFTCRelief money
, AI2Box14 money, E1Box11 money, E1Box15 money, E1Box17 money, E1Box1 money)

insert into @DigitaInfo
select be.billableentityid
	,ne.strName as [Employer]
	,coalesce(tr4.TR4Box4,0) as TR4Box4
	,coalesce(ga.TR4Box5,0) as TR4Box5
	,coalesce(ai212GFP.AI2Box12GrossForeignPay,0) as AI2Box12GrossForeignPay
	,coalesce(ai212ANT.AI2Box12AmountNotTaxable,0) as AI2Box12AmountNotTaxable
	,coalesce(ai212SFED.AI2Box12SeafarersForeignEarningsDeduction,0) as AI2Box12SeafarersForeignEarningsDeduction
	,coalesce(ai212LSDR.AI2Box12LessSeafarersDeductionRestriction,0) as	AI2Box12LessSeafarersDeductionRestriction
	,coalesce(ai212FTCD.AI2Box12ForeignTaxClaimedDeduction,0) as AI2Box12ForeignTaxClaimedDeduction
	,coalesce(ai212AFI.AI2Box12AssessableForeignIncome,0) as AI2Box12AssessableForeignIncome
	,coalesce(ai212FTC.AI2Box12ForeignTaxAvailableForFTCRelief,0) as AI2Box12ForeignTaxAvailableForFTCRelief
	,coalesce(ai214.AI2Box14,0) as AI2Box14
	,coalesce(ben.E1Box11,0) as E1Box11
	,coalesce(ben.E1Box15,0) as E1Box15
	,coalesce(ex.E1Box17,0) as E1Box17
	,coalesce(e1f.E1Foreign + e1u.E1UK + ne.cEqualisation,0) as E1Box1
from [DIGITATAX].PracticeManagementCoE.dbo.billableentity be 
inner join [DIGITATAX].TaxywinCoE.dbo.client c on c.entityid = be.billableentityid
inner join [DIGITATAX].TaxywinCoE.dbo.NewEmploy ne on ne.clientid = c.clientid and ne.[Year] = @TaxYear
left join (select 
			ne.lemployid
			,ef.cAmount as AI2Box12GrossForeignPay
			from [DIGITATAX].TaxywinCoE.dbo.NewEmploy ne 
			inner join [DIGITATAX].TaxywinCoE.dbo.EmployForeign ef on ne.lemployid = ef.lemployid
			where ef.lrefid = 10) ai212GFP on ne.lemployid = ai212GFP.lemployid
left join (select 
			ne.lemployid
			,ef.cAmount as AI2Box12AmountNotTaxable
			from [DIGITATAX].TaxywinCoE.dbo.NewEmploy ne 
			inner join [DIGITATAX].TaxywinCoE.dbo.EmployForeign ef on ne.lemployid = ef.lemployid
			where ef.lrefid = 20) ai212ANT on ne.lemployid = ai212ANT.lemployid
left join (select 
			ne.lemployid
			,ef.cAmount as AI2Box12SeafarersForeignEarningsDeduction
			from [DIGITATAX].TaxywinCoE.dbo.NewEmploy ne 
			inner join [DIGITATAX].TaxywinCoE.dbo.EmployForeign ef on ne.lemployid = ef.lemployid
			where ef.lrefid = 30) ai212SFED on ne.lemployid = ai212SFED.lemployid
left join (select 
			ne.lemployid
			,ef.cAmount as AI2Box12LessSeafarersDeductionRestriction
			from [DIGITATAX].TaxywinCoE.dbo.NewEmploy ne 
			inner join [DIGITATAX].TaxywinCoE.dbo.EmployForeign ef on ne.lemployid = ef.lemployid
			where ef.lrefid = 40) ai212LSDR on ne.lemployid = ai212LSDR.lemployid
left join (select 
			ne.lemployid
			,ef.cAmount as AI2Box12ForeignTaxClaimedDeduction
			from [DIGITATAX].TaxywinCoE.dbo.NewEmploy ne 
			inner join [DIGITATAX].TaxywinCoE.dbo.EmployForeign ef on ne.lemployid = ef.lemployid
			where ef.lrefid = 50) ai212FTCD on ne.lemployid = ai212FTCD.lemployid
left join (select 
			ne.lemployid
			,ef.cAmount as AI2Box12AssessableForeignIncome
			from [DIGITATAX].TaxywinCoE.dbo.NewEmploy ne 
			inner join [DIGITATAX].TaxywinCoE.dbo.EmployForeign ef on ne.lemployid = ef.lemployid
			where ef.lrefid = 60) ai212AFI on ne.lemployid = ai212AFI.lemployid
left join (select 
			ne.lemployid
			,ef.cAmount as AI2Box12ForeignTaxAvailableForFTCRelief
			from [DIGITATAX].TaxywinCoE.dbo.NewEmploy ne 
			inner join [DIGITATAX].TaxywinCoE.dbo.EmployForeign ef on ne.lemployid = ef.lemployid
			where ef.lrefid = 70) ai212FTC on ne.lemployid = ai212FTC.lemployid
left join (select p.strEmploymentScheduleId
				,sum(p.cEmployersContributionOverseas) as AI2Box14
			FROM [DIGITATAX].TaxywinCoE.[dbo].[plan] p WITH (NOLOCK)
			WHERE (p.[type] = 'OTHERPEN')
			AND p.[year] = @TaxYear
			group by p.strEmploymentScheduleId) ai214 on ne.strScheduleid = ai214.strEmploymentScheduleId
left join (select p.clientid
				,sum(p.NOWGROSS) as TR4Box4
			FROM [DIGITATAX].TaxywinCoE.[dbo].[plan] p WITH (NOLOCK)
			WHERE (p.[type] = 'OTHERPEN')
			AND p.[year] = @TaxYear
			and p.bNonUkScheme = 1
			group by p.clientid) tr4 on c.clientid = tr4.clientid
left join (select oo.clientid
				,sum(oo.cAmountPaidNet) as TR4Box5
			FROM [DIGITATAX].TaxywinCoE.[dbo].otherout oo
			WHERE oo.[type] = 'GAIDCOV'
			AND oo.[year] = @TaxYear
			group by oo.clientid) ga on ga.clientid = c.clientid
left join (select ne.lemployid
				,sum(case when eb.lRefId in (70,90) then eb.ctaxable else 0 end) as [E1Box9]
				,sum(case when eb.lRefId in (80,95) then eb.ctaxable else 0 end) as [E1Box10]
				,sum(case when eb.lRefId in (120) then eb.ctaxable else 0 end) as [E1Box11]
				,sum(case when eb.lRefId in (40,60) then eb.ctaxable else 0 end) as [E1Box12]
				,sum(case when eb.lRefId in (10,150) then eb.ctaxable else 0 end) as [E1Box13]
				,sum(case when eb.lRefId in (50) then eb.ctaxable else 0 end) as [E1Box14]
				,sum(case when eb.lRefId in (20,30,100,130,140,160,170,180,190,200) then eb.ctaxable else 0 end) as [E1Box15]
				,sum(case when eb.lRefId in (210,220,230,240,250,260,270) then eb.ctaxable else 0 end) as [E1Box16]
			from [DIGITATAX].TaxywinCoE.dbo.NewEmploy ne 
			inner join [DIGITATAX].TaxywinCoE.dbo.EmployBenefits eb on ne.lemployid = eb.lemployid
			group by ne.lemployid) ben on ben.lemployid = ne.lemployid
left join (select ne.lemployid
				,sum(case when eer.lRefId in (10) then ee.cAmount else 0 end) as E1Box17
				,sum(case when eer.lRefId in (20) then ee.cAmount else 0 end) as E1Box18
				,sum(case when eer.lRefId in (30) then ee.cAmount else 0 end) as E1Box19
				,sum(case when eer.lRefId in (40,50) then ee.cAmount else 0 end) as E1B20x9
			from [DIGITATAX].TaxywinCoE.dbo.NewEmploy ne 
			inner join [DIGITATAX].TaxywinCoE.dbo.EmployExpenses ee on ne.lemployid = ee.lemployid
			inner join [DIGITATAX].TaxywinCoE.dbo.EmployExpensesRef eer on eer.lrefid = ee.lrefid
			group by ne.lemployid) ex on ex.lemployid = ne.lemployid

left join (	select 
					ne.lemployid
					,ef.cAmount as E1Foreign
			from [DIGITATAX].TaxywinCoE.dbo.NewEmploy ne
			inner join [DIGITATAX].TaxywinCoE.dbo.EmployForeign ef on ne.lemployid = ef.lemployid			
			where ef.lrefid = 10) e1f on e1f.lemployid = ne.lemployid

left join (	select 
					ne.lemployid
					,euki.cAmount as E1UK
			from [DIGITATAX].TaxywinCoE.dbo.NewEmploy ne
			inner join [DIGITATAX].TaxywinCoE.dbo.EmployUKIncome euki on ne.lemployid = euki.lemployid
			where euki.lrefid = 10) e1u on e1u.lemployid = ne.lemployid

select cl.ForeignCode as ClientId
	,cl.ForeignName as ClientName
	,l.ForeignCode as AssigneeGTSID
	,l.ForeignName as AssigneeName
	,witmt.OverriddenName as CurrentMilestone
	,d.Employer
	,d.TR4Box4
	,d.TR4Box5
	,d.AI2Box12GrossForeignPay AS [GrossForeignPay]
	,d.AI2Box12AmountNotTaxable AS [AmountNotTaxable]
	,d.AI2Box12SeafarersForeignEarningsDeduction AS [SeafarersForeignEarningsDeduction]
	,d.AI2Box12LessSeafarersDeductionRestriction AS [LessSeafarersDeductionRestriction]
	,d.AI2Box12ForeignTaxClaimedDeduction AS [ForeignTaxClaimedAsADeduction]
	,d.AI2Box12AssessableForeignIncome AS [AssessableForeignIncome]
	,d.AI2Box12ForeignTaxAvailableForFTCRelief AS [ForeignTaxAvailableForFTCRelief]
	,d.AI2Box14
	,d.E1Box1
	,d.E1Box11
	,d.E1Box15
	,d.E1Box17
from Engagements e
inner join Periods p on p.EngagementId = e.engagementid
inner join ClientPeriods cp on cp.PeriodId = p.PeriodId
inner join WorkItems wi on wi.clientperiodid = cp.clientperiodid
inner join links cl on cl.clientid = cp.clientid and cl.linktypeid = 6
inner join links l on l.clientid = wi.clientid and l.linktypeid = 5
inner join links dl on dl.clientid = wi.clientid and dl.linktypeid = 2
inner join workitemtypemilestonetype witmt on witmt.workitemtypeid = wi.workitemtypeid and witmt.WorkItemMilestoneTypeId = wi.WorkItemMilestoneTypeId
inner join @DigitaInfo d on d.entityid = dl.ForeignId 
where e.businessservicelineid = 3
and p.TaxYearId = @TaxYear
and wi.WorkItemTypeid = 3
and wi.WorkItemStateId not in (3,4)
and cl.ForeignName like 'Lockheed Martin%'
order by cl.foreignname, l.foreignname