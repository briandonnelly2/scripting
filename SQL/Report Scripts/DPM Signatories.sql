--Signatory Part

USE [PracticeManagementCoE]
GO

  select
		 	lc.DisplayName
			,e.Position
			,isnull(posc.addressline1,'') as 'AddressLine1'
			,isnull(posc.addressline2,'') as 'AddressLine2'
			,isnull(posc.addressline3,'') as 'AddressLine3'
			,isnull(posc.town,'') as 'Town'
			,isnull(posc.postcode,'') as 'Postcode'
			,email.Address AS [Email]
			,t.[NationalNumber] AS [Phone]
			,f.[NationalNumber] AS [Fax]

  from 

		billableentity be 

  	inner join listcache lc on lc.billableentityid = be.billableentityid AND lc.[type]=4
	inner join [PracticePerson] pp on pp.billableentityid = be.billableentityid
	inner join [PracticeUser] pu on pu.practicepersonid = pp.[PracticePersonID]
	inner join [Employment] e on e.employmentid = pu.employmentid
	left join postalcontact posc on lc.postalcontactid = posc.postalcontactid
	left join emailcontact email on lc.emailcontactid = email.emailcontactid
	left join [TelephoneContact] t on lc.[TelephoneContactID] = t.[TelephoneContactID] AND t.[IsFax]=0
	left join [TelephoneContact] f on lc.[FaxContactID] = f.[TelephoneContactID] AND f.[IsFax]=1

Order by

	lc.DisplayName