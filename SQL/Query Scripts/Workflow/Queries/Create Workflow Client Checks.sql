/* Author: Brian Donnelly */


SET NOEXEC OFF

GO
SET ANSI_NULLS, ANSI_PADDING, ANSI_WARNINGS, ARITHABORT, CONCAT_NULL_YIELDS_NULL, QUOTED_IDENTIFIER ON;

/* ------------------------------------------------------------------------------- */
/* REQUIRED: Set @ExpectedDatabaseName to the database this should be executed on. */
/* ------------------------------------------------------------------------------- */

DECLARE @ExpectedDatabaseName VARCHAR(50) = 'TaxWFPortalData'

/* ------------------------------------------------------------------------------- */

IF (SELECT DB_NAME()) <> @ExpectedDatabaseName
BEGIN
	PRINT N'The current database is incorrect - stopping execution.'
	-- Nothing will execute from now on...
	SET NOEXEC ON
END

DECLARE @OpportunityId NVARCHAR(10) = 7954085
DECLARE @SuppliedClientNumber NVARCHAR(10) = 60430373
DECLARE @ReturnedClientNumber NVARCHAR(10)
DECLARE @ClientID INT

SET @ReturnedClientNumber = (SELECT ClientNumber FROM  [UKDTASQLCLU05\MSSQLUKDTADB07].SAPExtract.dbo.[TaxWorkflow_TaxComplianceOpportunities] WHERE OpportunityNumber = @OpportunityId)

IF (@SuppliedClientNumber <> @ReturnedClientNumber)
BEGIN
	PRINT N'The supplied SAP/MSD client number of ' + @SuppliedClientNumber + N' does not match the SAP/MSD client number of ' + @ReturnedClientNumber + N' for the supplied opportunity ID of ' + @OpportunityId
	SET NOEXEC ON
	-- Nothing will execute from now on..
END
ELSE
BEGIN
	PRINT N'This Section has not been coded yet...'
END

/*------------------------------------------------------- Schema Script Start */

--GO

--BEGIN TRY
--	PRINT N''
--END TRY

--BEGIN CATCH  
--    SELECT   
--        ERROR_NUMBER() AS ErrorNumber  
--        ,ERROR_SEVERITY() AS ErrorSeverity  
--        ,ERROR_STATE() AS ErrorState  
--        ,ERROR_PROCEDURE() AS ErrorProcedure  
--        ,ERROR_LINE() AS ErrorLine  
--        ,ERROR_MESSAGE() AS ErrorMessage;  
  
--    IF @@TRANCOUNT > 0  
--        ROLLBACK TRANSACTION;  
--END CATCH;  

--IF @@TRANCOUNT > 0  
--    COMMIT TRANSACTION;
--	SET TRANSACTION ISOLATION LEVEL READ COMMITTED;    
--GO  