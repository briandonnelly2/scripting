
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
DECLARE @ToVersion varchar(50) = '3.14'
DECLARE @CurrentVersion varchar(50) = (SELECT [Version] FROM [dbo].[Version] WHERE [Key] = @VersionKey)

IF (@CurrentVersion IS NOT NULL AND @CurrentVersion NOT IN ('3.13') AND @CurrentVersion <> @ToVersion)
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

--Ca.DataBase_Data_3.13.4_To_3.14

PRINT N'Updating [dbo].[DdrAssigneeQuestion]...';

MERGE INTO [dbo].[DdrAssigneeQuestion] AS Target
USING (VALUES

(49, 1, 20477, N'Assignee DDR Note', 2, NULL, 0), 
(50, 2, 20477, N'Assignee DDR Note', 2, NULL, 0), 
(51, 13, 20477, N'Assignee DDR Note', 2, NULL, 0), 
(52, 14, 20477, N'Assignee DDR Note', 2, NULL, 0)

) AS Source ([Id], [TaxYearId], [OrganizerStaticCode], [Text], [DdrAssigneeQuestionTypeId], [DdrReductionTypeId], [Hidden])
ON Target.Id = Source.Id

-- Update matched rows (except date)
WHEN MATCHED THEN
UPDATE SET 
	[TaxYearId] = Source.[TaxYearId],
	[OrganizerStaticCode] = Source.[OrganizerStaticCode],
	[Text] = Source.[Text],
	[DdrAssigneeQuestionTypeId] = Source.[DdrAssigneeQuestionTypeId],
	[DdrReductionTypeId] = Source.[DdrReductionTypeId],
	[Hidden] = Source.[Hidden]

-- Insert new rows
WHEN NOT MATCHED BY TARGET THEN
INSERT ([Id], [TaxYearId], [OrganizerStaticCode], [Text], [DdrAssigneeQuestionTypeId], [DdrReductionTypeId], [Hidden])
VALUES ([Id], [TaxYearId], [OrganizerStaticCode], [Text], [DdrAssigneeQuestionTypeId], [DdrReductionTypeId], [Hidden]);

--Ca.DataBase_Data_3.13.4_To_3.14

--Ca.DataBase_Data_3.14_To_3.14.1

PRINT 'Updating [dbo].[DdrAssigneeQuestion]...';

