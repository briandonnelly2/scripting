
/*
Compensation Anaylser UAT data update script from releases 2.14 to release 3.07
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
DECLARE @ToVersion varchar(50) = '3.15'
DECLARE @CurrentVersion varchar(50) = (SELECT [Version] FROM [dbo].[Version] WHERE [Key] = @VersionKey)

IF (@CurrentVersion IS NOT NULL AND @CurrentVersion NOT IN ('3.14') AND @CurrentVersion <> @ToVersion)
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


/************************** Data script start *************************/

--Ca.DataBase_Data_3.14.1_To_3.15

PRINT N'Updating [dbo].[UsFtcLabel]...';

MERGE INTO [dbo].[UsFtcLabel] AS Target
USING (VALUES

(1, N'Balance of US Federal Tax per form 1040 (line 44 minus lines 48-53)'),
(2, N'(Do not subract AMT credit from form 8801, form 1040 line 54)')

) AS Source ([Id], [Text])
ON Target.Id = Source.Id

-- Update matched rows
WHEN MATCHED THEN
UPDATE SET 
	[Text] = Source.[Text]

-- Insert new rows
WHEN NOT MATCHED BY TARGET THEN
INSERT ([Id], [Text])
VALUES ([Id], [Text])

-- Delete missing rows
WHEN NOT MATCHED BY SOURCE THEN
DELETE;



PRINT N'Updating [dbo].[UsFtcLabelOverride]...';

MERGE INTO [dbo].[UsFtcLabelOverride] AS Target
USING (VALUES

(1, 2018, 1, N'Balance of US Federal Tax per form 1040 line 13'),
(2, 2018, 2, N'')

) AS Source ([Id], [CalendarYear], [UsFtcLabelId], [Text])
ON Target.Id = Source.Id

-- Update matched rows
WHEN MATCHED THEN
UPDATE SET
	[CalendarYear] = Source.[CalendarYear], 
	[UsFtcLabelId] = Source.[UsFtcLabelId],
	[Text] = Source.[Text]

-- Insert new rows
WHEN NOT MATCHED BY TARGET THEN
INSERT ([Id], [CalendarYear], [UsFtcLabelId], [Text])
VALUES ([Id], [CalendarYear], [UsFtcLabelId], [Text])

-- Delete missing rows
WHEN NOT MATCHED BY SOURCE THEN
DELETE;

--Ca.DataBase_Data_3.14.1_To_3.15

/*************************** Data script end **************************/


PRINT N'Data update complete.'


DECLARE @VersionName varchar(50) = 'Data'
DECLARE @Version varchar(50) = '3.15'

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