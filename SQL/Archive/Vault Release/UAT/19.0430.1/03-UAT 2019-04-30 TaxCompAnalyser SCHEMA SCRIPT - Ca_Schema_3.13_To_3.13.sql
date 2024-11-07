
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
DECLARE @ToVersion varchar(50) = '3.13'
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

/************** This script needs to be executed at the end during release!!!!!!!!!!!!! *******/

--Ca_Schema_3.10_To_3.11

PRINT N'Altering [dbo].[Population]...';

ALTER TABLE [dbo].[Population]
    ALTER COLUMN [DDRAmountOriginId] INT NOT NULL;

--Ca_Schema_3.10_To_3.11

--Ca_Schema_3.13_To_3.13.1

PRINT N'Altering [dbo].[PensionForm]...';

ALTER TABLE [dbo].[PensionForm]
    ALTER COLUMN [DefinedBenefitTaxableValue] DECIMAL (12, 2) NOT NULL;
	
--Ca_Schema_3.13_To_3.13.1

--Ca_Schema_3.13.4_To_3.13.5

PRINT N'Altering [dbo].[FamilyAccompaniment]...';

ALTER TABLE [dbo].[FamilyAccompaniment]
	ALTER COLUMN ChildrenRequired BIT NOT NULL;
	
ALTER TABLE [dbo].[FamilyAccompaniment]
	ALTER COLUMN Name NVARCHAR(50) NOT NULL;

--Ca_Schema_3.13.4_To_3.13.5	

/********************************************* Schema changes end ****************************************************************/


PRINT N'Update complete.';

PRINT 'The database update succeeded.'
PRINT ''
PRINT N'Updating the KPMG version table.';

DECLARE @VersionKey varchar(50) = 'Schema'
DECLARE @ToVersion varchar(50) = '3.13'

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