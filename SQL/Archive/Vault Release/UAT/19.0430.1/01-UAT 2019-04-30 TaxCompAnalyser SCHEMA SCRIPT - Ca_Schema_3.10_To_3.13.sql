
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
DECLARE @FromVersion varchar(50) = '3.10'
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

-- Ca_Schema_3.10_To_3.11

PRINT N'Altering [dbo].[Users]...';

ALTER TABLE [dbo].[Users]
    ADD [UsFtcReviewer] BIT NULL;

-- Ca_Schema_3.10_To_3.11

-- Ca_Schema_3.11_To_3.11.1

PRINT N'Creating [dbo].[RevisionAction]...';

CREATE TABLE [dbo].[RevisionAction]
(
	[Id] INT NOT NULL PRIMARY KEY, 
    [Name] NVARCHAR(50) NOT NULL, 
    [Description] NVARCHAR(50) NOT NULL
);



PRINT N'Creating [dbo].[UsFtcProcessingRevision]...';

CREATE TABLE [dbo].[UsFtcProcessingRevision]
(
	[Id] INT NOT NULL PRIMARY KEY IDENTITY(1, 1), 
    [AssigneeGTSId] INT NOT NULL, 
    [CalendarYear] INT NOT NULL, 
	[RevisionActionId] INT NOT NULL, 
    [UserId] INT NOT NULL, 
    [Date] DATETIME NOT NULL, 
    [UsFtcProcessingId] INT NOT NULL, 
	CONSTRAINT [FK_UsFtcProcessingRevision_Assignee] FOREIGN KEY (AssigneeGTSId) REFERENCES [Assignee](GTSId),
	CONSTRAINT [FK_UsFtcProcessingRevision_RevisionAction] FOREIGN KEY (RevisionActionId) REFERENCES [RevisionAction](Id),
	CONSTRAINT [FK_UsFtcProcessingRevision_User] FOREIGN KEY (UserId) REFERENCES [Users](Id),
	CONSTRAINT [FK_UsFtcProcessingRevision_UsFtcProcessing] FOREIGN KEY (UsFtcProcessingId) REFERENCES [UsFtcProcessing](Id),
);


PRINT N'Creating [dbo].[UsFtcProcessingRevision].[IX_UsFtcProcessingRevision_Assignee_CalendarYear_Date]...';

CREATE NONCLUSTERED INDEX [IX_UsFtcProcessingRevision_Assignee_CalendarYear_Date]
    ON [dbo].[UsFtcProcessingRevision]([AssigneeGTSId] ASC, [CalendarYear] ASC, [Date] DESC);

-- Ca_Schema_3.11_To_3.11.1

-- Ca_Schema_3.11.1_To_3.11.2

PRINT N'Creating [dbo].[DDRAmountOrigin]...';

CREATE TABLE [dbo].[DDRAmountOrigin] (
    [Id]     INT            NOT NULL,
    [Name] NVARCHAR (100) NOT NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC)
);

PRINT N'Altering [dbo].[Population]...';

ALTER TABLE [dbo].[Population]
    ADD [DDRAmountOriginId] INT NULL;

PRINT N'Creating [dbo].[FK_Population_DDRAmountOrigin]...';

ALTER TABLE [dbo].[Population]
    ADD CONSTRAINT [FK_Population_DDRAmountOrigin] FOREIGN KEY ([DDRAmountOriginId]) REFERENCES [dbo].[DDRAmountOrigin] ([Id]);


PRINT N'Altering [dbo].[DetachedDutyRelief]...';

ALTER TABLE [dbo].[DetachedDutyRelief]
    ADD [ChangeOfIntentionDate] DATE NULL;

-- Ca_Schema_3.11.1_To_3.11.2

--Ca_Schema_3.11.3_To_3.12

PRINT N'Creating [dbo].[DocumentLink]...';

CREATE TABLE [dbo].[DocumentLink]
(
	[Id] INT NOT NULL PRIMARY KEY IDENTITY(1, 1),
	[AssigneeGTSId] INT NOT NULL,
	[TaxYearId] INT NOT NULL, 
    [Description] NVARCHAR(150) NOT NULL, 
    [Url] NVARCHAR(2083) NOT NULL, 
    [CreatedByUserId] INT NOT NULL, 
    [CreatedDate] DATETIME NOT NULL,
	CONSTRAINT FK_DocumentLink_Assignee FOREIGN KEY ([AssigneeGTSId]) REFERENCES Assignee(GTSId),
	CONSTRAINT FK_DocumentLink_TaxYear FOREIGN KEY ([TaxYearId]) REFERENCES TaxYear(Id),
	CONSTRAINT FK_DocumentLink_Users FOREIGN KEY ([CreatedByUserId]) REFERENCES Users(Id),
)


PRINT N'Creating [dbo].[IX_DocumentLink_Assignee_TaxYear]...';

CREATE NONCLUSTERED INDEX [IX_DocumentLink_Assignee_TaxYear_CreatedDate] ON [dbo].[DocumentLink]
(
	[AssigneeGTSId] ASC,
	[TaxYearId] ASC,
	[CreatedDate] DESC
)

