/*
Ca schema update script from release 2.12 to 2.14

*/
set noexec off

GO
SET ANSI_NULLS, ANSI_PADDING, ANSI_WARNINGS, ARITHABORT, CONCAT_NULL_YIELDS_NULL, QUOTED_IDENTIFIER ON;

SET NUMERIC_ROUNDABORT OFF;

SET XACT_ABORT ON
GO
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
GO
BEGIN TRANSACTION
GO

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
DECLARE @FromVersion varchar(50) = '2.12'
DECLARE @ToVersion varchar(50) = '2.14'
DECLARE @CurrentVersion varchar(50) = (SELECT [Version] FROM [dbo].[Version] WHERE [Key] = @VersionKey)

IF (@CurrentVersion <> @FromVersion)
BEGIN
	PRINT N'The current version of ' + @CurrentVersion + N' does not match the required version of ' + @FromVersion + N' for this script to execute.'
	set noexec on
	-- Nothing will execute from now on...
END

/*------------------------------------------------------- Schema Script Start */

GO

BEGIN TRY


-- Ca_Schema_2.12_To_2.14


PRINT N'Altering [dbo].[DayType]...';

ALTER TABLE [dbo].[DayType]
    ADD [IsShadowDayType]  BIT DEFAULT 0 NOT NULL,
        [NeedsShadowEntry] BIT DEFAULT 0 NOT NULL;


-- Ca_Schema_2.12_To_2.14

-- Ca_Schema_2.14_To_2.14.1


PRINT N'Dropping [dbo].[FxRate].[IX_FxRate_ClientId]...';

DROP INDEX [IX_FxRate_ClientId]
    ON [dbo].[FxRate];


PRINT N'Dropping [dbo].[FxSpotRate].[IX_FxSpotRate_ClientId]...';

DROP INDEX [IX_FxSpotRate_ClientId]
    ON [dbo].[FxSpotRate];



PRINT N'Creating [dbo].[Assignee].[IX_Assignee_LastName]...';

CREATE NONCLUSTERED INDEX [IX_Assignee_LastName]
    ON [dbo].[Assignee]([LastName] ASC);



PRINT N'Creating [dbo].[AssigneeExport].[IX_AssigneeExport_TaxYearId_Date]...';

CREATE NONCLUSTERED INDEX [IX_AssigneeExport_TaxYearId_Date]
    ON [dbo].[AssigneeExport]([TaxYearId] ASC, [Date] DESC);



PRINT N'Creating [dbo].[AssigneeExportLog].[IX_AssigneeExportLog_AssigneeExportId]...';

CREATE NONCLUSTERED INDEX [IX_AssigneeExportLog_AssigneeExportId]
    ON [dbo].[AssigneeExportLog]([AssigneeExportId] ASC);



PRINT N'Creating [dbo].[AssigneeProcessing].[IX_AssigneeProcessing_CascadeDeleteId]...';

CREATE NONCLUSTERED INDEX [IX_AssigneeProcessing_CascadeDeleteId]
    ON [dbo].[AssigneeProcessing]([CascadeDeleteId] ASC) WHERE CascadeDeleteId IS NOT NULL;



PRINT N'Creating [dbo].[Compensation].[IX_Compensation_ImportRollbackId]...';

CREATE NONCLUSTERED INDEX [IX_Compensation_ImportRollbackId]
    ON [dbo].[Compensation]([ImportRollbackId] ASC) WHERE ImportRollbackId IS NOT NULL;



PRINT N'Creating [dbo].[CompensationNameEqualisationPolicy].[IX_CompensationNameEqualisationPolicy_EqualisationPolicyId]...';

CREATE NONCLUSTERED INDEX [IX_CompensationNameEqualisationPolicy_EqualisationPolicyId]
    ON [dbo].[CompensationNameEqualisationPolicy]([EqualisationPolicyId] ASC);



PRINT N'Creating [dbo].[DetachedDutyRelief].[IX_DetachedDutyRelief_AssigneeGTSId]...';

CREATE NONCLUSTERED INDEX [IX_DetachedDutyRelief_AssigneeGTSId]
    ON [dbo].[DetachedDutyRelief]([AssigneeGTSId] ASC);



PRINT N'Creating [dbo].[EqualisationPolicy].[IX_EqualisationPolicy_EqualisationPolicyNameId]...';

CREATE NONCLUSTERED INDEX [IX_EqualisationPolicy_EqualisationPolicyNameId]
    ON [dbo].[EqualisationPolicy]([EqualisationPolicyNameId] ASC);



PRINT N'Creating [dbo].[EqualisationPolicy].[IX_EqualisationPolicy_TaxYearId_PopulationId]...';

CREATE NONCLUSTERED INDEX [IX_EqualisationPolicy_TaxYearId_PopulationId]
    ON [dbo].[EqualisationPolicy]([TaxYearId] ASC, [PopulationId] ASC);



PRINT N'Creating [dbo].[FxRate].[IX_FxRate_ClientId_TaxYearId_CurrencyId]...';

