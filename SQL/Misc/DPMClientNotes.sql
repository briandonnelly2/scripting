USE [PracticeManagementCoE]

SELECT	be.FileAs AS 'ClientName',
		be.ClientCode AS 'Client Code',
		hi.Title,
		n.[Text],
		hi.CreatedBy,
		hi.[Date] AS 'CreatedOn',
		hi.ModifiedBy,
		hi.DateModified AS 'ModifiedOn'
	FROM BillableEntity AS be
	INNER JOIN dbo.BillableEntityHistoryItem AS bh ON bh.BillableEntityID = be.BillableEntityID 
	INNER JOIN dbo.Note AS n ON n.HistoryItemID = bh.HistoryItemID
	INNER JOIN dbo.HistoryItem AS hi ON hi.HistoryItemID = n.HistoryItemID
	inner join ClientGroupBillableEntity cgb on cgb.billableentityid = be.billableentityid

	WHERE cgb.[ClientGroupID] in ('7238B024-0AF3-44BA-85B5-7BDE668F1B36','F9DD3D47-5E95-439F-B8F6-CEE2CBE1267B')

	ORDER BY be.ClientCode