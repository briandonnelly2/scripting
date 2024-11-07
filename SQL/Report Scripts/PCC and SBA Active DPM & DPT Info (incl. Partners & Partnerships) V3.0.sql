--Updated 04/12/2019 by brian Donnelly
--Now includes partnership records and the new user defined fields for 2019

USE [PracticeManagementCoE]

SELECT DISTINCT
	 lc.IsActive
	,lc.[DisplayName] as [Display Name]
	,be.FileAs
	,be.ClientCode
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


	from billableentity be 

	inner join listcache lc on lc.billableentityid = be.billableentityid --On Other report
	inner join ClientGroupBillableEntity cgb on cgb.billableentityid = be.billableentityid --On Other report
	inner join clientgroup cg on cg.ClientGroupID = cgb.ClientGroupID --On Other report
	inner join practiceclient pc on pc.practiceclientid = lc.practiceclientid --never used in select
	inner join ClientGroupBillableEntity cgbe on cgbe.BillableEntityID = be.BillableEntityID --never used in select
	left join person p on p.personid = lc.personid --On Other report but is a left join
	left join emailcontact email on lc.emailcontactid = email.emailcontactid --On Other report
	left join postalcontact posc on lc.postalcontactid = posc.postalcontactid --never used in select
	left join [Country] cou on cou.[CountryID] = posc.[CountryID] --never used in select

	where

	cg.[ClientGroupID] IN ('7238B024-0AF3-44BA-85B5-7BDE668F1B36','F9DD3D47-5E95-439F-B8F6-CEE2CBE1267B')

	AND
	
	lc.type != 1

	--lc.IsActive = 1

	order by 
		
	lc.DisplayName