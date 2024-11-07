USE [TaxywinCOE]

DECLARE @TaxYear NVARCHAR(100) = '2019'
DECLARE @ClientCode NVARCHAR(100) = '549613'

SELECT * FROM FBISubmissions
WHERE lclientId IN
(SELECT c.ClientId 
FROM Client c where c.RefCode = @ClientCode)
AND [nyear] = @TaxYear


--BEGIN TRAN

--UPDATE FBISubmissions
--SET LStatusId = 4
--WHERE lclientId IN
--(SELECT c.ClientId 
--FROM Client c WHERE c.RefCode = @ClientCode)
--AND lStatusId = 1
--AND nYear = @TaxYear

----ROLLBACK
--COMMIT