CREATE NONCLUSTERED INDEX [IX_FxRate_ClientId_TaxYearId_CurrencyId]
    ON [dbo].[FxRate]([ClientId] ASC, [TaxYearId] ASC, [CurrencyId] ASC);



PRINT N'Creating [dbo].[FxSpotRate].[IX_FxSpotRate_ClientId_Date_CurrencyId]...';

CREATE NONCLUSTERED INDEX [IX_FxSpotRate_ClientId_Date_CurrencyId]
    ON [dbo].[FxSpotRate]([ClientId] ASC, [Date] ASC, [CurrencyId] ASC);



PRINT N'Creating [dbo].[HmrcFxRate].[IX_HmrcFxRate_TaxYearId_CurrencyId]...';

CREATE NONCLUSTERED INDEX [IX_HmrcFxRate_TaxYearId_CurrencyId]
    ON [dbo].[HmrcFxRate]([TaxYearId] ASC, [CurrencyId] ASC);



PRINT N'Creating [dbo].[OANDAFxRate].[IX_OANDAFxRate_ClientId_TaxYearId_CurrencyId]...';

CREATE NONCLUSTERED INDEX [IX_OANDAFxRate_ClientId_TaxYearId_CurrencyId]
    ON [dbo].[OANDAFxRate]([StartDate] ASC, [EndDate] ASC, [CurrencyId] ASC);



PRINT N'Creating [dbo].[OANDAFxRate].[IX_OANDAFxRate_CurrencyId]...';

CREATE NONCLUSTERED INDEX [IX_OANDAFxRate_CurrencyId]
    ON [dbo].[OANDAFxRate]([CurrencyId] ASC);



PRINT N'Creating [dbo].[PopulationCompensationName].[IX_PopulationCompensationName_ImportRollbackId]...';

CREATE NONCLUSTERED INDEX [IX_PopulationCompensationName_ImportRollbackId]
    ON [dbo].[PopulationCompensationName]([ImportRollbackId] ASC) WHERE ImportRollbackId IS NOT NULL;



PRINT N'Creating [dbo].[PopulationExport].[IX_PopulationExport_PopulationId]...';

CREATE NONCLUSTERED INDEX [IX_PopulationExport_PopulationId]
    ON [dbo].[PopulationExport]([PopulationId] ASC);



PRINT N'Creating [dbo].[ProcessedCompensationRate].[IX_ProcessedCompensationRate_AssigneeProcessingId]...';

CREATE NONCLUSTERED INDEX [IX_ProcessedCompensationRate_AssigneeProcessingId]
    ON [dbo].[ProcessedCompensationRate]([AssigneeProcessingId] ASC);



PRINT N'Creating [dbo].[QualifyingRelocationRelief].[IX_QualifyingRelocationRelief_AssigneeGTSId]...';

CREATE NONCLUSTERED INDEX [IX_QualifyingRelocationRelief_AssigneeGTSId]
    ON [dbo].[QualifyingRelocationRelief]([AssigneeGTSId] ASC);



PRINT N'Creating [dbo].[Region].[IX_Region_CountryId]...';

CREATE NONCLUSTERED INDEX [IX_Region_CountryId]
    ON [dbo].[Region]([CountryId] ASC);



PRINT N'Creating [dbo].[Stock].[IX_Stock_ImportRollbackId]...';

CREATE NONCLUSTERED INDEX [IX_Stock_ImportRollbackId]
    ON [dbo].[Stock]([ImportRollbackId] ASC) WHERE ImportRollbackId IS NOT NULL;



PRINT N'Creating [dbo].[Stock].[IX_Stock_PopulationAssigneeId]...';

CREATE NONCLUSTERED INDEX [IX_Stock_PopulationAssigneeId]
    ON [dbo].[Stock]([PopulationAssigneeId] ASC);



PRINT N'Creating [dbo].[Stock].[IX_Stock_StockPlanId]...';

CREATE NONCLUSTERED INDEX [IX_Stock_StockPlanId]
    ON [dbo].[Stock]([StockPlanId] ASC);



PRINT N'Creating [dbo].[StockPlan].[IX_StockPlan_PopulationId_TaxYearId]...';

CREATE NONCLUSTERED INDEX [IX_StockPlan_PopulationId_TaxYearId]
    ON [dbo].[StockPlan]([PopulationId] ASC, [TaxYearId] ASC);



PRINT N'Creating [dbo].[UserRoles].[IX_UserRoles_RoleID]...';

CREATE NONCLUSTERED INDEX [IX_UserRoles_RoleID]
    ON [dbo].[UserRoles]([RoleID] ASC);



PRINT N'Creating [dbo].[UserRoles].[IX_UserRoles_UserID]...';

CREATE NONCLUSTERED INDEX [IX_UserRoles_UserID]
    ON [dbo].[UserRoles]([UserID] ASC);


-- Ca_Schema_2.14_To_2.14.1


PRINT N'Update complete.';

PRINT 'The database update succeeded.'
PRINT ''
PRINT N'Updating the KPMG version table.';

DECLARE @VersionKey varchar(50) = 'Schema'
DECLARE @ToVersion varchar(50) = '2.14'

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