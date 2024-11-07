USE [TaxywinCOE]

DECLARE @TaxYear INT = 2019

SELECT 	 c.TITLE + ' ' +  c.FIRSTNAMES + ' ' + c.SURNAME AS [Client Name]
		,c.REFCODE AS [Client Ref]
		,fbi.strUser AS [Username]
		,fbi.dtSubmitted AS [Date & Time]
		,fbi.nYear AS [Tax Year]
		,fbi.strMessages AS [Gateway Message]
		,CASE fbi.lStatusID
		 WHEN 0 THEN 'Pending'
		 WHEN 1 THEN 'Submitted'
		 WHEN 2 THEN 'Accepted'
		 WHEN 3 THEN 'Rejected'
		 WHEN 4 THEN 'Cancelled'
		 ELSE 'N/A'
		 END AS [Submission Status]
		,gc.GroupId AS [DPT access Groups]

FROM FBISubmissions fbi

INNER JOIN Client c ON c.CLIENTID = fbi.lClientID
INNER JOIN GroupClient gc ON gc.Clientid = fbi.lClientID 
	   AND gc.GroupId IN ( 'PCC UK', 'PCC Offshore')

WHERE fbi.nYear = @TaxYear