--Ca_Schema_3.11.3_To_3.12

--Ca_Schema_3.12_To_3.12.1

PRINT N'Creating [dbo].[DDRReductionType]...';

CREATE TABLE [dbo].[DDRReductionType] (
    [Id]   INT           NOT NULL,
    [Name] NVARCHAR (50) NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC)
);



PRINT N'Altering [dbo].[Treatments]...';

ALTER TABLE [dbo].[Treatments]
    ADD [DDRReductionTypeId] INT NULL,
		CONSTRAINT [FK_Treatments_DDRReductionType] FOREIGN KEY ([DDRReductionTypeId]) REFERENCES [dbo].[DDRReductionType] ([Id]);



PRINT N'Refreshing [dbo].[AssigneeCompensationInfo]...';

EXECUTE sp_refreshsqlmodule N'[dbo].[AssigneeCompensationInfo]';



PRINT N'Altering [dbo].[CompensationFullInfo]...';

EXEC('
ALTER  VIEW [dbo].[CompensationFullInfo]
AS
SELECT
	C.Id AS CompensationId 
	, PA.AssigneeGTSId
	, PA.TaxYearId
	, PA.PopulationId
	, C.PopulationAssigneeId
	, PC.CompensationName
	, C.PopulationCompensationNameId
	, C.Amount
	, C.CurrencyId
	, CY.Code AS CurrencyCode 
	, C.PaymentDate
	, C.SourceId
	, CS.Name AS SourceName
	, C.Deleted
	, PC.PaymentTypeId
	, PT.Name PaymentTypeName
	, PC.Ignore
	, CPS.ParentCompensationName
	, CPS.DescriptionOnTaxReturn
	, CPS.ParentPopulationCompensationId
	, CPS.CompensationTypeId, CPS.CompensationTypeName, CPS.Taxable, CPS.Complete, CPS.SourcingPeriodId, CPS.SourcingPeriodName, CPS.EqualisationSourcingTypeRequired, CPS.EqualisationSourcingTypeId, CPS.EqualisationSourcingTypeName
	, CPS.TreatmentsId
	, CPS.StandardTreatmentId
	, CPS.ReportedOnP11D, CPS.P11DReportingBoxId, CPS.QualifyingRelocation, CPS.DDRAvailable, CPS.HomeLeave, CPS.FundedByEmployer, CPS.InternationalMedical, CPS.PAYEPaid, CPS.PensionContributionId, CPS.ReportedOnP60Id, CPS.MultiplyByMinus1, CPS.DDRReductionTypeId
	, CPS.FxRateManagementId, CPS.FxRateManagementName
	, CPS.ResidentPeriodOSWD
	, CNL.CompensationMappingId
	, CNL.Linked
	, CPS.SourcingId
	, CPS.SourcingStartDate
	, CPS.SourcingEndDate
	, C.SpecificSourcingId
	, SS.StartDate AS SpecificSourcingStartDate
	, SS.EndDate AS SpecificSourcingEndDate
	, ACNO.Id AS AssigneeCompNameOverrideId
	, ACNO.SourcingPeriodId AS AssigneeSourcingPeriodId
	, ASP.Name AS AssigneeSourcingPeriodName
	, ASP.EqualisationSourcingTypeRequired AS AssigneeEqualisationSourcingTypeRequired
	, ACNO.EqualisationSourcingTypeId AS AssigneeEqualisedSourcingTypeId
	, AEST.Name AS AssigneeEqualisationSourcingTypeName
	  FROM [dbo].[Compensation]  C 
	  INNER JOIN [dbo].[PopulationCompensationName] PC ON PC.Id = C.PopulationCompensationNameId
	  INNER JOIN [dbo].[PopulationAssignee] PA ON PA.Id = C.PopulationAssigneeId
	  INNER JOIN [dbo].[Currency] CY ON CY.Id = C.CurrencyId
	  INNER JOIN [dbo].[PaymentType] PT ON PC.PaymentTypeId = PT.Id
	  INNER JOIN [dbo].[CompensationSource] CS ON CS.Id = C.SourceId
	  LEFT JOIN [dbo].[SpecificSourcing] SS ON C.SpecificSourcingId = SS.Id
	  LEFT JOIN [dbo].[CompensationNameLink] CNL ON PC.Id = CNL.PopulationCompensationNameId
	  LEFT JOIN
		(  
			SELECT PN.Id AS ParentPopulationCompensationId, CN2.PopulationCompensationNameId
			, PN.CompensationName ParentCompensationName
			, CM.DescriptionOnTaxReturn
			, CM.Complete
			, CM.Taxable
			, CM.CompensationTypeId
			, CM.TreatmentsId
			, CM.StandardTreatmentId
			, CM.SourcingId
			, S.StartDate AS SourcingStartDate
			, S.EndDate AS SourcingEndDate
			, S.SourcingPeriodId
			, SP.Name SourcingPeriodName
			, SP.EqualisationSourcingTypeRequired
			, S.EqualisationSourcingTypeId
			, EST.Name AS EqualisationSourcingTypeName
			, CT.Name CompensationTypeName
			, CM.FxRateManagementId
			, FRM.Name AS FxRateManagementName
			, T.ReportedOnP11D
			, T.P11DReportingBoxId
			, T.QualifyingRelocation
			, T.DDRAvailable
			, T.HomeLeave
			, T.FundedByEmployer
			, T.InternationalMedical
			, T.PAYEPaid
			, T.PensionContributionId
			, T.ReportedOnP60Id
			, T.DDRReductionTypeId
			, CM.ResidentPeriodOSWD
			, CM.MultiplyByMinus1
			FROM [dbo].[PopulationCompensationName] PN
			INNER JOIN [dbo].[CompensationNameLink] CN ON PN.Id = CN.PopulationCompensationNameId 
			INNER JOIN [dbo].[CompensationNameLink] CN2 ON CN.CompensationMappingId = CN2.CompensationMappingId
			INNER JOIN [dbo].[CompensationMapping] CM ON CM.Id = CN.CompensationMappingId
			LEFT JOIN [dbo].[CompensationType] CT ON CM.CompensationTypeId = CT.Id
			LEFT JOIN [dbo].[Sourcing] S ON CM.SourcingId = S.Id 
			LEFT JOIN [dbo].[SourcingPeriod] SP ON S.SourcingPeriodId = SP.Id
			LEFT JOIN [dbo].[Treatments] T ON CM.TreatmentsId = T.Id
			LEFT JOIN [dbo].[FxRateManagement] FRM ON CM.FxRateManagementId = FRM.Id
			LEFT JOIN [dbo].[EqualisationSourcingType] EST ON S.EqualisationSourcingTypeId = EST.Id
			WHERE 
			CN.Linked = 0
		) CPS ON PC.Id = CPS.PopulationCompensationNameId 
		LEFT JOIN [dbo].[AssigneeCompNameOverride] ACNO ON PA.AssigneeGTSId = ACNO.AssigneeGTSId AND CPS.ParentPopulationCompensationId = ACNO.CompensationNameId
		LEFT JOIN [dbo].[SourcingPeriod] ASP ON ACNO.SourcingPeriodId = ASP.Id
		LEFT JOIN [dbo].[EqualisationSourcingType] AEST ON ACNO.EqualisationSourcingTypeId = AEST.Id
')


PRINT N'Refreshing [dbo].[CompensationNameFullInfo]...';

EXEC('
ALTER VIEW [dbo].[CompensationNameFullInfo]
	AS SELECT
	PC.Id AS CompensationNameId  
	, PC.CompensationName
	, PC.Ignore
	, CPS.ParentCompensationName
	, CPS.DescriptionOnTaxReturn
	, CPS.ParentCompensationNameId
	, CPS.CompensationTypeId, CPS.CompensationTypeName, CPS.Taxable, CPS.Complete, CPS.SourcingId, CPS.SourcingStartDate, CPS.SourcingEndDate, CPS.SourcingPeriodId, CPS.SourcingPeriodName
	, CPS.TreatmentsId
	, CPS.StandardTreatmentId
	, CPS.StandardTreatmentName
	, CPS.ReportedOnP11D, CPS.P11DReportingBoxId, CPS.QualifyingRelocation, CPS.DDRAvailable, CPS.HomeLeave, CPS.FundedByEmployer, CPS.InternationalMedical, CPS.PAYEPaid, CPS.PensionContributionId, CPS.ReportedOnP60Id, CPS.MultiplyByMinus1, CPS.DDRReductionTypeId
	, CPS.PensionContributionName, CPS.P11DReportingBoxName, CPS.P11DReportingBoxDescription, CPS.ReportedOnP60Name, CPS.DDRReductionTypeName 
	, CPS.StayAtHome, CPS.MadeGood, CPS.ResidentPeriodOSWD
	, CPS.FxRateManagementId, CPS.FxRateManagementName
	, CPS.EqualisationSourcingTypeId, CPS.EqualisationSourcingTypeName
	, PC.PaymentTypeId
	, PT.Name PaymentTypeName
	, CNL.CompensationMappingId
	, CNL.Linked
	, PC.PopulationId
	, PC.TaxYearId
	, PC.SourceId
	, CS.Name AS [Source]
	  FROM [dbo].[PopulationCompensationName] PC
	  INNER JOIN [dbo].[PaymentType] PT ON PC.PaymentTypeId = PT.Id
	  LEFT JOIN [dbo].[CompensationNameLink] CNL ON PC.Id = CNL.PopulationCompensationNameId
	  LEFT JOIN [dbo].[CompensationSource] CS ON PC.SourceId = CS.Id
	  LEFT JOIN
		(  
			SELECT PN.Id AS ParentCompensationNameId, CN2.PopulationCompensationNameId
			, PN.CompensationName ParentCompensationName
			, CM.DescriptionOnTaxReturn
			, CM.Complete
			, CM.Taxable
			, CM.CompensationTypeId
			, CM.TreatmentsId
			, CM.StandardTreatmentId
			, ST.Name AS StandardTreatmentName
			, CM.SourcingId
			, S.StartDate AS SourcingStartDate
			, S.EndDate AS SourcingEndDate
			, S.SourcingPeriodId
			, SP.Name SourcingPeriodName
			, S.EqualisationSourcingTypeId
			, ES.Name AS EqualisationSourcingTypeName
			, CT.Name CompensationTypeName
			, CM.FxRateManagementId
			, FRM.Name AS FxRateManagementName
			, T.ReportedOnP11D
			, T.P11DReportingBoxId
			, T.QualifyingRelocation
			, T.DDRAvailable
			, T.HomeLeave
			, T.FundedByEmployer
			, T.InternationalMedical
			, T.PAYEPaid
			, T.PensionContributionId
			, T.ReportedOnP60Id
			, T.DDRReductionTypeId
			, CM.MultiplyByMinus1
			, PCO.Name AS PensionContributionName
			, PRB.Name AS P11DReportingBoxName
			, PRB.Description AS P11DReportingBoxDescription
			, ROP.Name AS ReportedOnP60Name
			, DRT.Name AS DDRReductionTypeName
			, CM.StayAtHome
			, CM.MadeGood
			, CM.ResidentPeriodOSWD
			FROM [dbo].[PopulationCompensationName] PN
			INNER JOIN [dbo].[CompensationNameLink] CN ON PN.Id = CN.PopulationCompensationNameId 
			INNER JOIN [dbo].[CompensationNameLink] CN2 ON CN.CompensationMappingId = CN2.CompensationMappingId
			INNER JOIN [dbo].[CompensationMapping] CM ON CM.Id = CN.CompensationMappingId
			LEFT JOIN [dbo].[CompensationType] CT ON CM.CompensationTypeId = CT.Id
			LEFT JOIN [dbo].[Sourcing] S ON CM.SourcingId = S.Id 
			LEFT JOIN [dbo].[SourcingPeriod] SP ON S.SourcingPeriodId = SP.Id
			LEFT JOIN [dbo].[EqualisationSourcingType] ES ON S.EqualisationSourcingTypeId = ES.Id
			LEFT JOIN [dbo].[Treatments] T ON CM.TreatmentsId = T.Id
			LEFT JOIN [dbo].[FxRateManagement] FRM ON CM.FxRateManagementId = FRM.Id
			LEFT JOIN [dbo].[StandardTreatment] ST ON CM.StandardTreatmentId = ST.Id
			LEFT JOIN [dbo].[PensionContribution] PCO ON T.PensionContributionId = PCO.Id
			LEFT JOIN [dbo].[P11DReportingBox] PRB ON T.P11DReportingBoxId = PRB.Id
			LEFT JOIN [dbo].[ReportedOnP60] ROP ON T.ReportedOnP60Id = ROP.Id
			LEFT JOIN [dbo].[DDRReductionType] DRT ON T.DDRReductionTypeId = DRT.Id
			WHERE 
			CN.Linked = 0
		) CPS ON PC.Id = CPS.PopulationCompensationNameId 
')

--Ca_Schema_3.12_To_3.12.1

--Ca_Schema_3.12.1_To_3.12.2

PRINT N'Altering [dbo].[OrganizerMissingInfo]...';

ALTER TABLE [dbo].[OrganizerMissingInfo]
    ADD [ManualCheck] BIT NULL;

--Ca_Schema_3.12.1_To_3.12.2

--Ca_Schema_3.12.2_To_3.12.3

PRINT N'Creating [dbo].[DdrProcessing]...';

CREATE TABLE [dbo].[DdrProcessing]
(
	[Id] INT NOT NULL PRIMARY KEY IDENTITY(1, 1),
	[AssigneeGTSId] INT NOT NULL, 
    [TaxYearId] INT NOT NULL, 
    [UserId] INT NOT NULL, 
    [Date] DATETIME NOT NULL, 
    [VersionNo] INT NOT NULL, 
    [ProcessingStateId] INT NOT NULL, 
    [CascadeDeleteId] UNIQUEIDENTIFIER NULL,
	[AssigneeQualifiesForDdr] BIT NOT NULL,
	[TotalDdrDays] INT NOT NULL,
	[TotalEligibleDdrDays] INT NOT NULL,
	CONSTRAINT [FK_DdrProcessing_Assignee] FOREIGN KEY (AssigneeGTSId) REFERENCES [Assignee](GTSId),
	CONSTRAINT [FK_DdrProcessing_User] FOREIGN KEY (UserId) REFERENCES [Users](Id),
	CONSTRAINT [FK_DdrProcessing_ProcessingState] FOREIGN KEY (ProcessingStateId) REFERENCES [ProcessingState](Id),
	CONSTRAINT [FK_DdrProcessing_TaxYear] FOREIGN KEY (TaxYearId) REFERENCES [TaxYear](Id)	
)

PRINT N'Creating [dbo].[DdrProcessing].[IX_DdrProcessing_Assignee_TaxYear_Version]...';

CREATE NONCLUSTERED INDEX [IX_DdrProcessing_Assignee_TaxYear_Version]
    ON [dbo].[DdrProcessing]([AssigneeGTSId] ASC, [TaxYearId] ASC, [VersionNo] DESC);


PRINT N'Creating [dbo].[DdrProcessing].[IX_DdrProcessing_CascadeDeleteId]...';

CREATE NONCLUSTERED INDEX [IX_DdrProcessing_CascadeDeleteId]
    ON [dbo].[DdrProcessing]([CascadeDeleteId] ASC)
	WHERE CascadeDeleteId IS NOT NULL;


PRINT N'Creating [dbo].[DdrProcessedPeriod]...';

CREATE TABLE [dbo].[DdrProcessedPeriod]
(
	[Id] INT NOT NULL PRIMARY KEY IDENTITY(1, 1),
	[DdrProcessingId] INT NOT NULL,
	[StartDate] DATE NOT NULL,
	[EndDate] DATE NOT NULL,
	[DateOfIntentionChange] DATE NULL,
	[TaxYearStartDate] DATE NOT NULL,
	[TaxYearEndDate] DATE NOT NULL,
	[TaxYearDateOfIntentionChange] DATE NULL,
	[TotalEligibleDaysInTaxYear] INT NOT NULL,
	[TotalDaysInTaxYear] INT NOT NULL,
	CONSTRAINT [FK_DdrProcessedPeriod_DdrProcessing] FOREIGN KEY (DdrProcessingId) REFERENCES [DdrProcessing](Id),
)

PRINT N'Creating [dbo].[DdrProcessedPeriod].[IX_DdrProcessedPeriod_DdrProcessing]...';

CREATE NONCLUSTERED INDEX [IX_DdrProcessedPeriod_DdrProcessing]
    ON [dbo].[DdrProcessedPeriod]([DdrProcessingId] ASC);


PRINT N'Creating [dbo].[FamilyAccompaniment]...';

CREATE TABLE [dbo].[FamilyAccompaniment]
(
	[Id] INT NOT NULL PRIMARY KEY,
	[Name] NVARCHAR(50),
);



PRINT N'Creating [dbo].[DdrBasicInput]...';

CREATE TABLE [dbo].[DdrBasicInput]
(
	[Id] INT NOT NULL PRIMARY KEY IDENTITY(1, 1),
	[DdrProcessingId] INT NOT NULL,
	[FamilyAccompanimentId] INT NOT NULL,
	[NoOfChildren] INT NULL,
	CONSTRAINT [FK_DdrBasicInput_DdrProcessing] FOREIGN KEY (DdrProcessingId) REFERENCES [DdrProcessing](Id),
	CONSTRAINT [FK_DdrBasicInput_FamilyAccompaniment] FOREIGN KEY (FamilyAccompanimentId) REFERENCES [FamilyAccompaniment](Id),
)


PRINT N'Creating [dbo].[DdrBasicInput].[IX_DdrBasicInput_DdrProcessing]...';

CREATE UNIQUE NONCLUSTERED INDEX [IX_DdrBasicInput_DdrProcessing]
    ON [dbo].[DdrBasicInput]([DdrProcessingId] ASC);


PRINT N'Creating [dbo].[DdrPopulationInput]...';

CREATE TABLE [dbo].[DdrPopulationInput]
(
	[Id] INT NOT NULL  PRIMARY KEY IDENTITY(1, 1), 
    [DdrProcessingId] INT NOT NULL, 
    [PopulationId] INT NOT NULL, 
    [DdrAmountOriginId] INT NOT NULL,
	CONSTRAINT [FK_DdrPopulationInput_DdrProcessing] FOREIGN KEY (DdrProcessingId) REFERENCES [DdrProcessing](Id),
	CONSTRAINT [FK_DdrPopulationInput_Population] FOREIGN KEY (PopulationId) REFERENCES [Population](Id),
	CONSTRAINT [FK_DdrPopulationInput_DdrAmountOrigin] FOREIGN KEY (DdrAmountOriginId) REFERENCES [DDRAmountOrigin](Id),
)

PRINT N'Creating [dbo].[DdrPopulationInput].[IX_DdrPopulationInput_DdrProcessing_Population]...';

CREATE UNIQUE NONCLUSTERED INDEX [IX_DdrPopulationInput_DdrProcessing_Population]
    ON [dbo].[DdrPopulationInput]([DdrProcessingId]  ASC, PopulationId ASC);

--Ca_Schema_3.12.2_To_3.12.3

--Ca_Schema_3.12.3_To_3.12.4

PRINT N'Altering [dbo].[ProcessedCompensation]...';

ALTER TABLE [dbo].[ProcessedCompensation] 
    ADD [DDRReductionTypeId] INT NULL,
	CONSTRAINT [FK_ProcessedCompensation_DDRReductionType] FOREIGN KEY ([DDRReductionTypeId]) REFERENCES [dbo].[DDRReductionType] ([Id]);



PRINT N'Altering [dbo].[Remuneration]...';

ALTER TABLE [dbo].[Remuneration]
    ADD [DDRReductionTypeId] INT NULL,
	CONSTRAINT [FK_Remuneration_DDRReductionType] FOREIGN KEY ([DDRReductionTypeId]) REFERENCES [dbo].[DDRReductionType] ([Id]);


PRINT N'Creating [dbo].[DdrEmployerExpense]...';

CREATE TABLE [dbo].[DdrEmployerExpense]
(
	[Id] INT NOT NULL PRIMARY KEY IDENTITY(1, 1),
	[DdrProcessingId] INT NOT NULL,
	[Description] VARCHAR(200) NOT NULL,
	[EqualisedAmount] DECIMAL(12, 2) NOT NULL,
	[NotEqualisedAmount] DECIMAL(12, 2) NOT NULL,
	[TotalAmount] DECIMAL(12, 2) NOT NULL, 
    [Equalised] BIT NULL,
	[ReductionPercentage] DECIMAL(3) NOT NULL, 
	[DdrPopulationInputId] INT NOT NULL,
    CONSTRAINT [FK_DdrEmployerExpense_DdrProcessing] FOREIGN KEY (DdrProcessingId) REFERENCES [DdrProcessing](Id),
	CONSTRAINT [FK_DdrEmployerExpense_DdrPopulationInput] FOREIGN KEY (DdrPopulationInputId) REFERENCES [DdrPopulationInput](Id),
)

PRINT N'Creating [IX_DdrEmployerExpense_DdrProcessing_DdrPopulationInput_Description]...';

CREATE UNIQUE NONCLUSTERED INDEX [IX_DdrEmployerExpense_DdrProcessing_DdrPopulationInput_Description]
    ON [dbo].[DdrEmployerExpense]([DdrProcessingId] ASC, [DdrPopulationInputId] ASC, [Description] ASC);


PRINT N'Creating [IX_DdrEmployerExpense_DdrPopulationInput]...';

CREATE NONCLUSTERED INDEX [IX_DdrEmployerExpense_DdrPopulationInput]
    ON [dbo].[DdrEmployerExpense]([DdrPopulationInputId] ASC);

--Ca_Schema_3.12.3_To_3.12.4

--Ca_Schema_3.12.4_To_3.13

PRINT N'Altering [dbo].[PensionForm]...';

ALTER TABLE [dbo].[PensionForm]
    ADD [DefinedBenefitTaxableValue] DECIMAL (12, 2) NULL;
	
--Ca_Schema_3.12.4_To_3.13

--Ca_Schema_3.13.1_To_3.13.2

PRINT N'Creating [dbo].[DdrAssigneeCurrency]...';

CREATE TABLE [dbo].[DdrAssigneeCurrency]
(
	[Id] INT NOT NULL PRIMARY KEY IDENTITY(1, 1),
	[DdrProcessingId] INT NOT NULL,
	[CurrencyId] INT NOT NULL,
	[FxRate] DECIMAL(18, 6) NULL,
	CONSTRAINT [FK_DdrAssigneeCurrency_DdrProcessing] FOREIGN KEY (DdrProcessingId) REFERENCES [DdrProcessing](Id),
	CONSTRAINT [FK_DdrAssigneeCurrency_Currency] FOREIGN KEY (CurrencyId) REFERENCES [Currency](Id),
)


PRINT N'Creating [dbo].[IX_DdrAssigneeCurrency_DdrProcessing]...';

CREATE UNIQUE NONCLUSTERED INDEX [IX_DdrAssigneeCurrency_DdrProcessing]
    ON [dbo].[DdrAssigneeCurrency]([DdrProcessingId] ASC);



PRINT N'Creating [dbo].[DdrAssigneeQuestion]...';

CREATE TABLE [dbo].[DdrAssigneeQuestion]
(
	[Id] INT NOT NULL PRIMARY KEY,
	[TaxYearId] INT NOT NULL,
	[OrganizerStaticCode] INT NOT NULL,
	[Text] NVARCHAR(MAX) NOT NULL,
	[DdrAssigneeQuestionTypeId] INT NOT NULL,
	[DdrReductionTypeId] INT NULL,
	[Hidden] BIT NOT NULL,
	CONSTRAINT [FK_DdrAssigneeQuestion_TaxYear] FOREIGN KEY (TaxYearId) REFERENCES [TaxYear](Id),
	CONSTRAINT [FK_DdrAssigneeQuestion_DdrReductionType] FOREIGN KEY (DdrReductionTypeId) REFERENCES [DDRReductionType](Id),
)


PRINT N'Creating [dbo].[IX_DdrAssigneeQuestion_TaxYear_OrganizerStaticCode]...';

CREATE UNIQUE NONCLUSTERED INDEX [IX_DdrAssigneeQuestion_TaxYear_OrganizerStaticCode]
    ON [dbo].[DdrAssigneeQuestion]([TaxYearId] ASC, [OrganizerStaticCode] ASC);


PRINT N'Creating [dbo].[IX_DdrAssigneeQuestion_OrganizerStaticCode]...';

CREATE NONCLUSTERED INDEX [IX_DdrAssigneeQuestion_OrganizerStaticCode]
    ON [dbo].[DdrAssigneeQuestion]([OrganizerStaticCode] ASC);



PRINT N'Creating [dbo].[DdrAssigneeExpense]...';

CREATE TABLE [dbo].[DdrAssigneeExpense]
(
	[Id] INT NOT NULL PRIMARY KEY IDENTITY(1, 1),
	[DdrProcessingId] INT NOT NULL,
	[DdrAssigneeQuestionId] INT NOT NULL,
	[TotalAmount] DECIMAL(12, 2) NULL, 
	[ReductionPercentage] DECIMAL(3) NOT NULL, 
    CONSTRAINT [FK_DdrAssigneeExpense_DdrProcessing] FOREIGN KEY (DdrProcessingId) REFERENCES [DdrProcessing](Id),
	CONSTRAINT [FK_DdrAssigneeExpense_DdrAssigneeQuestion] FOREIGN KEY (DdrAssigneeQuestionId) REFERENCES [DdrAssigneeQuestion](Id),
)

PRINT N'Creating [dbo].[IX_DdrAssigneeExpense_DdrProcessing_DdrAssigneeQuestion]...';

CREATE UNIQUE NONCLUSTERED INDEX [IX_DdrAssigneeExpense_DdrProcessing_DdrAssigneeQuestion]
    ON [dbo].[DdrAssigneeExpense]([DdrProcessingId] ASC, [DdrAssigneeQuestionId] ASC);



PRINT N'Creating [dbo].[IX_DdrAssigneeExpense_DdrAssigneeQuestion]...';

CREATE NONCLUSTERED INDEX [IX_DdrAssigneeExpense_DdrAssigneeQuestion]
    ON [dbo].[DdrAssigneeExpense]([DdrAssigneeQuestionId] ASC);



PRINT N'Creating [dbo].[DdrAssigneeOtherInfo]...';

CREATE TABLE [dbo].[DdrAssigneeOtherInfo]
(
	[Id] INT NOT NULL PRIMARY KEY IDENTITY(1, 1),
	[DdrProcessingId] INT NOT NULL,
	[DdrAssigneeQuestionId] INT NOT NULL,
	[Data] NVARCHAR(MAX) NULL, 
    CONSTRAINT [FK_DdrAssigneeOtherInfo_DdrProcessing] FOREIGN KEY (DdrProcessingId) REFERENCES [DdrProcessing](Id),
	CONSTRAINT [FK_DdrAssigneeOtherInfo_DdrAssigneeQuestion] FOREIGN KEY (DdrAssigneeQuestionId) REFERENCES [DdrAssigneeQuestion](Id),
)


PRINT N'Creating [dbo].[IX_DdrAssigneeOtherInfo_DdrProcessing_DdrAssigneeQuestion]...';

CREATE UNIQUE NONCLUSTERED INDEX [IX_DdrAssigneeOtherInfo_DdrProcessing_DdrAssigneeQuestion]
    ON [dbo].[DdrAssigneeOtherInfo]([DdrProcessingId] ASC, [DdrAssigneeQuestionId] ASC);


PRINT N'Creating [dbo].[IX_DdrAssigneeOtherInfo_DdrAssigneeQuestion]...';

CREATE NONCLUSTERED INDEX [IX_DdrAssigneeOtherInfo_DdrAssigneeQuestion]
    ON [dbo].[DdrAssigneeOtherInfo]([DdrAssigneeQuestionId] ASC);

--Ca_Schema_3.13.1_To_3.13.2

--Ca_Schema_3.13.2_To_3.13.3

PRINT N'Creating [dbo].[DdrExpenseSummary]...';

CREATE TABLE [dbo].[DdrExpenseSummary]
(
	[Id] INT NOT NULL PRIMARY KEY IDENTITY(1, 1),
	[DdrProcessingId] INT NOT NULL,
	[TotalAssigneeCurrencyAmount] DECIMAL(12, 2) NOT NULL,
	[TotalAssigneeAmount] DECIMAL(12, 2) NOT NULL,
	[TotalAssigneeReducedAmount] DECIMAL(12, 2) NOT NULL,
	[TotalAssigneeApportionedAmount] DECIMAL(12, 2) NOT NULL,
	[TotalEmployerAmount] DECIMAL(12, 2) NOT NULL,
	[TotalEmployerReducedAmount] DECIMAL(12, 2) NOT NULL,
	[TotalDdrAmount] DECIMAL(12, 2) NOT NULL,
	CONSTRAINT [FK_DdrExpenseSummary_DdrProcessing] FOREIGN KEY (DdrProcessingId) REFERENCES [DdrProcessing](Id),
);



PRINT N'Creating [dbo].[DdrExpenseSummary].[IX_DdrExpenseSummary_DdrProcessing]...';

CREATE UNIQUE NONCLUSTERED INDEX [IX_DdrExpenseSummary_DdrProcessing]
    ON [dbo].[DdrExpenseSummary]([DdrProcessingId] ASC);


PRINT N'Creating [dbo].[DdrPopulationExpenseTotal]...';

CREATE TABLE [dbo].[DdrPopulationExpenseTotal]
(
	[Id] INT NOT NULL PRIMARY KEY IDENTITY(1, 1),
	[DdrProcessingId] INT NOT NULL,
	[DdrPopulationInputId] INT NOT NULL,
	[TotalEmployerAmount] DECIMAL(12, 2) NOT NULL,
	[TotalEmployerReducedAmount] DECIMAL(12, 2) NOT NULL,
	CONSTRAINT [FK_DdrPopulationExpenseTotal_DdrProcessing] FOREIGN KEY (DdrProcessingId) REFERENCES [DdrProcessing](Id),
	CONSTRAINT [FK_DdrPopulationExpenseTotal_DdrPopulationInput] FOREIGN KEY (DdrPopulationInputId) REFERENCES [DdrPopulationInput](Id),
);



PRINT N'Creating [dbo].[DdrPopulationExpenseTotal].[IX_DdrPopulationExpenseTotal_DdrProcessing]...';

CREATE NONCLUSTERED INDEX [IX_DdrPopulationExpenseTotal_DdrProcessing]
    ON [dbo].[DdrPopulationExpenseTotal]([DdrProcessingId] ASC);



PRINT N'Creating [dbo].[DdrPopulationExpenseTotal].[IX_DdrPopulationExpenseTotal_DdrPopulationInput]...';

CREATE UNIQUE NONCLUSTERED INDEX [IX_DdrPopulationExpenseTotal_DdrPopulationInput]
    ON [dbo].[DdrPopulationExpenseTotal]([DdrPopulationInputId] ASC);



PRINT N'Creating [dbo].[DdrProcessedAssigneeExpense]...';

CREATE TABLE [dbo].[DdrProcessedAssigneeExpense]
(
	[Id] INT NOT NULL PRIMARY KEY IDENTITY(1, 1),
	[DdrProcessingId] INT NOT NULL,
	[DdrAssigneeExpenseId] INT NOT NULL,
	[TotalAmountInGBP] DECIMAL(12, 2) NOT NULL,
	[ReducedAmount] DECIMAL(12, 2) NOT NULL,
	[TimeApportionedAmount] DECIMAL(12, 2) NOT NULL,
	CONSTRAINT [FK_DdrProcessedAssigneeExpense_DdrProcessing] FOREIGN KEY (DdrProcessingId) REFERENCES [DdrProcessing](Id),
	CONSTRAINT [FK_DdrProcessedAssigneeExpense_DdrAssigneeExpense] FOREIGN KEY (DdrAssigneeExpenseId) REFERENCES [DdrAssigneeExpense](Id),
);



PRINT N'Creating [dbo].[DdrProcessedAssigneeExpense].[IX_DdrProcessedAssigneeExpense_DdrProcessing]...';

CREATE NONCLUSTERED INDEX [IX_DdrProcessedAssigneeExpense_DdrProcessing]
    ON [dbo].[DdrProcessedAssigneeExpense]([DdrProcessingId] ASC);



PRINT N'Creating [dbo].[DdrProcessedAssigneeExpense].[IX_DdrProcessedAssigneeExpense_DdrAssigneeExpense]...';

CREATE UNIQUE NONCLUSTERED INDEX [IX_DdrProcessedAssigneeExpense_DdrAssigneeExpense]
    ON [dbo].[DdrProcessedAssigneeExpense]([DdrAssigneeExpenseId] ASC);



PRINT N'Creating [dbo].[DdrProcessedEmployerExpense]...';

CREATE TABLE [dbo].[DdrProcessedEmployerExpense]
(
	[Id] INT NOT NULL PRIMARY KEY IDENTITY(1, 1),
	[DdrProcessingId] INT NOT NULL,
	[DdrEmployerExpenseId] INT NOT NULL,
	[ReducedAmount] DECIMAL(12, 2) NOT NULL,
	CONSTRAINT [FK_DdrProcessedEmployerExpense_DdrProcessing] FOREIGN KEY (DdrProcessingId) REFERENCES [DdrProcessing](Id),
	CONSTRAINT [FK_DdrProcessedEmployerExpense_DdrEmployerExpense] FOREIGN KEY (DdrEmployerExpenseId) REFERENCES [DdrEmployerExpense](Id),
);



PRINT N'Creating [dbo].[DdrProcessedEmployerExpense].[IX_DdrProcessedEmployerExpense_DdrProcessing]...';

CREATE NONCLUSTERED INDEX [IX_DdrProcessedEmployerExpense_DdrProcessing]
    ON [dbo].[DdrProcessedEmployerExpense]([DdrProcessingId] ASC);



PRINT N'Creating [dbo].[DdrProcessedEmployerExpense].[IX_DdrProcessedEmployerExpense_DdrEmployerExpense]...';

CREATE UNIQUE NONCLUSTERED INDEX [IX_DdrProcessedEmployerExpense_DdrEmployerExpense]
    ON [dbo].[DdrProcessedEmployerExpense]([DdrEmployerExpenseId] ASC);

--Ca_Schema_3.13.2_To_3.13.3

--Ca_Schema_3.13.3_To_3.13.4

PRINT N'Altering [dbo].[FamilyAccompaniment]...';

ALTER TABLE [dbo].[FamilyAccompaniment]
	ADD ChildrenRequired BIT NULL;

--Ca_Schema_3.13.3_To_3.13.4

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