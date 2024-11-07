
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
DECLARE @FromVersion varchar(50) = '3.13'
DECLARE @ToVersion varchar(50) = '3.14'
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

-- Ca_Schema_3.13.5_To_3.14

PRINT N'Creating [dbo].[DdrInputAmountHistory]...';

CREATE TABLE [dbo].[DdrInputAmountHistory]
(
	[Id] INT NOT NULL PRIMARY KEY IDENTITY(1, 1),
	[DdrProcessingId] INT NOT NULL,
	[OriginalAmount] DECIMAL(12, 2) NULL,
	[LastUpdatedDate] DATETIME NOT NULL,
	[LastUpdatedByUserId] INT NOT NULL,
	CONSTRAINT [FK_DdrInputAmountHistory_DdrProcessing] FOREIGN KEY (DdrProcessingId) REFERENCES [DdrProcessing](Id),
	CONSTRAINT [FK_DdrInputAmountHistory_LastUpdatedByUser] FOREIGN KEY (LastUpdatedByUserId) REFERENCES [Users](Id),
)


PRINT N'Creating [dbo].[IX_DdrInputAmountHistory_DdrProcessing]...';

CREATE NONCLUSTERED INDEX [IX_DdrInputAmountHistory_DdrProcessing]
    ON [dbo].[DdrInputAmountHistory]([DdrProcessingId] ASC);



PRINT N'Creating [dbo].[DdrInputAmountOriginHistory]...';

CREATE TABLE [dbo].[DdrInputAmountOriginHistory]
(
	[Id] INT NOT NULL PRIMARY KEY IDENTITY(1, 1),
	[DdrProcessingId] INT NOT NULL,
	[OriginalDdrAmountOriginId] INT NOT NULL,
	[LastUpdatedDate] DATETIME NOT NULL,
	[LastUpdatedByUserId] INT NOT NULL,
	CONSTRAINT [FK_DdrInputAmountOriginHistory_DdrProcessing] FOREIGN KEY (DdrProcessingId) REFERENCES [DdrProcessing](Id),
	CONSTRAINT [FK_DdrInputAmountOriginHistory_LastUpdatedByUser] FOREIGN KEY (LastUpdatedByUserId) REFERENCES [Users](Id),
	CONSTRAINT [FK_DdrInputAmountOriginHistory_OriginalDdrAmountOrigin] FOREIGN KEY (OriginalDdrAmountOriginId) REFERENCES [DDRAmountOrigin](Id),
)

PRINT N'Creating [dbo].[IX_DdrInputAmountOriginHistory_DdrProcessing]...';

CREATE NONCLUSTERED INDEX [IX_DdrInputAmountOriginHistory_DdrProcessing]
    ON [dbo].[DdrInputAmountOriginHistory]([DdrProcessingId] ASC);


PRINT N'Creating [dbo].[DdrInputCurrencyHistory]...';

CREATE TABLE [dbo].[DdrInputCurrencyHistory]
(
	[Id] INT NOT NULL PRIMARY KEY IDENTITY(1, 1),
	[DdrProcessingId] INT NOT NULL,
	[OriginalCurrencyId] INT NOT NULL,
	[LastUpdatedDate] DATETIME NOT NULL,
	[LastUpdatedByUserId] INT NOT NULL,
	CONSTRAINT [FK_DdrInputCurrencyHistory_DdrProcessing] FOREIGN KEY (DdrProcessingId) REFERENCES [DdrProcessing](Id),
	CONSTRAINT [FK_DdrInputCurrencyHistory_LastUpdatedByUser] FOREIGN KEY (LastUpdatedByUserId) REFERENCES [Users](Id),
	CONSTRAINT [FK_DdrInputCurrencyHistory_OriginalCurrency] FOREIGN KEY (OriginalCurrencyId) REFERENCES [Currency](Id),
)


PRINT N'Creating [dbo].[IX_DdrInputCurrencyHistory_DdrProcessing]...';

CREATE NONCLUSTERED INDEX [IX_DdrInputCurrencyHistory_DdrProcessing]
    ON [dbo].[DdrInputCurrencyHistory]([DdrProcessingId] ASC);


PRINT N'Creating [dbo].[DdrInputFamilyAccompanimentHistory]...';

CREATE TABLE [dbo].[DdrInputFamilyAccompanimentHistory]
(
	[Id] INT NOT NULL PRIMARY KEY IDENTITY(1, 1),
	[DdrProcessingId] INT NOT NULL,
	[OriginalFamilyAccompanimentId] INT NOT NULL,
	[LastUpdatedDate] DATETIME NOT NULL,
	[LastUpdatedByUserId] INT NOT NULL,
	CONSTRAINT [FK_DdrInputFamilyAccompanimentHistory_DdrProcessing] FOREIGN KEY (DdrProcessingId) REFERENCES [DdrProcessing](Id),
	CONSTRAINT [FK_DdrInputFamilyAccompanimentHistory_LastUpdatedByUser] FOREIGN KEY (LastUpdatedByUserId) REFERENCES [Users](Id),
	CONSTRAINT [FK_DdrInputFamilyAccompanimentHistory_OriginalFamilyAccompaniment] FOREIGN KEY (OriginalFamilyAccompanimentId) REFERENCES [FamilyAccompaniment](Id),
)