MERGE INTO [dbo].[DdrAssigneeQuestion] AS Target
USING (VALUES

(1, 1, 92796, N'Annual rent paid to the landlord', 1, 1, 0, N'Rent'),
(2, 1, 20807, N'Council tax', 1, 2, 0, N'Council tax'),
(3, 1, 20808, N'Water rates', 1, 1, 0, N'Water rates'),
(4, 1, 20127, N'Utilities (e.g., gas, heating, electricity)', 1, 1, 0, N'Utilities'),
(5, 1, 92551, N'Insurance', 1, 1, 0, N'Insurance'),
(6, 1, 92552, N'Furniture rental', 1, 1, 0, N'Furniture rental'),
(7, 1, 20809, N'Travel', 1, 3, 0, N'Travel'),
(8, 1, 20810, N'Meals', 1, 3, 0, N'Meals'),
(9, 1, 20134, N'Other', 1, 3, 0, N'Other'),
(10, 1, 20133, N'Other description', 2, NULL, 1, NULL),
(11, 1, 23373, N'If different, annual rent paid by you (and not reimbursed by your employer)', 2, NULL, 0, NULL),
(12, 1, 92550, N'Were these expenses borne by your employer?', 2, NULL, 0, NULL),
(13, 2, 92796, N'Annual rent paid to the landlord', 1, 1, 0, N'Rent'),
(14, 2, 20807, N'Council tax', 1, 2, 0, N'Council tax'),
(15, 2, 20808, N'Water rates', 1, 1, 0, N'Water rates'),
(16, 2, 20127, N'Utilities (e.g., gas, heating, electricity)', 1, 1, 0, N'Utilities'),
(17, 2, 92551, N'Insurance', 1, 1, 0, N'Insurance'),
(18, 2, 92552, N'Furniture rental', 1, 1, 0, N'Furniture rental'),
(19, 2, 20809, N'Travel', 1, 3, 0, N'Travel'),
(20, 2, 20810, N'Meals', 1, 3, 0, N'Meals'),
(21, 2, 20134, N'Other', 1, 3, 0, N'Other'),
(22, 2, 20133, N'Other description', 2, NULL, 1, NULL),
(23, 2, 23373, N'If different, annual rent paid by you (and not reimbursed by your employer)', 2, NULL, 0, NULL),
(24, 2, 92550, N'Were these expenses borne by your employer?', 2, NULL, 0, NULL),
(25, 13, 92796, N'Annual rent paid to the landlord', 1, 1, 0, N'Rent'),
(26, 13, 20807, N'Council tax', 1, 2, 0, N'Council tax'),
(27, 13, 20808, N'Water rates', 1, 1, 0, N'Water rates'),
(28, 13, 20127, N'Utilities (e.g., gas, heating, electricity)', 1, 1, 0, N'Utilities'),
(29, 13, 92551, N'Insurance', 1, 1, 0, N'Insurance'),
(30, 13, 92552, N'Furniture rental', 1, 1, 0, N'Furniture rental'),
(31, 13, 20809, N'Travel', 1, 3, 0, N'Travel'),
(32, 13, 20810, N'Meals', 1, 3, 0, N'Meals'),
(33, 13, 20134, N'Other', 1, 3, 0, N'Other'),
(34, 13, 20133, N'Other description', 2, NULL, 1, NULL),
(35, 13, 23373, N'If different, annual rent paid by you (and not reimbursed by your employer)', 2, NULL, 0, NULL),
(36, 13, 92550, N'Were these expenses borne by your employer?', 2, NULL, 0, NULL),
(37, 14, 92796, N'Annual rent paid to the landlord', 1, 1, 0, N'Rent'),
(38, 14, 20807, N'Council tax', 1, 2, 0, N'Council tax'),
(39, 14, 20808, N'Water rates', 1, 1, 0, N'Water rates'),
(40, 14, 20127, N'Utilities (e.g., gas, heating, electricity)', 1, 1, 0, N'Utilities'),
(41, 14, 92551, N'Insurance', 1, 1, 0, N'Insurance'),
(42, 14, 92552, N'Furniture rental', 1, 1, 0, N'Furniture rental'),
(43, 14, 20809, N'Travel', 1, 3, 0, N'Travel'),
(44, 14, 20810, N'Meals', 1, 3, 0, N'Meals'),
(45, 14, 20134, N'Other', 1, 3, 0, N'Other'),
(46, 14, 20133, N'Other description', 2, NULL, 1, NULL),
(47, 14, 23373, N'If different, annual rent paid by you (and not reimbursed by your employer)', 2, NULL, 0, NULL),
(48, 14, 92550, N'Were these expenses borne by your employer?', 2, NULL, 0, NULL),
(49, 1, 20477, N'Assignee DDR Note', 2, NULL, 0, NULL),
(50, 2, 20477, N'Assignee DDR Note', 2, NULL, 0, NULL),
(51, 13, 20477, N'Assignee DDR Note', 2, NULL, 0, NULL),
(52, 14, 20477, N'Assignee DDR Note', 2, NULL, 0, NULL)

) AS Source ([Id], [TaxYearId], [OrganizerStaticCode], [Text], [DdrAssigneeQuestionTypeId], [DdrReductionTypeId], [Hidden], [DigitaExportText])
ON Target.Id = Source.Id

-- Update matched rows (except date)
WHEN MATCHED THEN
UPDATE SET 
	[TaxYearId] = Source.[TaxYearId],
	[OrganizerStaticCode] = Source.[OrganizerStaticCode],
	[Text] = Source.[Text],
	[DdrAssigneeQuestionTypeId] = Source.[DdrAssigneeQuestionTypeId],
	[DdrReductionTypeId] = Source.[DdrReductionTypeId],
	[Hidden] = Source.[Hidden],
	[DigitaExportText] = Source.[DigitaExportText]

-- Insert new rows
WHEN NOT MATCHED BY TARGET THEN
INSERT ([Id], [TaxYearId], [OrganizerStaticCode], [Text], [DdrAssigneeQuestionTypeId], [DdrReductionTypeId], [Hidden], [DigitaExportText])
VALUES ([Id], [TaxYearId], [OrganizerStaticCode], [Text], [DdrAssigneeQuestionTypeId], [DdrReductionTypeId], [Hidden], [DigitaExportText])

-- Delete missing rows
WHEN NOT MATCHED BY SOURCE THEN
DELETE;

--Ca.DataBase_Data_3.14_To_3.14.1

/*************************** Data script end **************************/


PRINT N'Data update complete.'


DECLARE @VersionName varchar(50) = 'Data'
DECLARE @Version varchar(50) = '3.14'

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