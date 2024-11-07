USE [PracticeManagementCoE_Staging]
GO
	
	;with TaxywinDetails as
(
select c.entityid, c.refcode, c.taxref, c.NI, c.HOMEPHONE, c.WORKPHONE, g.GroupId, tf.[formtype]
from TaxywinCOE_Staging.dbo.Client c
inner join TaxywinCOE_Staging.dbo.GroupClient gc on gc.Clientid = c.CLIENTID
inner join TaxywinCOE_Staging.dbo.[Group] g on g.GroupId = gc.GroupId
left join TaxywinCOE_Staging.dbo.TaxForm tf on tf.CLIENTID = c.CLIENTID --and tf.[YEAR] = 2018
union 
select p.entityid, p.REFCODE, p.TaxRef, '', '', '', g.GroupId, case when ptf.lPartnershipID is null then '' else 'SA800' end
from TaxywinCOE_Staging.dbo.Partnership p
inner join TaxywinCOE_Staging.dbo.GroupPartnership gp on gp.PClientid = p.PCLIENTID
inner join TaxywinCOE_Staging.dbo.[Group] g on g.GroupId = gp.GroupId
left join TaxywinCOE_Staging.dbo.PartnershipTaxForm ptf on ptf.lpartnershipid = p.pclientid --and ptf.nYear = 2018
)

	SELECT DISTINCT
			 lc.[DisplayName] as [Display Name]
			,twd.REFCODE AS [DPT Code]
			,twd.groupid AS [DPT Access Group]
			,twd.TaxRef AS [UTR]
			,case lc.type
			when 0 then 'Person'
			when 1 then 'Sole Trade'
			when 2 then 'Partnership'
			when 3 then 'Company'
			when 4 then 'Staff Member'
			when 7 then 'Trust'
			when 8 then 'Estate'
			else 'n/a'
			end as [Type]


	from billableentity be 
	inner join listcache lc on lc.billableentityid = be.billableentityid
	inner join practiceclient pc on pc.practiceclientid = lc.practiceclientid
	inner join person p on p.personid = lc.personid
	inner join ClientGroupBillableEntity cgb on cgb.billableentityid=be.billableentityid
	inner join clientgroup cg on cg.ClientGroupID = cgb.ClientGroupID
	inner join TaxywinDetails twd on twd.EntityId = be.BillableEntityID
	--inner join taxywincoe..client c on c.entityid = be.billableentityid
	inner join ClientGroupBillableEntity cgbe on cgbe.BillableEntityID = be.BillableEntityID
	--inner join taxywincoe..groupclient gc on gc.Clientid = c.CLIENTID
	--inner join taxywincoe..[group] g on g.GroupId = gc.GroupId
	--LEFT JOIN taxywincoe..taxform tf ON tf.clientid = c.clientid --AND tf.[YEAR] = @Year
	left join postalcontact posc on lc.postalcontactid = posc.postalcontactid
	left join [Country] cou on cou.[CountryID] = posc.[CountryID]
	left join practiceperson pp on p.personid = pp.personid
	left join emailcontact email on lc.emailcontactid = email.emailcontactid
	left join PracticePerson pps ON lc.ClientSignatoryID = pps.PersonID
	left join PracticeUser pu ON pps.PracticePersonID = pu.PracticePersonID
	left join Employment emp ON pu.EmploymentID = emp.EmploymentID
	left join KPMG_TrackerReporting_UDFs udf on udf.billableentityidudf = be.billableentityid 
	left join KPMG_TrackerReporting_Relationships rel on rel.[billableentityidrel] = be.billableentityid 
	left join UserDefinedFieldsView udfv on udfv.BillableEntityID = be.billableentityid

	where

	cg.[ClientGroupID] IN ('7238B024-0AF3-44BA-85B5-7BDE668F1B36','F9DD3D47-5E95-439F-B8F6-CEE2CBE1267B''8919E018-70C5-418D-8BCD-03621741332E')
	--AND be.ClientCode IN ('BL60142029RR','BM60262654CP','BL60142029RK')

	AND 

	lc.IsActive = 1

	--order by 
		
		--be.FileAs