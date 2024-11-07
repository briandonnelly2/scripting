use [TaxWFPortalData]
go

DECLARE @year int
SET @year=2019

;with SubmissionStatus as
(
select c.EntityId as EntityId
	,c.TaxRef as UTR
	,fbis.strStatus as SubmissionStatus
	,fbi.dtSubmitted as DateSubmitted

from DIGITATAX.TaxywinCoE.dbo.Client c

inner join DIGITATAX.TaxywinCoE.dbo.fbiSubmissions fbi on fbi.lclientid = c.clientid
inner join DIGITATAX.TaxywinCoE.dbo.fbiStatusRef fbis on fbis.lid = fbi.lstatusid

where fbi.nYear = @year

union all

select p.EntityId as EntityId
	,p.TaxRef as UTR
	,fbis.strStatus as SubmissionStatus
	,pfbi.dtSubmitted as DateSubmitted

from DIGITATAX.TaxywinCoE.dbo.Partnership p

inner join DIGITATAX.TaxywinCoE.dbo.PartnershipfbiSubmissions pfbi on pfbi.lPartnershipID = p.pclientid
inner join DIGITATAX.TaxywinCoE.dbo.fbiStatusRef fbis on fbis.lid = pfbi.lstatusid

where pfbi.nYear = @year

)

select l.ForeignCode as ClientId
	,l.ForeignName as ClientName
	,e.[Description] as [Engagement Name]
	--,l.ForeignCode as AssigneeGTSID
	--,l.ForeignName as ClientName
	,ss.UTR
	,ss.SubmissionStatus as [SubmissionStatus - in Digita]
	,ss.DateSubmitted as [DateSubmitted - in Digita]
	,wis.[Name]
	,witmt.OverriddenName as CurrentMilestone
	,wi.WorkItemMilestoneChangeDate as LastUpdated
	,p.[Description] as [Year]
from WorkItems wi
inner join links l on l.clientid = wi.clientid and l.linktypeid = 2 --Digita
inner join ClientPeriods cp on cp.clientperiodid = wi.clientperiodid
inner join Periods p on p.periodid = cp.periodid
--inner join links cl on cl.clientid = cp.clientid and cl.linktypeid = 6
inner join WorkitemtypeMilestonetype witmt on witmt.WorkItemMileStoneTypeId = wi.WorkItemMilestoneTypeId and witmt.WorkItemTypeId = wi.WorkItemTypeId
inner join WorkItemState wis on wis.Id = wi.WorkItemStateId
inner join Engagements e on e.EngagementId = p.engagementid
left join SubmissionStatus ss on ss.entityid = l.foreignid collate Latin1_General_CI_AS
where wi.parentworkitemid is null
and wi.BusinessServiceLineId = 2 -- PCC
and p.taxyearid = @year
order by l.ForeignCode,ss.DateSubmitted
