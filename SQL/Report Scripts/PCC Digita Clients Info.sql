USE [PracticeManagementCoE]

SELECT 
		be.ClientCode AS 'Client Code',
		cd.[Name] AS 'Client Name',
		cd.[Email Address],
		rel.Staff,
		lc.ClientManagerName AS 'Client Manager',
		lc.ClientSignatoryName AS 'Client Signatory',
		rel.[relationship manager] AS 'Relationship Manager',
		per.GivenNames AS 'Forename',
		per.FamilyName AS 'Surname',
		per.UniqueTaxReference AS 'UTR',
		per.NINumber AS 'NI Number',
		rel.processingoffice AS 'Processing Office',
		lc.RelationshipOfficeName AS 'Relationship Office',
		udf.[Business Group],
		udfv.ReturnType AS 'Return Type',
		udfv.[ProjectBoxPilot] AS 'OPI Status',
		udfv.Region,
		udfv.[COEContact] AS 'COE Contact Method',
		udfv.[InformationExpected] AS 'Information Expected',
		per.PreferredName 'Preferred Name',
		be.FileAs AS 'File As',
		per.DateOfDeath AS 'Date Of Death',
		udfv.[CoE Client] AS 'COE Client?',
		udfv.[FamilyGroup] AS 'Business/Family Group',
		isnull(posc.addressline1,'') as 'AddressLine1',
		isnull(posc.addressline2,'') as 'AddressLine2',
		isnull(posc.addressline3,'') as 'AddressLine3',
		isnull(posc.town,'') as 'Town',
		isnull(posc.county,'') as 'County',
		isnull(posc.postcode,'') as 'Postcode',
		isnull(cou.[Name],'') as 'Country',
		cd.[Home Telephone Number] AS 'Home Phone',
		cd.[Fax Telephone Number] AS 'Fax Number',
		cd.[Mobile Telephone Number] AS 'Mobile Number',
		cg.[Name] AS [Assigned Group],
		CASE per.Gender
			WHEN 0 THEN 'Not Known'
			WHEN 1 THEN 'Male'
			WHEN 2 THEN 'Female'
			WHEN 3 THEN 'Not Specified'
			ELSE 'Not Selected'
			END AS Gender,
		per.DateOfBirth,
		udf.[Document Password],
		case when udf.[Email correspondence] = '1' then 'Yes' else 'No' end as [Email correspondence?],
		case lc.type
			when 0 then 'Person'
			when 1 then 'Sole Trade'
			when 2 then 'Partnership'
			when 3 then 'Company'
			when 4 then 'Staff Member'
			when 7 then 'Trust'
			when 8 then 'Estate'
			else 'n/a'
			end as [Type]
	
	FROM BillableEntity AS be
    INNER JOIN ListCache AS lc ON lc.BillableEntityID = be.BillableEntityID
	INNER JOIN [TaxywinCoE]..[_ddm_CLIENT_DETAILS_GENERAL] cd WITH (NOLOCK) ON cd.[BillableEntityID] = be.[BillableEntityID]
	inner join ClientGroupBillableEntity cgb on cgb.billableentityid = be.billableentityid
	inner join clientgroup cg on cg.ClientGroupID = cgb.ClientGroupID
	left join postalcontact posc on lc.postalcontactid = posc.postalcontactid
	left join [Country] cou on cou.[CountryID] = posc.[CountryID]
	left join KPMG_TrackerReporting_UDFs udf on udf.billableentityidudf = be.billableentityid 
	left join KPMG_TrackerReporting_Relationships rel on rel.[billableentityidrel] = be.billableentityid 
	left join UserDefinedFieldsView udfv on udfv.BillableEntityID = be.billableentityid
	LEFT JOIN Person AS per ON per.PersonID = lc.PersonID
	
	WHERE cg.[ClientGroupID] in ('7238B024-0AF3-44BA-85B5-7BDE668F1B36','F9DD3D47-5E95-439F-B8F6-CEE2CBE1267B')

	--AND (rel.Staff = 'Andrea Ong'
	--	OR lc.ClientManagerName = 'Andrea Ong'
	--	OR lc.ClientSignatoryName = 'Andrea Ong'
	--	OR rel.[relationship manager] = 'Andrea Ong')

	ORDER BY lc.DisplayName