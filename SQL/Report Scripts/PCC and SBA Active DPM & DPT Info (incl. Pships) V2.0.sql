USE [PracticeManagementCoE]
GO
	
	;with TaxywinDetails as
(
select c.entityid, c.refcode, c.taxref, c.NI, c.HOMEPHONE, c.WORKPHONE, g.GroupId, tf.[formtype]
from TaxywinCOE.dbo.Client c
inner join TaxywinCOE.dbo.GroupClient gc on gc.Clientid = c.CLIENTID
inner join TaxywinCOE.dbo.[Group] g on g.GroupId = gc.GroupId
left join TaxywinCOE.dbo.TaxForm tf on tf.CLIENTID = c.CLIENTID and tf.[YEAR] = 2018
union 
select p.entityid, p.REFCODE, p.TaxRef, '', '', '', g.GroupId, case when ptf.lPartnershipID is null then '' else 'SA800' end
from TaxywinCOE.dbo.Partnership p
inner join TaxywinCOE.dbo.GroupPartnership gp on gp.PClientid = p.PCLIENTID
inner join TaxywinCOE.dbo.[Group] g on g.GroupId = gp.GroupId
left join TaxywinCOE.dbo.PartnershipTaxForm ptf on ptf.lpartnershipid = p.pclientid and ptf.nYear = 2018
)

	SELECT DISTINCT
			lc.IsActive
			,lc.[DisplayName] as [Display Name]
			,be.ClientCode AS [DPM Code]
			,twd.REFCODE AS [DPT Code]
			,cg.[Name] AS [DPM Access Group]
			,twd.groupid AS [DPT Access Group]
			,twd.TaxRef AS [UTR]
			,twd.NI as [NI Number]
			,twd.HOMEPHONE as [Home Phone]
			,twd.WORKPHONE as [Work Phone]
			,be.FileAs
            ,p.DateOfBirth
            ,p.DateOfDeath
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
			,udfv.[FamilyGroup] AS 'Business/Family Group'
			,udfv.[ProjectBoxPilot] AS 'OPI Status'
			,udfv.[NotOffshore] AS 'Why Not Offshore'
			,udfv.[CoE Client] AS 'COE Client?'
			,udfv.[COEContact] AS 'COE Contact Method'
			,udfv.[CoE_Contact_New] AS 'COE Contact**NEW' --New Field
			,udfv.[NotCOEClient] AS 'Why Not COE?'
			,udfv.[InformationExpected] AS 'Information Expected'
			,udfv.[JointFee] AS 'Joint Fee'
			,udfv.[15_16_Fee] AS '15/16 Fee'
			,udfv.[15_16_FeeType] AS '15/16 Fee Type'
			,udfv.[TotalFeeJoint15_16] AS 'Total 15/16 Joint Fee'
			,udfv.[16_17_Fee] AS '16/17 Fee'
			,udfv.[16_17_FeeType] AS '16/17 Fee Type'
			,udfv.[TotalFeeJoint16_17] AS 'Total 16/17 Joint Fee'
			,udfv.[17_18_Fee] AS '17/18 Fee'
			,udfv.[17_18_FeeType] AS '17/18 Fee Type'
			,udfv.[TotalFeeJoint17_18] AS 'Total 17/18 Joint Fee'
			,udfv.[18_19_Fee] AS '18/19 Fee**NEW' --New Field
			,udfv.[18_19_FeeType] AS '18/19 Fee Type**NEW' --New Field
			,udfv.[TotalFeeJoint18_19] AS 'Total 18/19 Joint Fee**NEW' --New Field
			,udfv.[InvoiceAmount] AS 'Invoice Amount'
			,udfv.[FROR_Field] AS 'FROR Date**NEW' --New Field
 			,twd.[FormType]
		    	,case when udf.[Email correspondence] = '1' then 'Yes' else 'No' end as [Email correspondence?]
		    	,isnull(email.Address,'') as EmailAddress
		    	,isnull(pp.personal,'') as 'Personal'
				,isnull(pp.envelope,'') as 'Envelope'
				,isnull(posc.addressline1,'') as 'AddressLine1'
				,isnull(posc.addressline2,'') as 'AddressLine2'
				,isnull(posc.addressline3,'') as 'AddressLine3'
				,isnull(posc.town,'') as 'Town'
				,isnull(posc.county,'') as 'County'
				,isnull(posc.postcode,'') as 'Postcode'
				,isnull(cou.[Name],'') as 'Country'
			,rel.processingoffice as [Processing Office]
			,rel.[relationshipoffice] AS [Relationship Office]
			,rel.[relationship manager] as [Relationship Manager]
			,rel.staff as [Staff]
			,lc.ClientSignatoryName AS [Signatory is]
			,rel.[manager] AS [Manager is]
			,case when udf.[Exclude from mailshots] = '1' then 'Yes' else 'No' end as [Exclude from mailshots]


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

	order by 
		
		be.FileAs