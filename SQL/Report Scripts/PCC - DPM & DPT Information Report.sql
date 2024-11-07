USE [PracticeManagementCoE]
GO

SELECT 

		DISTINCT 
		p.[UniqueTaxReference] as [UTR]
		,be.[Fileas] as [FileAs]
		,lc.[DisplayName] as [Display Name]
		,case lc.[IsActive]
		when 1 then 'Yes'
		end as [Active]
		,be.[Clientcode] as [Code]
		,p.DateOfDeath as [Death DPM]
		,tc.Death as [Death DPT]
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
		,isnull(posc.addressline1,'') as 'AddressLine1'
			,isnull(posc.addressline2,'') as 'AddressLine2'
			,isnull(posc.addressline3,'') as 'AddressLine3'
			,isnull(posc.town,'') as 'Town'
			,isnull(posc.county,'') as 'County'
			,isnull(posc.postcode,'') as 'Postcode'
			,isnull(cou.[Name],'') as 'Country'
		,cg.Name as [Offshore Status]
		,udfv.NotOffshore AS [No Offshore Reason]
		,udfv.NotCOEClient AS [No Coe Reason]
		,udf.Region as [Region]
		,rel.processingoffice as [Processing Office]
		,rel.manager as [Manager]
		,rel.staff as [Staff]
		,lc.[UDR_Relationship manager is Name] AS [Relationship Manager]
		,rel.relationshipoffice as [Relationship Office]
		,udf.[Email correspondence]

from billableentity be

inner join listcache lc on lc.billableentityid = be.billableentityid
inner join ClientGroupBillableEntity cgb on cgb.billableentityid=be.billableentityid
inner join clientgroup cg on cg.ClientGroupID = cgb.ClientGroupID
inner join practiceperson pp on pp.BillableEntityID = lc.BillableEntityID
left join UserDefinedFieldsView udfv on udfv.BillableEntityID = be.BillableEntityID
left join person p on lc.personid = p.personid
left join postalcontact posc on lc.postalcontactid = posc.postalcontactid
left join [Country] cou on cou.[CountryID] = posc.[CountryID]
left join KPMG_TrackerReporting_UDFs udf on be.billableentityid = udf.billableentityidudf 
left join KPMG_TrackerReporting_Relationships rel on be.billableentityid = rel.billableentityidrel
left join [EmailContact] ec on lc.[EmailContactID] = ec.[EmailContactID]
left join [BillableEntityCategory] bec on be.billableentityid = bec.[BillableEntityID]
left join [PracticeCategory] pc on bec.[PracticeCategoryID] = pc.[PracticeCategoryID]
left join [Taxywincoe].dbo._ddm_CLIENT_DETAILS_GENERAL cdg on cdg.BillableEntityID = pp.BillableEntityID
left join [Taxywincoe].dbo.Client tc on tc.clientid = cdg.clientid



where --lc.isactive = 1
--AND
cg.[ClientGroupID] IN ('7238B024-0AF3-44BA-85B5-7BDE668F1B36','F9DD3D47-5E95-439F-B8F6-CEE2CBE1267B')

order by fileas