PRINT N'Creating [dbo].[IX_DdrInputFamilyAccompanimentHistory_DdrProcessing]...';

CREATE NONCLUSTERED INDEX [IX_DdrInputFamilyAccompanimentHistory_DdrProcessing]
    ON [dbo].[DdrInputFamilyAccompanimentHistory]([DdrProcessingId] ASC);


PRINT N'Creating [dbo].[dbo].[DdrInputFxRateHistory]...';

CREATE TABLE [dbo].[DdrInputFxRateHistory]
(
	[Id] INT NOT NULL PRIMARY KEY IDENTITY(1, 1),
	[DdrProcessingId] INT NOT NULL,
	[OriginalFxRate] DECIMAL(18, 6) NULL,
	[LastUpdatedDate] DATETIME NOT NULL,
	[LastUpdatedByUserId] INT NOT NULL,
	CONSTRAINT [FK_DdrInputFxRateHistory_DdrProcessing] FOREIGN KEY (DdrProcessingId) REFERENCES [DdrProcessing](Id),
	CONSTRAINT [FK_DdrInputFxRateHistory_LastUpdatedByUser] FOREIGN KEY (LastUpdatedByUserId) REFERENCES [Users](Id),
)


PRINT N'Creating [dbo].[IX_DdrInputFxRateHistory_DdrProcessing]...';

CREATE NONCLUSTERED INDEX [IX_DdrInputFxRateHistory_DdrProcessing]
    ON [dbo].[DdrInputFxRateHistory]([DdrProcessingId] ASC);


PRINT N'Creating [dbo].[DdrInputNumberHistory]...';

CREATE TABLE [dbo].[DdrInputNumberHistory]
(
	[Id] INT NOT NULL PRIMARY KEY IDENTITY(1, 1),
	[DdrProcessingId] INT NOT NULL,
	[OriginalNumber] INT NULL,
	[LastUpdatedDate] DATETIME NOT NULL,
	[LastUpdatedByUserId] INT NOT NULL,
	CONSTRAINT [FK_DdrInputNumberHistory_DdrProcessing] FOREIGN KEY (DdrProcessingId) REFERENCES [DdrProcessing](Id),
	CONSTRAINT [FK_DdrInputNumberHistory_LastUpdatedByUser] FOREIGN KEY (LastUpdatedByUserId) REFERENCES [Users](Id),
)


PRINT N'Creating [dbo].[IX_DdrInputNumberHistory_DdrProcessing]...';

CREATE NONCLUSTERED INDEX [IX_DdrInputNumberHistory_DdrProcessing]
    ON [dbo].[DdrInputNumberHistory]([DdrProcessingId] ASC);



PRINT N'Creating [dbo].[DdrInputPercentageHistory]...';

CREATE TABLE [dbo].[DdrInputPercentageHistory]
(
	[Id] INT NOT NULL PRIMARY KEY IDENTITY(1, 1),
	[DdrProcessingId] INT NOT NULL,
	[OriginalPercentage] DECIMAL(3, 0) NOT NULL,
	[LastUpdatedDate] DATETIME NOT NULL,
	[LastUpdatedByUserId] INT NOT NULL,
	CONSTRAINT [FK_DdrInputPercentageHistory_DdrProcessing] FOREIGN KEY (DdrProcessingId) REFERENCES [DdrProcessing](Id),
	CONSTRAINT [FK_DdrInputPercentageHistory_LastUpdatedByUser] FOREIGN KEY (LastUpdatedByUserId) REFERENCES [Users](Id),
)


PRINT N'Creating [dbo].[IX_DdrInputPercentageHistory_DdrProcessing]...';

CREATE NONCLUSTERED INDEX [IX_DdrInputPercentageHistory_DdrProcessing]
    ON [dbo].[DdrInputPercentageHistory]([DdrProcessingId] ASC);



PRINT N'Altering [dbo].[DdrAssigneeCurrency]...';

ALTER TABLE [dbo].[DdrAssigneeCurrency]
    ADD [CurrencyHistoryId] INT NULL,
        [FxRateHistoryId] INT NULL,
		CONSTRAINT [FK_DdrAssigneeCurrency_CurrencyHistory] FOREIGN KEY (CurrencyHistoryId) REFERENCES [DdrInputCurrencyHistory](Id),
		CONSTRAINT [FK_DdrAssigneeCurrency_FxRateHistory] FOREIGN KEY (FxRateHistoryId) REFERENCES [DdrInputFxRateHistory](Id);



