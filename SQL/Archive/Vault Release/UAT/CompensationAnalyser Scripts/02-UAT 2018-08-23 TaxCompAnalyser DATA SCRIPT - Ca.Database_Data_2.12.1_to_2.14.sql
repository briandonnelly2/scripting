
/*
Compensation Anaylser data update script from releases 2.12.1 to release 2.14
*/

set noexec off

GO
SET ANSI_NULLS, ANSI_PADDING, ANSI_WARNINGS, ARITHABORT, CONCAT_NULL_YIELDS_NULL, QUOTED_IDENTIFIER ON;

/* ------------------------------------------------------------------------------- */
/* REQUIRED: Set @ExpectedDatabaseName to the database this should be executed on. */
/* ------------------------------------------------------------------------------- */

DECLARE @ExpectedDatabaseName varchar(50) = 'TaxCompAnalyser'

/* ------------------------------------------------------------------------------- */

IF (SELECT DB_NAME()) <> @ExpectedDatabaseName
BEGIN
	PRINT N'The current database is incorrect - stopping execution.'
	-- Nothing will execute from now on...
	set noexec on
END

DECLARE @VersionKey varchar(50) = 'Data'
DECLARE @ToVersion varchar(50) = '2.14'
DECLARE @CurrentVersion varchar(50) = (SELECT [Version] FROM [dbo].[Version] WHERE [Key] = @VersionKey)

IF (@CurrentVersion IS NOT NULL AND @CurrentVersion NOT IN ('2.12.1') AND @CurrentVersion <> @ToVersion)
BEGIN
	PRINT N'The current version of ' + @CurrentVersion + N' does not match a required version for this script to execute.'
	set noexec on
	-- Nothing will execute from now on...
END

GO

BEGIN TRANSACTION;

SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

SET XACT_ABORT ON;

BEGIN TRY

-- Ca.Database_Data_2.12.1_To_2.14

PRINT N'Updating [dbo].[Country]...'

MERGE INTO [dbo].[Country] AS Target
USING (VALUES
(252, 'BQ', N'Bonaire', 'BES')
) AS Source ([Id], [Code], [Name], [HMRC3LetterCode])
ON Target.Id = Source.Id

-- Update matched rows (except date)
WHEN MATCHED THEN
UPDATE SET 
	Code = Source.Code,
	Name = Source.Name,
	HMRC3LetterCode = Source.HMRC3LetterCode

-- Insert new rows
WHEN NOT MATCHED BY TARGET THEN
INSERT ([Id], [Code], [Name], [HMRC3LetterCode])
VALUES ([Id], [Code], [Name], [HMRC3LetterCode]);


-- Ca.Database_Data_2.12.1_To_2.14

-- Ca.Database_Data_2.14_To_2.14.1


MERGE INTO [dbo].[DayType] AS Target
USING (VALUES

(1, N'work', N'Work', 0, 0),
(2, N'nonwork', N'Non-work', 0, 0),
(3, N'homeleave', N'Home Leave', 0, 1),
(4, N'sick', N'Sick', 0, 1),
(5, N'work3', N'Work < 3hrs', 0, 0),
(6, N'vacation', N'Vacation', 0, 1),
(7, N'travel', N'Travel', 0, 0),
(8, N'clear', N'Delete Activity', 0, 0),
(9, N'vhls_work', N'V, HL or S Assumed Work', 1, 0),
(10, N'vhls_nonwork', N'V, HL or S Assumed Non-work', 1, 0)

) AS Source ([Id], [Code], [Description], [IsShadowDayType], [NeedsShadowEntry])
ON Target.Id = Source.Id
WHEN MATCHED THEN
UPDATE SET 
	[Code] = Source.Code,
	[Description] = Source.[Description],
	[IsShadowDayType] = source.[IsShadowDayType],
	[NeedsShadowEntry] = source.[NeedsShadowEntry]

-- Insert new rows
WHEN NOT MATCHED BY TARGET THEN
INSERT ([Id], [Code], [Description], [IsShadowDayType], [NeedsShadowEntry])
VALUES ([Id], [Code], [Description], [IsShadowDayType], [NeedsShadowEntry]);


-- Ca.Database_Data_2.14_To_2.14.1

PRINT N'Data update complete.'

PRINT ''
PRINT N'Updating the KPMG version table.';

DECLARE @VersionName varchar(50) = 'Data'
DECLARE @Version varchar(50) = '2.14'

DECLARE @VersionTable TABLE([Key] varchar(50), [Version] varchar(50), [AppliedOn] datetime)
SET NOCOUNT ON;
INSERT INTO @VersionTable([Key], [Version], [AppliedOn]) VALUES (@VersionName, @Version, GETDATE())

UPDATE [dbo].[Version] SET [Key] = new.[Key], [Version] = new.[Version], [AppliedOn] = new.[AppliedOn]
FROM [dbo].[Version]
INNER JOIN @VersionTable new ON new.[Key] = [dbo].[Version].[Key]

INSERT INTO [dbo].[Version]([Key], [Version],[AppliedOn]) 
SELECT new.[Key], new.[Version], new.[AppliedOn]
FROM @VersionTable new
LEFT OUTER JOIN [dbo].[Version] existing ON new.[Key] = existing.[Key]
WHERE existing.[Key] IS NULL

SET NOCOUNT OFF;

END TRY

BEGIN CATCH  
    SELECT   
        ERROR_NUMBER() AS ErrorNumber  
        ,ERROR_SEVERITY() AS ErrorSeverity  
        ,ERROR_STATE() AS ErrorState  
        ,ERROR_PROCEDURE() AS ErrorProcedure  
        ,ERROR_LINE() AS ErrorLine  
        ,ERROR_MESSAGE() AS ErrorMessage;  
  
    IF @@TRANCOUNT > 0  
        ROLLBACK TRANSACTION;  
END CATCH;  

IF @@TRANCOUNT > 0  
    COMMIT TRANSACTION;
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED;  
	PRINT N'Update complete.';

GO  