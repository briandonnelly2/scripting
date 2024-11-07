USE [Sequence]

DECLARE @MainProcessID INT
SET @MainProcessID = 9709112

DECLARE @OffshorePreparerId INT
DECLARE @OffshorePreparerName NVARCHAR(30)
DECLARE @OffshoreReviewerId INT = (SELECT OffshorePreparerId FROM [Sequence].[dbo].[UWFe23fcf4c13ba4388ab77a85d25571073] WHERE fldIWfId = @MainProcessID)
DECLARE @OffshoreReviewerName NVARCHAR(30) = (SELECT OffshorePreparerName FROM [Sequence].[dbo].[UWFe23fcf4c13ba4388ab77a85d25571073] WHERE fldIWfId = @MainProcessID)


BEGIN TRANSACTION
	UPDATE [Sequence].[dbo].[UWFe23fcf4c13ba4388ab77a85d25571073]
	SET OffshoreReviewerId = @OffshoreReviewerId, 
		OffshoreReviewerName = @OffshoreReviewerName,
		OffshorePreparerId = @OffshorePreparerId,
		OffshorePreparerName = @OffshorePreparerName
	WHERE fldIWfId = 9709112
ROLLBACK TRANSACTION
--COMMIT TRANSACTION