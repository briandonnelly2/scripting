USE [TaxWFPortalData]

SELECT	 wi.[ClientId] AS 'WF Client ID'
		,lk.ForeignName AS 'Client Name'
		,wi.[SequenceInstanceId]
		,wi.[Description]
		,wi.[DueDate]
		,mt.[Name] AS 'Milestone'
		,st.[Name] AS 'Status'
		,lk.ForeignCode AS 'Client Code'

	FROM WorkItems AS wi

	INNER JOIN Links AS lk ON wi.ClientId = lk.ClientId
	INNER JOIN WorkItemMilestoneType AS mt ON wi.WorkItemMilestoneTypeId = mt.Id
	INNER JOIN WorkItemState AS st ON wi.WorkItemStateId = st.Id

	WHERE wi.SequenceInstanceId IN (7556699, 9053949, 8804686, 8480086, 7794473)
			AND wi.WorkItemStateId = 1 
			AND lk.LinkTypeId = 2