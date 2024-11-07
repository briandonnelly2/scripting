USE [PracticeManagementCoE]

	
	select
			 lc.IsActive as [Active]
			,be.ClientCode
			,be.FileAs
			,isnull(p.UniqueTaxReference,'') AS [Tax Reference]
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
			,cg.Name
			

	from billableentity be 

	inner join listcache lc on lc.billableentityid = be.billableentityid
	inner join practiceclient pc on pc.practiceclientid = lc.practiceclientid
	inner join ClientGroupBillableEntity cgb on cgb.billableentityid=be.billableentityid
	inner join clientgroup cg on cg.ClientGroupID = cgb.ClientGroupID
	left join person p on p.personid = lc.personid

	order by 
		
		be.ClientCode