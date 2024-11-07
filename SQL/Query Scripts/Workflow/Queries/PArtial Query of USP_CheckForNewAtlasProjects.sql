select ntrp.AssigneeGTSID AS [Id], a.*
from TAX_Atlas_KPMGLink.dbo.NewTaxReturnProjects ntrp
/****** Object:  StoredProcedure [dbo].[USP_CheckForNewAtlasProjects]    Script Date: 19/07/2019 14:31:42 ******/
left join [UACT910bad3d040c4db79d241ebe24dd008c] a on ntrp.AssigneeGTSID = a.TempGTSID and ntrp.TaxYear = a.WorkItemYear and a.TempGTSIDClient = ntrp.ClientGTSID
where --ntrp.ClientGTSID = 40102
ntrp.TaxYear in (2018,2019)
--and a.fldId is null