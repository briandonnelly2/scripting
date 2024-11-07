
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
DECLARE @FromVersion varchar(50) = '3.15'
DECLARE @ToVersion varchar(50) = '3.15.1'
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

-- Ca_Schema_3.15.1_To_3.15.2


PRINT N'Creating [dbo].[IX_ProcessedCompensation_Compensation]...';

CREATE NONCLUSTERED INDEX [IX_ProcessedCompensation_Compensation]
    ON [dbo].[ProcessedCompensation]([CompensationId] ASC);



PRINT N'Creating [dbo].[IX_ProcessedCompensation_AssigneeResidenceCategory]...';

CREATE NONCLUSTERED INDEX [IX_ProcessedCompensation_AssigneeResidenceCategory]
    ON [dbo].[ProcessedCompensation]([AssigneeResidenceCategoryId] ASC);



PRINT N'Creating [dbo].[IX_ProcessedCompensationRate_Compensation]...';

CREATE NONCLUSTERED INDEX [IX_ProcessedCompensationRate_Compensation]
    ON [dbo].[ProcessedCompensationRate]([CompensationId] ASC);



PRINT N'Creating [dbo].[IX_RemunerationPayment_Compensation]...';

CREATE NONCLUSTERED INDEX [IX_RemunerationPayment_Compensation]
    ON [dbo].[RemunerationPayment]([CompensationId] ASC);



PRINT N'Creating [dbo].[IX_CompensationNameEqualisationPolicy_PopulationCompensationName]...';

CREATE NONCLUSTERED INDEX [IX_CompensationNameEqualisationPolicy_PopulationCompensationName]
    ON [dbo].[CompensationNameEqualisationPolicy]([PopulationCompensationNameId] ASC);
	


PRINT N'Creating [dbo].[IX_AssigneeCompNameOverride_CompensationName]...';

CREATE NONCLUSTERED INDEX [IX_AssigneeCompNameOverride_CompensationName]
    ON [dbo].[AssigneeCompNameOverride]([CompensationNameId] ASC);



PRINT N'Creating [dbo].[IX_RemunerationDetails_PopulationCompensationName]...';

CREATE NONCLUSTERED INDEX [IX_RemunerationDetails_PopulationCompensationName]
    ON [dbo].[RemunerationDetails]([PopulationCompensationNameId] ASC);



PRINT N'Creating [dbo].[IX_Assignment_EqualisationPolicyName]...';

CREATE NONCLUSTERED INDEX [IX_Assignment_EqualisationPolicyName] 
	ON [dbo].[Assignment] ([EqualisationPolicyNameId] ASC);



PRINT N'Creating [IX_ProcessedAssignment_EqualisationPolicyName]...';

CREATE NONCLUSTERED INDEX [IX_ProcessedAssignment_EqualisationPolicyName]
    ON [dbo].[ProcessedAssignment]([EqualisationPolicyNameId] ASC);


-- Ca_Schema_3.15.1_To_3.15.2


/********************************************* Schema changes end ****************************************************************/


PRINT N'Update complete.';

PRINT 'The database update succeeded.'
PRINT ''
PRINT N'Updating the KPMG version table.';

DECLARE @VersionKey varchar(50) = 'Schema'
DECLARE @ToVersion varchar(50) = '3.15.1'

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