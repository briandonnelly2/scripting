/*
Ca schema update script from release 2.13 to release 2.14

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

DECLARE @VersionKey varchar(50) = 'Schema'
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

-- Schema_2.13.1_to_2.14

PRINT N'Altering [dbo].[DayType]...';

ALTER TABLE [dbo].[DayType]
    ADD [IsShadowDayType] BIT DEFAULT 0 NOT NULL;

ALTER TABLE [dbo].[DayType]
    ADD [NeedsShadowEntry] BIT DEFAULT 0 NOT NULL;


PRINT N'Altering [dbo].[DayType_SelectAll]...';

EXEC('ALTER PROCEDURE [dbo].[DayType_SelectAll]
AS
BEGIN
	SET NOCOUNT ON;
	
	SELECT  DayTypeID,
			DayTypeCode,
			DayTypeDescription,
			IsShadowDayType,
			NeedsShadowEntry
    FROM  dbo.DayType

END')


PRINT N'Altering [dbo].[TaxPayerTravelDataBreakDown_Select]...';

EXEC('ALTER PROCEDURE [dbo].[TaxPayerTravelDataBreakDown_Select]
	@TaxPayerID	INT
AS
BEGIN
	SET NOCOUNT ON;

	SELECT  
		TaxPayerTravelDataBreakdown.*, 
		DayType.DayTypeCode ,
		DayType.DayTypeDescription as DayTypeName,
		DayType.IsShadowDayType as IsShadowDayType,
		DayType.NeedsShadowEntry as NeedsShadowEntry,
		Country.CountryCode,
		Country.CountryName,
		Region.RegionCode,
		Region.RegionName,
		City.Code as CityCode,
		City.Name as CityName,
		TravelDataBreakdownSource.Name as SourceName
	FROM 
		TaxPayerTravelDataBreakdown
		INNER JOIN DayType ON TaxPayerTravelDataBreakdown.DayTypeID = DayType.DayTypeID
		INNER JOIN  Country ON TaxPayerTravelDataBreakdown.CountryID = Country.CountryID
		LEFT JOIN Region ON TaxPayerTravelDataBreakdown.RegionID = Region.RegionID
		LEFT JOIN City ON TaxPayerTravelDataBreakdown.CityID = City.CityID
		INNER JOIN TravelDataBreakdownSource ON TaxPayerTravelDataBreakdown.SourceID = TravelDataBreakdownSource.SourceID
	WHERE
		TaxPayerTravelDataBreakdown.TaxPayerID	= @TaxPayerID
	ORDER BY [DAY] 
END')


PRINT N'Altering [dbo].[TaxPayerTravelDataBreakDown_SelectAllByDates]...';

EXEC('ALTER PROCEDURE [dbo].[TaxPayerTravelDataBreakDown_SelectAllByDates]
	@StartDate		DATETIME, 
	@EndDate		DATETIME
AS
BEGIN
	SET NOCOUNT ON;

	SELECT  
		TaxPayerTravelDataBreakdown.*, 
		DayType.DayTypeCode ,
		DayType.DayTypeDescription as DayTypeName,
		DayType.IsShadowDayType as IsShadowDayType,
		DayType.NeedsShadowEntry as NeedsShadowEntry,
		Country.CountryCode,
		Country.CountryName,
		Region.RegionCode,
		Region.RegionName,
		City.Code as CityCode,
		City.Name as CityName,
		TravelDataBreakdownSource.Name as SourceName
	FROM 
		TaxPayerTravelDataBreakdown
		INNER JOIN DayType ON TaxPayerTravelDataBreakdown.DayTypeID = DayType.DayTypeID
		INNER JOIN  Country ON TaxPayerTravelDataBreakdown.CountryID = Country.CountryID
		LEFT JOIN Region ON TaxPayerTravelDataBreakdown.RegionID = Region.RegionID
		LEFT JOIN City ON TaxPayerTravelDataBreakdown.CityID = City.CityID
		INNER JOIN TravelDataBreakdownSource ON TaxPayerTravelDataBreakdown.SourceID = TravelDataBreakdownSource.SourceID
	WHERE
		[DAY] BETWEEN @StartDate AND @EndDate
END')


PRINT N'Altering [dbo].[TaxPayerTravelDataBreakDown_SelectByDates]...';

EXEC('ALTER PROCEDURE [dbo].[TaxPayerTravelDataBreakDown_SelectByDates]
	@TaxPayerID		INT,
	@StartDate		DATETIME, 
	@EndDate		DATETIME
AS
BEGIN
	SET NOCOUNT ON;

	SELECT  
		TaxPayerTravelDataBreakdown.*, 
		DayType.DayTypeCode ,
		DayType.DayTypeDescription as DayTypeName,
		DayType.IsShadowDayType as IsShadowDayType,
		DayType.NeedsShadowEntry as NeedsShadowEntry,
		Country.CountryCode,
		Country.CountryName,
		Region.RegionCode,
		Region.RegionName,
		City.Code as CityCode,
		City.Name as CityName,
		TravelDataBreakdownSource.Name as SourceName
	FROM 
		TaxPayerTravelDataBreakdown
		INNER JOIN DayType ON TaxPayerTravelDataBreakdown.DayTypeID = DayType.DayTypeID
		INNER JOIN  Country ON TaxPayerTravelDataBreakdown.CountryID = Country.CountryID
		LEFT JOIN Region ON TaxPayerTravelDataBreakdown.RegionID = Region.RegionID
		LEFT JOIN City ON TaxPayerTravelDataBreakdown.CityID = City.CityID
		INNER JOIN TravelDataBreakdownSource ON TaxPayerTravelDataBreakdown.SourceID = TravelDataBreakdownSource.SourceID
	WHERE
		TaxPayerTravelDataBreakdown.TaxPayerID	= @TaxPayerID		AND	
		[DAY] BETWEEN @StartDate AND @EndDate
	ORDER BY 
		[DAY] 
END')


PRINT N'Refreshing [dbo].[DayType_Select]...';

EXECUTE sp_refreshsqlmodule N'[dbo].[DayType_Select]';

PRINT N'Altering [dbo].[HasTaxYearData]...';

EXEC('ALTER FUNCTION [dbo].[HasTaxYearData]
    (
      @TaxPayerID INT ,
      @TaxYearCode NVARCHAR(50) ,
      @IncludeNoOfPriorTaxYear INT
    )
RETURNS BIT
AS
    BEGIN
        IF LEN(@TaxYearCode) = 0
            RETURN 0

        DECLARE @StartDate DATE ,
            @EndDate DATE
        DECLARE @ExpectedDayCount INT ,
            @ActualDayCount INT

        SELECT  @StartDate = DATEADD(YEAR, -1 * @IncludeNoOfPriorTaxYear,
                                     StartDate) ,
                @EndDate = EndDate
        FROM    dbo.TaxYear
        WHERE   Code = @TaxYearCode

        SELECT  @ExpectedDayCount = DATEDIFF(DAY, @StartDate, @EndDate) + 1

        SELECT  @ActualDayCount = COUNT(DISTINCT ( [Day] ))
        FROM    dbo.TaxPayerTravelDataBreakdown
        INNER JOIN DayType D ON D.DayTypeID = dbo.TaxPayerTravelDataBreakdown.DayTypeID
		WHERE   TaxPayerID = @TaxPayerID
				AND [Day] BETWEEN @StartDate AND @EndDate
				AND D.IsShadowDayType = 0

        IF @ActualDayCount = @ExpectedDayCount
            RETURN 1
	
        RETURN 0
    END')

-- Schema_2.13.1_to_2.14

-- Schema_2.14_to_2.14.1

PRINT N'Dropping [dbo].[Region].[IX_Region]...';

DROP INDEX [IX_Region]
    ON [dbo].[Region];



PRINT N'Altering [dbo].[TravelDataBreakdownSource]...';

EXEC('
ALTER TABLE [dbo].[TravelDataBreakdownSource] ALTER COLUMN [SourceID] INT NOT NULL;
')



PRINT N'Creating unnamed constraint on [dbo].[TravelDataBreakdownSource]...';

EXEC('
ALTER TABLE [dbo].[TravelDataBreakdownSource]
    ADD PRIMARY KEY CLUSTERED ([SourceID] ASC);
')



PRINT N'Creating [dbo].[City].[IX_City_RegionID_Code]...';

CREATE UNIQUE NONCLUSTERED INDEX [IX_City_RegionID_Code]
    ON [dbo].[City]([RegionID] ASC, [Code] ASC);



PRINT N'Creating [dbo].[Country].[IX_Country_CountryCode]...';

CREATE UNIQUE NONCLUSTERED INDEX [IX_Country_CountryCode]
    ON [dbo].[Country]([CountryCode] ASC);



PRINT N'Creating [dbo].[Country].[IX_Country_ThreeCharCode]...';

CREATE UNIQUE NONCLUSTERED INDEX [IX_Country_ThreeCharCode]
    ON [dbo].[Country]([ThreeCharCode] ASC);



PRINT N'Creating [dbo].[Currency].[IX_Currency_CurrencyCode]...';

CREATE UNIQUE NONCLUSTERED INDEX [IX_Currency_CurrencyCode]
    ON [dbo].[Currency]([CurrencyCode] ASC);



PRINT N'Creating [dbo].[DoubleTaxTreaty].[IX_DoubleTaxTreaty_CountryId]...';

CREATE UNIQUE NONCLUSTERED INDEX [IX_DoubleTaxTreaty_CountryId]
    ON [dbo].[DoubleTaxTreaty]([CountryId] ASC);



PRINT N'Creating [dbo].[Region].[IX_Region_CountryID_RegionCode]...';

CREATE UNIQUE NONCLUSTERED INDEX [IX_Region_CountryID_RegionCode]
    ON [dbo].[Region]([CountryID] ASC, [RegionCode] ASC);



PRINT N'Creating [dbo].[SrtAssessment].[IX_SrtAssessment_TaxPayerID_TaxYearID]...';

CREATE NONCLUSTERED INDEX [IX_SrtAssessment_TaxPayerID_TaxYearID]
    ON [dbo].[SrtAssessment]([TaxPayerID] ASC, [TaxYearID] ASC);



PRINT N'Creating [dbo].[TaxPayer].[IX_TaxPayer_ClientID]...';

CREATE NONCLUSTERED INDEX [IX_TaxPayer_ClientID]
    ON [dbo].[TaxPayer]([ClientID] ASC);



PRINT N'Creating [dbo].[UserRole].[IX_UserRole_RoleID_UserID]...';

CREATE NONCLUSTERED INDEX [IX_UserRole_RoleID_UserID]
    ON [dbo].[UserRole]([RoleID] ASC, [UserID] ASC);



PRINT N'Creating [dbo].[UserRole].[IX_UserRole_UserID]...';

CREATE NONCLUSTERED INDEX [IX_UserRole_UserID]
    ON [dbo].[UserRole]([UserID] ASC);



PRINT N'Refreshing [dbo].[TaxPayerTravelDataBreakDown_Select]...';

EXECUTE sp_refreshsqlmodule N'[dbo].[TaxPayerTravelDataBreakDown_Select]';



PRINT N'Refreshing [dbo].[TaxPayerTravelDataBreakDown_SelectAllByDates]...';

EXECUTE sp_refreshsqlmodule N'[dbo].[TaxPayerTravelDataBreakDown_SelectAllByDates]';



PRINT N'Refreshing [dbo].[TaxPayerTravelDataBreakDown_SelectByDates]...';

EXECUTE sp_refreshsqlmodule N'[dbo].[TaxPayerTravelDataBreakDown_SelectByDates]';



PRINT N'Refreshing [dbo].[TravelDataBreakdownSource_SelectAll]...';

EXECUTE sp_refreshsqlmodule N'[dbo].[TravelDataBreakdownSource_SelectAll]';

-- Schema_2.14_to_2.14.1


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
