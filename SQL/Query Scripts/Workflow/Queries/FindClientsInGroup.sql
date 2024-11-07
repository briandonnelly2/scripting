USE [TaxWFPortalData]

SELECT cl.ClientId
      ,cl.ClientName
	  ,clag.[Description]
	  ,lk.ForeignCode as 'GTS Id'
  FROM Clients cl
  INNER JOIN ClientAccessGroupClients clg on cl.ClientId = clg.ClientId
  INNER JOIN ClientAccessGroup clag on clg.ClientAccessGroupId = clag.ClientAccessGroupId
  INNER JOIN Links lk on cl.ClientId = lk.ClientId
  WHERE (clg.ClientAccessGroupId = 7 OR clg.ClientAccessGroupId = 8) AND lk.LinkTypeId = 5
	ORDER BY cl.ClientName