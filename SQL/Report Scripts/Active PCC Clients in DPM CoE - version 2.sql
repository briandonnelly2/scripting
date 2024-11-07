use [PracticeManagementCoE]
GO

select
		be.clientcode as 'ClientCode'
		,be.fileas as 'FileAs'
		,isnull(pp.envelope,'') as 'Envelope'
		,isnull(pp.informal,'') as 'Informal'
		,isnull(posc.addressline1,'') as 'AddressLine1'
		,isnull(posc.addressline2,'') as 'AddressLine2'
		,isnull(posc.addressline3,'') as 'AddressLine3'
		,isnull(posc.town,'') as 'Town'
		,isnull(posc.county,'') as 'County'
		,isnull(posc.postcode,'') as 'Postcode'
		,udf.[Letter reference]
		,cg.[Name] AS [UK or Offshore]
		,rel.RelationshipOffice
		,rel.Manager
		,rel.Staff

from billableentity be

inner join listcache lc on lc.billableentityid = be.billableentityid
inner join practiceclient pc on pc.practiceclientid = lc.practiceclientid
inner join person p on p.personid = lc.personid
inner join KPMG_TrackerReporting_UDFs udf on udf.billableentityidudf = be.billableentityid 
inner join KPMG_TrackerReporting_Relationships rel on rel.billableentityidrel = be.billableentityid
inner join ClientGroupBillableEntity cgb on cgb.billableentityid=be.billableentityid
inner join clientgroup cg on cg.ClientGroupID = cgb.ClientGroupID
left join postalcontact posc on lc.postalcontactid = posc.postalcontactidleft join practiceperson pp on p.personid = pp.personid

where pc.isactive = 1
and cg.[ClientGroupID] in ('7238B024-0AF3-44BA-85B5-7BDE668F1B36','F9DD3D47-5E95-439F-B8F6-CEE2CBE1267B')

order by be.clientcode