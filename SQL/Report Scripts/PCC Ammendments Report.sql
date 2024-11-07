USE [TaxywinCOE]
GO

DECLARE @year INT
SET @year=2019

SELECT
	
	 c.refcode AS [Client Code]
	,c.Surname AS [Surname or Name]
	,c.Firstnames
	,tf.dtPrinted  AS [Last Date Printed]
	,tf.DateFinalised AS [Date Finalised]
	,fbis.strStatus AS SubmissionStatus
	,fbi.dtSubmitted AS DateSubmitted
	,fbi.strIRMark AS [IR Mark when submitted]
	,tf.bAmendedReturn AS [Amended Return]
	,tf.dtAmendmentStarted AS [Date Amendment Started]


FROM

	Client c

INNER JOIN fbiSubmissions fbi WITH (NOLOCK) ON fbi.lclientid = c.clientid
INNER JOIN fbiStatusRef fbis WITH (NOLOCK) ON fbis.lid = fbi.lstatusid
INNER JOIN taxform tf WITH (NOLOCK) ON tf.clientid = c.clientid

WHERE 
		fbi.nYear = @year
		AND 
		tf.[YEAR] = @year

UNION ALL

SELECT

	 p.refcode AS [Client Code]
	,p.name AS [Surname or Name]
	,NULL
	,ptf.dtPrinted AS [Last Date Printed]
	,ptf.dtFinalised AS [Date Finalised]
	,fbis.strStatus AS SubmissionStatus
	,pfbi.dtSubmitted AS DateSubmitted
	,pfbi.strIRMark AS [IR Mark when submitted]
	,ptf.bAmendedReturn AS [Amended Return]
	,ptf.dtAmendmentStarted AS [Date Amendment Started]

FROM

	Partnership p

INNER JOIN PartnershipfbiSubmissions pfbi WITH (NOLOCK) ON pfbi.lPartnershipID = p.pclientid
INNER JOIN fbiStatusRef fbis WITH (NOLOCK) ON fbis.lid = pfbi.lstatusid
INNER JOIN partnershiptaxform ptf WITH (NOLOCK) ON ptf.lPartnershipID = p.pclientid

WHERE 
		pfbi.nYear = @year
		AND 
		ptf.nYear = @year

ORDER BY

	c.refcode