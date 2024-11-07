/*
Ca data update script from release 2.13 to release 2.14

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

DECLARE @ExpectedDatabaseName varchar(50) = 'TaxSRTv2_Web'

/* ------------------------------------------------------------------------------- */

IF (SELECT DB_NAME()) <> @ExpectedDatabaseName
BEGIN
	PRINT N'The current database is incorrect - stopping execution.'
	-- Nothing will execute from now on...
	set noexec on
END

DECLARE @VersionKey varchar(50) = 'Data'
DECLARE @FromVersion varchar(50) = '2.13'
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

-- Data_2.13_to_2.14 

PRINT N'Updating [dbo].[Country]...'

SET IDENTITY_INSERT [dbo].[Country]  ON

MERGE INTO [dbo].[Country] AS Target
USING (VALUES

(252, 'BQ', 'BES', N'Bonaire', NULL, 0, 0, 0, 0, 0, 0)

) AS Source ([CountryID], [CountryCode], [ThreeCharCode], [CountryName], [CurrencyID], [ECCountry], [EEACountry], [A8Country], [ESTACountry], [SchengenCountry], [HasState])
ON Target.[CountryID] = Source.[CountryID] 

WHEN MATCHED THEN
UPDATE SET 
	CountryCode = Source.CountryCode,
	ThreeCharCode = Source.ThreeCharCode,
	CountryName = Source.CountryName,
	CurrencyID = Source.CurrencyID,
	ECCountry = Source.ECCountry,
	EEACountry = Source.EEACountry,
	A8Country = Source.A8Country,
	ESTACountry = Source.ESTACountry,
	SchengenCountry = Source.SchengenCountry,
	HasState = Source.HasState

-- Insert new rows
WHEN NOT MATCHED BY TARGET THEN
INSERT ([CountryID], [CountryCode], [ThreeCharCode], [CountryName], [CurrencyID], [ECCountry], [EEACountry], [A8Country], [ESTACountry], [SchengenCountry], [HasState])
VALUES ([CountryID], [CountryCode], [ThreeCharCode], [CountryName], [CurrencyID], [ECCountry], [EEACountry], [A8Country], [ESTACountry], [SchengenCountry], [HasState]);

SET IDENTITY_INSERT [dbo].[Country] OFF


-- Data_2.13_to_2.14

-- Data_2.14_to_2.14.1 


PRINT N'Updating [dbo].[DayType]...'

SET IDENTITY_INSERT [dbo].[DayType]  ON

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

) AS Source ([DayTypeID], [DayTypeCode], [DayTypeDescription], [IsShadowDayType], [NeedsShadowEntry])
ON Target.[DayTypeID] = Source.[DayTypeID] 

WHEN MATCHED THEN
UPDATE SET 
	[DayTypeCode] = Source.[DayTypeCode],
	[DayTypeDescription] = Source.[DayTypeDescription],
	[IsShadowDayType] = source.[IsShadowDayType],
	[NeedsShadowEntry] = source.[NeedsShadowEntry]

-- Insert new rows
WHEN NOT MATCHED BY TARGET THEN
INSERT ([DayTypeID], [DayTypeCode], [DayTypeDescription], [IsShadowDayType], [NeedsShadowEntry])
VALUES ([DayTypeID], [DayTypeCode], [DayTypeDescription], [IsShadowDayType], [NeedsShadowEntry]);

SET IDENTITY_INSERT [dbo].[DayType] OFF

-- Data_2.14_to_2.14.1 

PRINT N'Update complete.';

PRINT 'The database update succeeded.'
PRINT ''
PRINT N'Updating the KPMG version table.';

DECLARE @VersionKey varchar(50) = 'Data'
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
