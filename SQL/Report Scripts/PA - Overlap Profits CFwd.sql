
USE TaxyWinTraining

GO

DECLARE @Year INT = '2018'

SELECT

 c.Refcode
,c.Surname
,c.Firstnames
,tf.Year
,sum(pi.OLR_TradingCarriedForward) [Box 14] --Multiple rows per year therefore provides total
,sum(pi.OLR_UntaxedCarriedForward) [Box 66] --Multiple rows per year therefore provides total

FROM client c

INNER JOIN taxform tf on c.clientid = tf.clientid and tf.year = @Year
INNER JOIN PartnershipIncome pi on pi.clientid = c.clientid and pi.year = @Year

GROUP BY

 c.refcode
,c.clientid
,c.surname
,c.firstnames
,c.refcode
,tf.year

ORDER BY SURNAME