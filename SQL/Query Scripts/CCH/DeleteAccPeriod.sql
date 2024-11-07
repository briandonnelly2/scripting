USE [CCHCentral_Live]

BEGIN TRAN
-------------------------------------------------------------------------------------------
/*
PM-20/10/17
Deletes all the draft journals for an accounting period.
*/
-------------------------------------------------------------------------------------------
DECLARE @AccountingPeriodId		INT = 613
DECLARE @DraftTranHeaders AS TABLE	(DraftTransactionHeader	INT)

;
WITH cteGetDraftTransactionHeaders AS 
	(SELECT TransactionHeaderId
	FROM AP.TransactionHeader
		INNER JOIN AP.TransactionType
			ON TransactionHeader.TransactionTypeId = TransactionType.TransactionTypeId
		INNER JOIN AP.TransactionCategory
			ON TransactionType.TransactionCategoryId = TransactionCategory.TransactionCategoryId
	WHERE AccountingPeriodId = @AccountingPeriodId
		  AND PostedId = 1 -- draft
		  AND TransactionCategory.TransactionCategoryId = 1) -- journals

INSERT INTO @DraftTranHeaders(DraftTransactionHeader)

SELECT cteDTH.TransactionHeaderId FROM cteGetDraftTransactionHeaders cteDTH


-- Mark the transaction items as Deleted
--SELECT * 
UPDATE ti
SET ti.IsDeleted = 1
FROM AP.TransactionItem ti
INNER JOIN AP.TransactionHeader th ON th.TransactionHeaderId = ti.TransactionHeaderId
INNER JOIN @DraftTranHeaders dth ON th.TransactionHeaderId = dth.DraftTransactionHeader
WHERE 
	ti.AccountingPeriodId = @AccountingPeriodId

-- Mark the transaction headers as Deleted
--SELECT *
UPDATE th
SET th.IsDeleted = 1
FROM AP.TransactionHeader th
INNER JOIN @DraftTranHeaders dth ON th.TransactionHeaderId = dth.DraftTransactionHeader
WHERE AccountingPeriodId = @AccountingPeriodId

PRINT 'Marking draft journals as deleted for accounting period ' + CONVERT(NVARCHAR(6), @AccountingPeriodId)

ROLLBACK TRAN
--COMMIT