PRINT N'Altering [dbo].[DdrAssigneeExpense]...';

ALTER TABLE [dbo].[DdrAssigneeExpense]
    ADD [TotalAmountHistoryId] INT NULL,
        [ReductionPercentageHistoryId] INT NULL,
		CONSTRAINT [FK_DdrAssigneeExpense_TotalAmountHistory] FOREIGN KEY (TotalAmountHistoryId) REFERENCES [DdrInputAmountHistory](Id),
		CONSTRAINT [FK_DdrAssigneeExpense_ReductionPercentageHistory] FOREIGN KEY (ReductionPercentageHistoryId) REFERENCES [DdrInputPercentageHistory](Id);



PRINT N'Altering [dbo].[DdrBasicInput]...';

ALTER TABLE [dbo].[DdrBasicInput]
    ADD [FamilyAccompanimentHistoryId] INT NULL,
        [NoOfChildrenHistoryId] INT NULL,
		CONSTRAINT [FK_DdrBasicInput_FamilyAccompanimentHistory] FOREIGN KEY (FamilyAccompanimentHistoryId) REFERENCES [DdrInputFamilyAccompanimentHistory](Id),
		CONSTRAINT [FK_DdrBasicInput_NoOfChildrenHistory] FOREIGN KEY (NoOfChildrenHistoryId) REFERENCES [DdrInputNumberHistory](Id);



PRINT N'Altering [dbo].[DdrEmployerExpense]...';

ALTER TABLE [dbo].[DdrEmployerExpense]
    ADD [ReductionPercentageHistoryId] INT NULL,
	CONSTRAINT [FK_DdrEmployerExpense_ReductionPercentageHistory] FOREIGN KEY (ReductionPercentageHistoryId) REFERENCES [DdrInputPercentageHistory](Id);



PRINT N'Altering [dbo].[DdrPopulationInput]...';

ALTER TABLE [dbo].[DdrPopulationInput]
    ADD [DdrAmountOriginHistoryId] INT NULL,
	CONSTRAINT [FK_DdrPopulationInput_DdrAmountOriginHistory] FOREIGN KEY (DdrAmountOriginHistoryId) REFERENCES [DdrInputAmountOriginHistory](Id);

-- Ca_Schema_3.13.5_To_3.14

-- Ca_Schema_3.14_To_3.14.1

PRINT N'Altering [dbo].[DdrAssigneeQuestion]...';

ALTER TABLE [dbo].[DdrAssigneeQuestion]
    ADD [DigitaExportText] NVARCHAR (MAX) NULL;

-- Ca_Schema_3.14_To_3.14.1

-- Ca_Schema_3.14.1_To_3.14.2

PRINT N'Creating [dbo].[DdrComment]...';

CREATE TABLE [dbo].[DdrComment]
(
	[Id] INT NOT NULL PRIMARY KEY IDENTITY(1, 1),
	[AssigneeGTSId] INT NOT NULL,
	[TaxYearId] INT NOT NULL,
	[Comment] NVARCHAR(200) NOT NULL, 
    [UserId] INT NOT NULL, 
    [CreatedDate] DATETIME NOT NULL,
	CONSTRAINT [FK_DdrComment_Assignee] FOREIGN KEY([AssigneeGTSId]) REFERENCES [dbo].[Assignee] ([GTSId]),
	CONSTRAINT [FK_DdrComment_TaxYear] FOREIGN KEY (TaxYearId) REFERENCES [TaxYear](Id),
	CONSTRAINT [FK_DdrComment_User] FOREIGN KEY([UserId]) REFERENCES [dbo].[Users] ([Id])
)


PRINT N'Creating [dbo].[IX_DdrComment_Assignee_TaxYear_CreatedDate]...';

CREATE NONCLUSTERED INDEX [IX_DdrComment_Assignee_TaxYear_CreatedDate]
    ON [dbo].[DdrComment]([AssigneeGTSId] ASC, [TaxYearId] ASC, [CreatedDate] DESC)


PRINT N'Creating [dbo].[IX_DdrComment_TaxYear_Assignee_CreatedDate]...';

CREATE NONCLUSTERED INDEX [IX_DdrComment_TaxYear_Assignee_CreatedDate]
    ON [dbo].[DdrComment]([TaxYearId] ASC, [AssigneeGTSId] ASC, [CreatedDate] DESC)

-- Ca_Schema_3.14.1_To_3.14.2

/********************************************* Schema changes end ****************************************************************/


PRINT N'Update complete.';

PRINT 'The database update succeeded.'
PRINT ''
PRINT N'Updating the KPMG version table.';

DECLARE @VersionKey varchar(50) = 'Schema'
DECLARE @ToVersion varchar(50) = '3.14'

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