
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

DECLARE @VersionKey varchar(50) = 'Schema'
DECLARE @FromVersion varchar(50) = '3.14'
DECLARE @ToVersion varchar(50) = '3.15'
DECLARE @CurrentVersion varchar(50) = (SELECT [Version] FROM [dbo].[Version] WHERE [Key] = @VersionKey)

IF (@CurrentVersion <> @FromVersion)
BEGIN
	PRINT N'The current version of ' + @CurrentVersion + N' does not match the required version of ' + @FromVersion + N' for this script to execute.'
	set noexec on
	-- Nothing will execute from now on...
END

/*------------------------------------------------------- Schema Script Start */

GO

BEGIN TRANSACTION;

SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

SET XACT_ABORT ON;

BEGIN TRY

PRINT N'Begin update.';


/********************************************* Schema changes start **************************************************************/

-- Ca_Schema_3.14.2_To_3.15

PRINT N'Creating [dbo].[UsFtcLabel]...';

CREATE TABLE [dbo].[UsFtcLabel]
(
	[Id] INT NOT NULL PRIMARY KEY,
	[Text] NVARCHAR(200) NOT NULL,
)


PRINT N'Creating [dbo].[UsFtcLabelOverride]...';

CREATE TABLE [dbo].[UsFtcLabelOverride]
(
	[Id] INT NOT NULL PRIMARY KEY,
	[CalendarYear] INT NOT NULL,
	[UsFtcLabelId] INT NOT NULL,
	[Text] NVARCHAR(200),
	CONSTRAINT [FK_UsFtcLabelOverride_UsFtcLabel] FOREIGN KEY (UsFtcLabelId) REFERENCES [UsFtcLabel](Id)
)

PRINT N'Creating [dbo].[IX_UsFtcLabelOverride_CalendarYear_UsFtcLabel]...';

CREATE UNIQUE NONCLUSTERED INDEX [IX_UsFtcLabelOverride_CalendarYear_UsFtcLabel]
    ON [dbo].[UsFtcLabelOverride]([CalendarYear] ASC, [UsFtcLabelId] ASC);

-- Ca_Schema_3.14.2_To_3.15

-- Ca_Schema_3.15_To_3.15.1

PRINT N'Renaming [dbo].[QualifyingRelocationRelief].[AmountUsedInTaxYearOfTransfer]...';

EXEC('sp_rename ''QualifyingRelocationRelief.AmountUsedInTaxYearOfTransfer'', ''AmountUsedOutsideVault'', ''COLUMN'';');



PRINT N'Altering [dbo].[QualifyingRelocationRelief]...';

ALTER TABLE [dbo].[QualifyingRelocationRelief]
	ADD [CalculatedAmountInTaxYearOfTransfer] DECIMAL(6, 2) NOT NULL CONSTRAINT DF_QualifyingRelocationRelief_CalculatedAmountInTaxYearOfTransfer DEFAULT 0,
		[CalculatedAmountInFollowingTaxYear] DECIMAL(6, 2) NOT NULL CONSTRAINT DF_QualifyingRelocationRelief_CalculatedAmountInFollowingTaxYear DEFAULT 0;

ALTER TABLE [dbo].[QualifyingRelocationRelief]
	DROP CONSTRAINT DF_QualifyingRelocationRelief_CalculatedAmountInTaxYearOfTransfer,
					DF_QualifyingRelocationRelief_CalculatedAmountInFollowingTaxYear;


PRINT N'Altering [dbo].[RemunerationQualifyingRelocationRelief]...';

ALTER TABLE [dbo].[RemunerationQualifyingRelocationRelief]
	ADD [AmountUsed] DECIMAL(6, 2) NULL;
	

-- Ca_Schema_3.15_To_3.15.1

/********************************************* Schema changes end ****************************************************************/


PRINT N'Update complete.';

PRINT 'The database update succeeded.'
PRINT ''
PRINT N'Updating the KPMG version table.';

DECLARE @VersionKey varchar(50) = 'Schema'
DECLARE @ToVersion varchar(50) = '3.15'

UPDATE [dbo].[Version] SET [Version] = @ToVersion, [AppliedOn] = GETDATE()
	WHERE [Key] = @VersionKey

PRINT N'Update complete.';

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
GO  