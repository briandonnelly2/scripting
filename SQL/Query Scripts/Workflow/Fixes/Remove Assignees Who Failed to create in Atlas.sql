	delete from [UACT910bad3d040c4db79d241ebe24dd008c] where fldid in (
select a.fldid

from TAX_Atlas_KPMGLink.dbo.NewTaxReturnProjects ntrp

join [UACT910bad3d040c4db79d241ebe24dd008c] a on ntrp.assigneegtsid = a.TempGTSID and ntrp.TaxYear = a.WorkItemYear and a.TempGTSIDClient = ntrp.ClientGTSID
join tblinstanceactivities ia on a.fldiactid = ia.fldid and ia.fldcompletiondate is not null

where ntrp.taxyear = 2018 )