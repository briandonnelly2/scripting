DECLARE @SeqEngInstanceId INT
DECLARE @EngagementInstances INT
DECLARE @TotalYearsRequested INT
DECLARE @RemainingYears INT
DECLARE @PeriodsCreated INT
DECLARE @SeqFirstTaxYear INT


SET @SeqEngInstanceId = 5447096
SET @EngagementInstances = (SELECT COUNT(*) FROM [Sequence].[dbo].tblInstanceWorkflows WHERE fldCompletionDate IS NULL AND fldId = @SeqEngInstanceId)
SET @TotalYearsRequested = (SELECT LengthValue FROM [Sequence].[dbo].[UACT30482307f98f43e0be104b62bf553f45] WHERE fldiwfid = @SeqEngInstanceId)
SET @RemainingYears = (SELECT EngagementYearsRemaining FROM [Sequence].[dbo].[UWF4a5eadb0cd0b419db25fff8b1ffe931d] WHERE ServiceLineId = 2 AND fldIWfId = @SeqEngInstanceId)
SET @PeriodsCreated = (SELECT Count(*) FROM [Sequence].[dbo].[tblInstanceActivities] WHERE fldInstanceWfId = @SeqEngInstanceId AND fldTemplateActivityGuid = 'c9b9647d-2f78-45a2-a4d9-7de6b95905c8')
SET @SeqFirstTaxYear = (SELECT FirstTaxYear FROM [Sequence].[dbo].[UACT30482307f98f43e0be104b62bf553f45] WHERE fldiwfid = @SeqEngInstanceId)

SELECT * FROM [UACT30482307f98f43e0be104b62bf553f45] 
WHERE fldiwfid = @SeqEngInstanceId


SELECT * FROM [UWF4a5eadb0cd0b419db25fff8b1ffe931d] 
WHERE fldiwfid = @SeqEngInstanceId

--UPDATE [Sequence].[dbo].[UACT30482307f98f43e0be104b62bf553f45] 
--SET LengthValue = @ExpectedYears
--WHERE fldiwfid = @SeqEngInstanceId

--UPDATE [Sequence].[dbo].[UWF4a5eadb0cd0b419db25fff8b1ffe931d] 
--SET EngagementYearsRemaining = (6 - 2)
--WHERE fldiwfid = @SeqEngInstanceId