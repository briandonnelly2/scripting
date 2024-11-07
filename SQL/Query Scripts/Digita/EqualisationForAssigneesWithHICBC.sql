USE [TaxywinCOE]

SELECT	 Refcode
		,FIRSTNAMES + ' ' + SURNAME AS 'Client Name'
		,nYear 

FROM	 Client
		,OtherReturnInfo

WHERE Client.CLIENTID = OtherReturnInfo.lClientID

AND bHighIncomeChildBenefitCharge <> 0

AND (	cHICBCChargeable IS NULL 
		OR cHICBCChargeable = 0  )

ORDER BY nYear