
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
DECLARE @ToVersion varchar(50) = '3.13'
DECLARE @CurrentVersion varchar(50) = (SELECT [Version] FROM [dbo].[Version] WHERE [Key] = @VersionKey)

IF (@CurrentVersion IS NOT NULL AND @CurrentVersion NOT IN ('3.10') AND @CurrentVersion <> @ToVersion)
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

--Ca.DataBase_Data_3.10_To_3.11

PRINT N'Updating [dbo].[Users]...'

UPDATE [dbo].[Users] 
SET UsFtcReviewer = 0 
WHERE Id IN (SELECT UserId FROM [dbo].[UserRoles] WHERE RoleID = 3)

PRINT N'Updating [dbo].[Functionality]...'

MERGE INTO [dbo].[Functionality] AS Target
USING (VALUES

(1, 'ViewProcessingDayCategorisation'),
(2, 'ViewProcessingProcessedSourcing'),
(3, 'ViewProcessingRelocationAssignment'),
(4, 'ViewProcessingUkEmployment'),
(5, 'ViewProcessingProcessedAssignment'),
(6, 'ImportAssignee'),
(7, 'AssignmentImport'),
(8, 'OrganizerBulkImport'),
(9, 'ScheduleOfRemunerationImport'),
(10, 'CompMappingMultiplyByMinus1'),
(11, 'RestrictedClientAccessAdmin'),
(12, 'UsFtcReview')

) AS Source (Id, Name)
ON Target.Id = Source.Id

WHEN MATCHED THEN
UPDATE SET 
	Name = Source.Name

-- Insert new rows
WHEN NOT MATCHED BY TARGET THEN
INSERT (Id, Name)
VALUES (Id, Name);

PRINT N'Updating [dbo].[RoleFunctionality]...'

MERGE INTO [dbo].[RoleFunctionality] AS Target
USING (VALUES

(1, 1), 
(1, 2), 
(1, 3), 
(1, 4), 
(1, 5),
(1, 6),
(1, 7),
(1, 8),
(1, 9),
(1, 10),
(2, 10),
(6, 1), 
(6, 2), 
(6, 3), 
(6, 4), 
(6, 5),
(6, 6),
(6, 7),
(6, 8),
(6, 9),
(6, 10),
(6, 11),
(3, 12)

) AS Source (RoleId, FunctionalityId)
ON Target.RoleId = Source.RoleId AND Target.FunctionalityId = Source.FunctionalityId

-- Insert new rows
WHEN NOT MATCHED BY TARGET THEN
INSERT (RoleId, FunctionalityId)
VALUES (RoleId, FunctionalityId);

--Ca.DataBase_Data_3.10_To_3.11

--Ca.DataBase_Data_3.11_To_3.11.1

PRINT N'Updating [dbo].[RevisionAction]...';

MERGE INTO [dbo].[RevisionAction] AS Target
USING (VALUES

(1, N'Approve', N'Approved'),
(2, N'Unlock', N'Unlocked')

) AS Source ([Id], [Name], [Description])
ON Target.Id = Source.Id

-- Update matched rows (except date)
WHEN MATCHED THEN
UPDATE SET 
	Name = Source.Name,
	[Description] = Source.[Description]

-- Insert new rows
WHEN NOT MATCHED BY TARGET THEN
INSERT ([Id], [Name], [Description])
VALUES ([Id], [Name], [Description])

-- Delete missing rows
WHEN NOT MATCHED BY SOURCE THEN
DELETE;

--Ca.DataBase_Data_3.11_To_3.11.1

--Ca.DataBase_Data_3.11.1_To_3.11.2

MERGE INTO [dbo].[DDRAmountOrigin] AS Target
USING (VALUES

(1, N'Employer'),
(2, N'Assignee'),
(3, N'Both')

) AS Source ([Id], [Name])
ON Target.Id = Source.Id

-- Update matched rows (except date)
WHEN MATCHED THEN
UPDATE SET 
	Name = Source.Name

-- Insert new rows
WHEN NOT MATCHED BY TARGET THEN
INSERT ([Id], [Name])
VALUES ([Id], [Name]);

--Add values to existing populations
UPDATE [dbo].[Population]
SET DDRAmountOriginId = 1

--Ca.DataBase_Data_3.11.1_To_3.11.2

--Ca.DataBase_Data_3.11.2_To_3.11.3

PRINT N'Inserting into [dbo].[DetachedDutyRelief]...';


INSERT INTO [dbo].[DetachedDutyRelief] (AssigneeGTSId, StartDate, EndDate)
(SELECT A.AssigneeGTSId, A.StartDate, A.EndDate FROM [dbo].[Assignment] A
WHERE A.Active = 1 AND A.HostCountryId = 227 AND A.EndDate IS NOT NULL AND A.EndDate <= DATEADD(year, 2, A.StartDate)
AND NOT EXISTS (SELECT 1 FROM [dbo].[DetachedDutyRelief] D 
	WHERE D.AssigneeGTSId = A.AssigneeGTSId)
)

--Ca.DataBase_Data_3.11.2_To_3.11.3

--Ca.DataBase_Data_3.11.3_To_3.12

PRINT N'Inserting into [dbo].[DDRReductionType]...';

MERGE INTO [dbo].[DDRReductionType] AS Target
USING (
VALUES 
(1, 'Standard Reduction'),
(2, 'Council Tax Reduction'),
(3, 'No Reduction')

) AS Source ([Id],[Name])
ON Target.Id = Source.Id

WHEN MATCHED THEN
UPDATE SET 
	Name = Source.Name

-- Insert new rows
WHEN NOT MATCHED BY TARGET THEN
INSERT ([Id],[Name])
VALUES ([Id],[Name]);


PRINT N'Updating [dbo].[Treatments]...';

UPDATE [dbo].[Treatments] SET DDRReductionTypeId = 1 WHERE DDRAvailable = 1 AND DDRReductionTypeId IS NULL;

--Ca.DataBase_Data_3.11.3_To_3.12

--Ca.DataBase_Data_3.12_To_3.12.1

PRINT N'Updating [dbo].[OrganizerMissingInfoSection]...';

MERGE INTO [dbo].[OrganizerMissingInfoSection] AS Target
USING (VALUES

(1, N'UK Bank Interest'),
(2, N'UK Dividend'),
(3, N'UK Rental Income'),
(4, N'Gift Aid'),
(5, N'2nd Employment Income'),
(6, N'Self Employment'),
(7, N'Capital Gains-Assets'),
(8, N'Capital Gains-Real Estate'),
(9, N'Non Company Pension')

) AS Source ([Id], [Name])
ON Target.Id = Source.Id

WHEN MATCHED THEN
UPDATE SET 
	Name = Source.Name
-- Insert new rows
WHEN NOT MATCHED BY TARGET THEN
INSERT ([Id], [Name])
VALUES ([Id], [Name]);

--Ca.DataBase_Data_3.12_To_3.12.1

--Ca.DataBase_Data_3.12.1_To_3.12.2

PRINT N'Updating [dbo].[FamilyAccompaniment]...';

MERGE INTO [dbo].[FamilyAccompaniment] AS Target
USING (VALUES

(1, N'Unaccompanied'),
(2, N'Spouse'),
(3, N'Spouse with Children'),
(4, N'Children')

) AS Source ([Id], [Name])
ON Target.Id = Source.Id

-- Update matched rows (except date)
WHEN MATCHED THEN
UPDATE SET 
	Name = Source.Name

-- Insert new rows
WHEN NOT MATCHED BY TARGET THEN
INSERT ([Id], [Name])
VALUES ([Id], [Name])

-- Delete missing rows
WHEN NOT MATCHED BY SOURCE THEN
DELETE;

--Ca.DataBase_Data_3.12.1_To_3.12.2

--Ca.DataBase_Data_3.12.2_To_3.12.3

PRINT N'Inserting lookup data in to [dbo].[OrganizerForm] ...';

SET IDENTITY_INSERT [dbo].[OrganizerForm]  ON

MERGE INTO [dbo].[OrganizerForm] AS Target
USING (VALUES

(1, 1),
(2, 2),
(3, 13),
(4, 14)

) AS Source ([Id], [TaxYearId])    
ON Target.Id = Source.Id

WHEN MATCHED THEN
UPDATE SET 
	TaxYearId = Source.TaxYearId
		 
-- Insert new rows
WHEN NOT MATCHED BY TARGET THEN
INSERT ([Id], [TaxYearId])  
VALUES ([Id], [TaxYearId])
-- Delete missing rows
WHEN NOT MATCHED BY SOURCE THEN
DELETE;
SET IDENTITY_INSERT [dbo].[OrganizerForm] OFF

PRINT N'Inserting lookup data in to [dbo].[OrganizerQuestion] ...';

SET IDENTITY_INSERT [dbo].[OrganizerQuestion]  ON
MERGE INTO [dbo].[OrganizerQuestion] AS Target
USING (VALUES

(2455,4,5,NULL,10001,1,0,1,1, N'Profile',0,54),
(2456,4,2,NULL,10002,1,10001,2,1, N'Basic Information',0,67),
(2457,4,1,7,10004,1,10002,3,100, N'Title',0,2),
(2458,4,1,13,10006,1,10002,3,140, N'First name',0,1),
(2459,4,1,13,10007,1,10002,3,160, N'Middle name',0,1),
(2460,4,1,13,10008,1,10002,3,170, N'Last name/Surname',0,1),
(2461,4,1,12,10010,1,10002,3,10, N'Are you married?',0,16),
(2462,4,1,3,10015,1,10002,3,240, N'Country of citizenship or nationality',0,9),
(2463,4,1,3,10018,1,10002,3,250, N'Country of second citizenship or nationality',0,9),
(2464,4,1,3,10029,1,20175,3,40, N'What is your host country?',0,9),
(2465,4,1,6,10032,1,20175,3,50,N'Assignment start date (e.g., 01 Jan 2018)',0,5),
(2466,4,1,6,10034,1,20175,3,60,N'Assignment end date (e.g., 31 Dec 2021)',0,5),
(2467,4,1,5,10050,1,11915,3,10, N'Select a default currency to use throughout the questionnaire',0,12),
(2468,4,2,NULL,10113,1,10263,2,15, N'Marital Information',0,61),
(2469,4,1,6,10117,1,10113,3,40,N'Indicate the date your current marital status took effect (e.g., 31 Dec 2000)',0,5),
(2470,4,2,NULL,10130,1,10263,2,450,N'Identification Number(s) (Tax, Social Security, Others)',0,62),
(2471,4,1,13,10140,1,10130,3,625,N'Please specify your UK National Insurance (NI) number, if known',0,1),
(2472,4,1,6,10148,1,10002,3,230,N'Date of birth (e.g., 31 Dec 1980)',0,5),
(2473,4,1,13,10152,1,12004,3,30, N'Business telephone number (including country code)',0,1),
(2474,4,1,8,10155,1,24542,3,10, N'Preferred e-mail address',0,21),
(2475,4,1,7,10158,1,12004,3,10,N'If we have questions, how would you like us to contact you?',0,2),
(2476,4,1,13,10161,1,12009,3,10, N'Street address',0,1),
(2477,4,1,13,10162,1,12009,3,20, N'Street address line 2',0,1),
(2478,4,1,13,10163,1,12009,3,30, N'Apartment number',0,1),
(2479,4,1,13,10164,1,12009,3,40, N'City',0,1),
(2480,4,1,4,10165,1,12009,3,50, N'State/Province/Canton',0,11),
(2481,4,1,13,10166,1,12009,3,60, N'County',0,1),
(2482,4,1,13,10167,1,12009,3,70, N'Zip/Postal code',0,1),
(2483,4,1,3,10168,1,12009,3,80, N'Country',0,9),
(2484,4,1,13,10233,1,12123,5,40, N'First name',0,1),
(2485,4,1,6,10236,1,12123,5,80,N'Date of birth (e.g., 31 Dec 2005)',0,5),
(2486,4,5,NULL,10263,1,0,1,2, N'Personal Info',0,54),
(2487,4,5,NULL,10315,1,0,1,3, N'Employment',0,54),
(2488,4,1,7,10372,1,20517,3,2315,N'Has there been a change in the expected length of assignment such as signing a contract extension, agreeing to local terms, or applying for a new work permit?',0,2),
(2489,4,2,NULL,10393,1,10315,2,20, N'Host Country Employer',0,62),
(2490,4,1,13,10394,1,10393,3,150, N'Street address',0,1),
(2491,4,1,13,10395,1,10393,3,160, N'Street address line 2',0,1),
(2492,4,1,13,10396,1,10393,3,180, N'City',0,1),
(2493,4,1,4,10397,1,10393,3,190, N'State/Province/Canton',0,11),
(2494,4,1,13,10398,1,10393,3,196, N'Zip/Postal code',0,1),
(2495,4,1,3,10399,1,10393,3,200, N'Country',0,9),
(2496,4,1,14,10414,1,91700,4,50, N'Do you own residential property in the UK?',0,13),
(2497,4,1,6,10415,1,91700,4,60, N'Please indicate the date you purchased your UK property and provide details in the Notes',0,5),
(2498,4,1,6,10420,1,91700,4,20,N'If rented by yourself or your employer, please indicate the start date of your lease',0,5),
(2499,4,1,6,10421,1,91700,4,30,N'If rented by yourself or your employer, please indicate the end date of your lease',0,5),
(2500,4,2,NULL,10451,1,10263,2,380, N'Business Visits to the UK',0,56),
(2501,4,1,14,10454,1,10451,3,40,N'Are you a director of a UK company (i.e., a member of the board of directors) and attend board meetings in the UK?',0,13),
(2502,4,1,7,10455,1,10451,3,20, N'Are these UK workdays ''incidental'' to your non-UK duties?',0,2),
(2503,4,1,13,10456,1,10451,3,30,N'If No or Some of them, please provide details of the UK duties performed (including the capacity in which you were working in the UK and who you were working for) and confirm how many of your UK workdays were spent performing non-incidental duties',0,1),
(2504,4,2,NULL,10506,1,10315,2,190, N'Host Country Housing Expenses',0,61),
(2505,4,1,5,10508,1,10506,3,30, N'Currency',0,12),
(2506,4,7,NULL,10513,1,20716,4,1, N'Details',0,51),
(2507,4,3,11,10514,1,10513,5,20, N'Ownership',0,8),
(2508,4,1,6,10515,1,10513,5,30, N'Date trip commenced',0,5),
(2509,4,1,6,10516,1,10513,5,40, N'Date trip ended',0,5),
(2510,4,1,13,10517,1,10513,5,70, N'Who traveled?',0,1),
(2511,4,1,3,10519,1,10513,5,60, N'Country visited',0,9),
(2512,4,5,NULL,10535,1,0,1,4, N'Property/Investments',0,54),
(2513,4,2,NULL,10569,1,10315,2,140, N'Board of Directors/Supervisory Board',0,65),
(2514,4,2,NULL,10581,1,10315,2,50, N'Employment Income',0,65),
(2515,4,6,NULL,10582,1,10581,3,210, N'Employment Income - Details',0,63),
(2516,4,1,13,10583,1,20399,5,20, N'Employer name',0,1),
(2517,4,1,2,10592,1,20399,5,400, N'Total income for the year per P60/P45',0,6),
(2518,4,1,6,10593,1,20399,5,410, N'Date of first payment',0,5),
(2519,4,1,9,10594,1,24371,3,10, N'Did you have a separate contract of employment for duties performed wholly outside the UK (sometimes referred to as a dual or multiple employment contract)?',0,15),
(2520,4,7,NULL,10597,1,10582,4,120, N'Compensation/Remuneration - Details',0,66),
(2521,4,1,7,10598,1,10597,5,10, N'Category',0,2),
(2522,4,1,3,10602,1,10597,5,30, N'Country in which income was earned',0,9),
(2523,4,1,5,10605,1,10597,5,80, N'Currency',0,12),
(2524,4,1,2,10606,1,10597,5,90, N'Amount',0,6),
(2525,4,7,NULL,10616,1,20902,4,1, N'Details',0,51),
(2526,4,1,2,10619,1,10616,5,30, N'Total amount kept offshore',0,6),
(2527,4,7,NULL,10621,1,92359,4,10, N'General Information',0,51),
(2528,4,1,13,10652,1,20179,5,300,N'Other items (e.g., subscriptions and professional fees - box 15)',0,1),
(2529,4,1,5,10653,1,20179,5,20, N'Currency',0,12),
(2530,4,1,2,10654,1,20179,5,370, N'Description of other expenses (box 16)',0,6),
(2531,4,2,NULL,10680,1,10315,2,80, N'Stock Options',0,65),
(2532,4,7,NULL,10725,1,20674,4,1, N'Details',0,51),
(2533,4,3,11,10726,1,10725,5,10, N'Ownership',0,8),
(2534,4,1,5,10727,1,10725,5,120, N'Currency',0,12),
(2535,4,1,7,10728,1,10725,5,20, N'Payment type',0,2),
(2536,4,1,13,10729,1,10725,5,30,N'If Other, please specify',0,1),
(2537,4,1,2,10734,1,10725,5,130, N'Amount',0,6),
(2538,4,2,NULL,10735,1,11388,2,60, N'Pension and Retirement Distributions',0,65),
(2539,4,6,NULL,10736,1,10735,3,60, N'Pension and Retirement Distributions',0,58),
(2540,4,3,11,10737,1,20185,5,30, N'Ownership',0,8),
(2541,4,1,5,10740,1,20185,5,390, N'Currency',0,12),
(2542,4,1,13,10741,1,20185,5,140, N'Payor',0,1),
(2543,4,1,3,10742,1,20185,5,190, N'Location of plan/account',0,9),
(2544,4,1,6,10743,1,20185,5,250, N'Date of distribution',0,5),
(2545,4,2,NULL,10751,1,10315,2,500, N'Company Pension Contributions (Contributions Made by Taxpayer)',0,65),
(2546,4,3,11,10752,1,20187,5,20, N'Ownership',0,8),
(2547,4,1,3,10754,1,20187,5,70, N'Location of plan',0,9),
(2548,4,1,13,10755,1,20187,5,60, N'Name of scheme/plan',0,1),
(2549,4,1,5,10760,1,20187,5,80, N'Currency',0,12),
(2550,4,1,2,10761,1,20187,5,90, N'Amount of contributions made by you',0,6),
(2551,4,1,13,10774,1,20185,5,180, N'Description of plan/account',0,1),
(2552,4,1,2,10779,1,20185,5,550, N'Amount remitted (if non-UK)',0,6),
(2553,4,1,6,10780,1,20185,5,590, N'Date remitted (if non-UK)',0,5),
(2554,4,6,NULL,10781,1,20189,3,160, N'Non-Company Pension Plan',0,58),
(2555,4,3,11,10782,1,20190,5,20, N'Policy holder',0,8),
(2556,4,1,13,10784,1,20190,5,30, N'Name of provider',0,1),
(2557,4,1,7,10786,1,20190,5,60, N'Type of UK pension plan',0,2),
(2558,4,1,5,10788,1,20190,5,170, N'Currency',0,12),
(2559,4,1,2,10792,1,20190,5,180, N'Personal contributions',0,6),
(2560,4,7,NULL,10796,1,20192,4,1, N'Details',0,51),
(2561,4,3,11,10797,1,10796,5,25, N'Ownership',0,8),
(2562,4,1,13,10798,1,10796,5,40, N'Name of payor',0,1),
(2563,4,1,2,10809,1,10796,5,340, N'Tax credit',0,6),
(2564,4,1,3,10810,1,10796,5,50, N'Location of payor',0,9),
(2565,4,1,6,10811,1,10796,5,280, N'Date paid',0,5),
(2566,4,1,5,10812,1,10796,5,290, N'Currency',0,12),
(2567,4,1,7,10817,1,10796,5,100, N'Type of shares',0,2),
(2568,4,1,2,10820,1,10796,5,490, N'Amount of tax withheld',0,6),
(2569,4,2,NULL,10829,1,10535,2,10, N'Interest',0,65),
(2570,4,3,11,10830,1,20194,5,20, N'Ownership',0,8),
(2571,4,1,13,10831,1,20194,5,40, N'Name of payor',0,1),
(2572,4,1,3,10836,1,20194,5,70, N'Location of payor',0,9),
(2573,4,1,7,10837,1,20194,5,250, N'Period earned',0,2),
(2574,4,1,5,10839,1,20194,5,290, N'Currency',0,12),
(2575,4,1,2,10844,1,20194,5,680, N'Amount of non-UK interest remitted',0,6),
(2576,4,1,6,10845,1,20194,5,710, N'Date non-UK interest remitted',0,5),
(2577,4,1,2,10847,1,20194,5,300, N'Gross interest amount',0,6),
(2578,4,1,2,10848,1,20194,5,510, N'Amount of tax withheld',0,6),
(2579,4,2,NULL,10853,1,10535,2,90, N'Sale or Disposition of Assets (Capital Gains and Losses)',0,65),
(2580,4,7,NULL,10898,1,10853,3,70, N'Sale or Disposition of Assets (Capital Gains and Losses) - Summary',0,58),
(2581,4,3,11,10899,1,20196,5,32, N'Ownership',0,8),
(2582,4,1,13,10900,1,20196,5,60, N'Description',0,1),
(2583,4,1,7,10901,1,20196,5,40, N'Asset type',0,2),
(2584,4,1,13,10902,1,20196,5,50,N'If Other, please specify',0,1),
(2585,4,1,3,10904,1,20196,5,70,N'Location of asset (if stock or securities, location of company)',0,9),
(2586,4,1,2,10909,1,20196,5,450, N'Gross sales proceeds',0,6),
(2587,4,1,2,10910,1,20196,5,480, N'Disposal costs',0,6),
(2588,4,1,13,10911,1,20196,5,470, N'Description of disposal costs',0,1),
(2589,4,1,2,10912,1,20196,5,230, N'Cost',0,6),
(2590,4,1,6,10915,1,20196,5,210, N'Date acquired',0,5),
(2591,4,1,6,10916,1,20196,5,410, N'Date sold/disposed',0,5),
(2592,4,1,2,10921,1,20196,5,530, N'Amount of tax withheld',0,6),
(2593,4,1,5,10922,1,20196,5,227, N'Currency',0,12),
(2594,4,1,2,10923,1,20196,5,630, N'Amount remitted',0,6),
(2595,4,1,6,10924,1,20196,5,640, N'Date remitted',0,5),
(2596,4,2,NULL,10928,1,10535,2,300, N'Sale or Disposition of Real Estate',0,65),
(2597,4,6,NULL,11105,1,20200,3,160, N'Property - Summary',0,63),
(2598,4,7,NULL,11106,1,11105,4,10, N'Ownership and Use',0,61),
(2599,4,1,13,11111,1,11106,5,90, N'Property address (including city and country)',0,1),
(2600,4,1,7,11114,1,11106,5,180, N'Use of property during the tax year under consideration',0,2),
(2601,4,1,5,11115,1,11106,5,110, N'Currency used for this property',0,12),
(2602,4,1,6,11116,1,11106,5,360, N'Date available for rent',0,5),
(2603,4,1,6,11122,1,11106,5,370, N'Rental period start date',0,5),
(2604,4,1,6,11123,1,11106,5,380, N'Rental period end date (leave blank if not applicable)',0,5),
(2605,4,1,7,11124,1,11106,5,480, N'Is property furnished or unfurnished?',0,2),
(2606,4,7,NULL,11146,1,11105,4,55, N'Remittance of Rental Income into the UK',0,51),
(2607,4,1,5,11147,1,11146,5,20, N'Currency',0,12),
(2608,4,1,2,11148,1,11146,5,30, N'Amount remitted',0,6),
(2609,4,1,6,11149,1,11146,5,60, N'Date remitted',0,5),
(2610,4,7,NULL,11152,1,11105,4,20, N'Rental Income',0,51),
(2611,4,1,2,11154,1,11152,5,50, N'Gross rent income',0,6),
(2612,4,1,2,11155,1,11152,5,100, N'Taxes paid (in country where property is located)',0,6),
(2613,4,7,NULL,11160,1,11105,4,30, N'Other Income',0,56),
(2614,4,1,13,11161,1,11160,5,10, N'Income description',0,1),
(2615,4,1,2,11162,1,11160,5,20, N'Income amount',0,6),
(2616,4,7,NULL,11360,1,20206,4,1, N'General Information',0,51),
(2617,4,3,11,11361,1,11360,5,10, N'Ownership',0,8),
(2618,4,1,13,11363,1,11360,5,50, N'Description',0,1),
(2619,4,1,5,11369,1,11360,5,140, N'Currency',0,12),
(2620,4,1,6,11370,1,11360,5,110, N'Date paid',0,5),
(2621,4,1,3,11371,1,11360,5,70, N'Location of payor',0,9),
(2622,4,1,13,11372,1,20797,5,20, N'Indicate the tax year of original receipt of income',0,1),
(2623,4,1,2,11375,1,11360,5,150, N'Gross amount',0,6),
(2624,4,1,2,11376,1,11360,5,160, N'Tax withheld/deducted',0,6),
(2625,4,5,NULL,11388,1,0,1,5, N'Other Income/Expenses',0,54),
(2626,4,8,NULL,11416,1,92554,5,10, N'Details',0,51),
(2627,4,6,NULL,11434,1,20211,3,360, N'Cash Contributions',0,58),
(2628,4,7,NULL,11435,1,11434,4,1, N'Cash - Details',0,51),
(2629,4,3,11,11436,1,11435,5,10, N'Ownership',0,8),
(2630,4,1,13,11437,1,11435,5,30, N'Name of organization',0,1),
(2631,4,1,3,11438,1,11435,5,60, N'Location of organization',0,9),
(2632,4,1,7,11439,1,11435,5,70,N'Indicate whether the donations were made under a deed of covenant (entered into before 06 Apr 2000), or as a formal UK Gift Aid scheme donation.',0,2),
(2633,4,1,5,11440,1,11435,5,120, N'Currency',0,12),
(2634,4,1,2,11441,1,11435,5,130, N'Amount donated',0,6),
(2635,4,7,NULL,11443,1,20518,4,1, N'Non Cash - Details',0,51),
(2636,4,3,11,11444,1,11443,5,10, N'Ownership',0,8),
(2637,4,1,13,11446,1,11443,5,20, N'Name of organization',0,1),
(2638,4,1,6,11448,1,11443,5,80, N'Date donated',0,5),
(2639,4,1,5,11451,1,11443,5,110, N'Currency',0,12),
(2640,4,1,2,11453,1,11443,5,130, N'Fair market value on date of donation',0,6),
(2641,4,6,NULL,11507,1,23114,3,50, N'Union Dues/Subscriptions to Professional Organizations',0,56),
(2642,4,3,11,11508,1,11507,4,10, N'Ownership',0,8),
(2643,4,1,13,11509,1,11507,4,20, N'Name of professional body',0,1),
(2644,4,1,5,11510,1,11507,4,80, N'Currency',0,12),
(2645,4,1,2,11512,1,11507,4,90, N'Total amount (net of refunds)',0,6),
(2646,4,6,NULL,11722,1,20208,3,80, N'Other Employment-related Expenses',0,53),
(2647,4,7,NULL,11723,1,11722,4,31, N'Miscellaneous Expenses',0,56),
(2648,4,1,7,11724,1,11723,5,10, N'Description',0,2),
(2649,4,1,14,11728,1,11723,5,80,N'Was this expense ''wholly, exclusively and necessarily'' of a business nature?',0,13),
(2650,4,1,5,11729,1,11723,5,40, N'Currency',0,12),
(2651,4,1,2,11730,1,11723,5,50, N'Amount (net of any reimbursements)',0,6),
(2652,4,7,NULL,11732,1,11722,4,4, N'Business Use of Personal Vehicle (Non-Commuting)',0,51),
(2653,4,1,2,11734,1,11732,5,40, N'Number of miles driven for business purposes',0,6),
(2654,4,5,NULL,11778,1,0,1,6, N'Miscellaneous Deductions/Credits',0,54),
(2655,4,5,NULL,11831,1,0,1,7, N'Other Tax-related Issues',0,54),
(2656,4,2,NULL,11869,1,11831,2,410, N'Special Situations',0,61),
(2657,4,2,NULL,11915,1,10001,2,5, N'Questionnaire Defaults',0,67),
(2658,4,1,14,11940,1,10621,5,30, N'Did you receive any payments in respect of termination of employment?',0,13),
(2659,4,1,12,11983,1,20175,3,1, N'Is your spouse also working? (Select No if not applicable or if not including your spouse''s personal and tax information in this questionnaire.)',0,16),
(2660,4,2,NULL,12004,1,10263,2,5, N'Contact Information - General',0,62),
(2661,4,2,NULL,12009,1,10263,2,45, N'Current Residence Address',0,62),
(2662,4,1,12,12066,1,10581,3,10, N'Has your compensation data NOT been pro-forma''d?',0,16),
(2663,4,1,9,12068,1,20200,3,40, N'Did you have rental real estate?',0,15),
(2664,4,1,9,12072,1,10853,3,10,N'Did you have income from the sale or disposition of assets (e.g., stocks, personal property, assets held for investment)?',0,15),
(2665,4,1,9,12074,1,20404,3,10, N'Are you self-employed or do you have your own business?',0,15),
(2666,4,1,9,12077,1,10569,3,10, N'Were you an officer or director of a corporate entity at any time during the year?',0,15),
(2667,4,1,9,12082,1,20222,3,10,N'Did you subscribe for shares in a Venture Capital Trust, an Enterprise Investment Scheme, Community Investment Scheme, or any other tax effective investment that you believe should be reflected on your tax return?',0,15),
(2668,4,1,9,12101,1,20208,3,10, N'Did you incur any unreimbursed employment related expenses (including business use of your personal vehicle and commuting costs)?',0,15),
(2669,4,1,9,12106,1,10735,3,5, N'Did you receive any pension or retirement distributions?',0,15),
(2670,4,1,9,12108,1,10751,3,10, N'Did you contribute to/participate in any pension or retirement plan sponsored by your employer?',0,15),
(2671,4,2,NULL,12120,1,10263,2,455, N'Tax Return Filing',0,61),
(2672,4,6,NULL,12122,1,20387,3,320, N'Dependent Children',0,63),
(2673,4,7,NULL,12123,1,12122,4,10, N'General Information',0,61),
(2674,4,1,2,12166,1,10796,5,610, N'Amount of non-UK dividends remitted',0,6),
(2675,4,1,6,12167,1,10796,5,590, N'Date non-UK dividends remitted',0,5),
(2676,4,1,2,12170,1,11360,5,190, N'Amount remitted',0,6),
(2677,4,1,6,12171,1,11360,5,220, N'Date remitted',0,5),
(2678,4,7,NULL,12188,1,11722,4,1, N'General Information',0,51),
(2679,4,1,13,12189,1,12188,5,20, N'Employer name',0,1),
(2680,4,1,5,12211,1,10616,5,20, N'Currency',0,12),
(2681,4,1,13,12245,1,11723,5,20,N'If Other, please specify (e.g., job search expenses)',0,1),
(2682,4,1,5,12261,1,10513,5,130, N'Currency',0,12),
(2683,4,1,3,12356,1,20175,3,25, N'What is your home country?',0,9),
(2684,4,1,13,12383,1,10130,3,635, N'10 digit Unique Taxpayer Reference Number (UTR) assigned by UK tax authorities',0,1),
(2685,4,1,15,20110,1,20387,3,10, N'Do you have any dependent children?',0,15),
(2686,4,1,2,20127,1,10506,3,100,N'Utilities (e.g., gas, heating, electricity)',0,6),
(2687,4,1,2,20130,1,10506,3,220, N'Insurance',0,6),
(2688,4,1,2,20132,1,10506,3,230, N'Furniture rental',0,6),
(2689,4,1,13,20133,1,10506,3,150, N'Other description',0,1),
(2690,4,1,2,20134,1,10506,3,160, N'Other amount',0,6),
(2691,4,2,NULL,20175,1,10001,2,2, N'Employment Snapshot',0,67),
(2692,4,7,NULL,20179,1,10582,4,100, N'P11D Benefits Detail',0,51),
(2693,4,7,NULL,20185,1,10736,4,1, N'Details',0,51),
(2694,4,6,NULL,20186,1,10751,3,95, N'Company Pension Contributions (Contributions Made by Taxpayer)',0,58),
(2695,4,7,NULL,20187,1,20186,4,1, N'Details',0,51),
(2696,4,2,NULL,20189,1,11778,2,300, N'Non-Company Pension Plan',0,65),
(2697,4,7,NULL,20190,1,10781,4,1, N'Details',0,51),
(2698,4,2,NULL,20191,1,10535,2,20, N'Dividends',0,65),
(2699,4,6,NULL,20192,1,20191,3,120, N'Dividends - Summary',0,58),
(2700,4,6,NULL,20193,1,10829,3,120, N'Interest - Summary',0,58),
(2701,4,7,NULL,20194,1,20193,4,1, N'Details',0,51),
(2702,4,8,NULL,20196,1,10898,4,1, N'Details',0,51),
(2703,4,2,NULL,20198,1,10535,2,500, N'Trusts/Estates',0,65),
(2704,4,2,NULL,20200,1,10535,2,200, N'Property',0,65),
(2705,4,6,NULL,20206,1,20377,3,140, N'Miscellaneous Income',0,58),
(2706,4,2,NULL,20208,1,10315,2,410, N'Other Employment-related Expenses',0,65),
(2707,4,2,NULL,20211,1,11778,2,20, N'Charitable Contributions/Donations',0,65),
(2708,4,2,NULL,20222,1,11831,2,70, N'Venture Capital Investment (Tax Efficient Investments)',0,65),
(2709,4,4,NULL,20305,1,10796,5,30, N'Payor Information',1,4),
(2710,4,4,NULL,20306,1,10796,5,240, N'Dividend Income',1,4),
(2711,4,4,NULL,20307,1,10796,5,460, N'Tax Withholding Details',1,4),
(2712,4,1,5,20308,1,10796,5,485, N'Currency',0,12),
(2713,4,1,3,20309,1,10796,5,480, N'Location of tax withheld',0,9),
(2714,4,4,NULL,20311,1,10796,5,520, N'Remittance Details',1,4),
(2715,4,4,NULL,20316,1,20194,5,480, N'Tax Withholding Details',1,4),
(2716,4,1,5,20317,1,20194,5,490, N'Currency',0,12),
(2717,4,1,3,20318,1,20194,5,485, N'Location of tax withheld',0,9),
(2718,4,2,NULL,20375,1,11388,2,50, N'Government Payments',0,65),
(2719,4,2,NULL,20377,1,11388,2,130, N'Miscellaneous Income',0,65),
(2720,4,2,NULL,20387,1,10263,2,500, N'Dependent Children',0,65),
(2721,4,2,NULL,20393,1,10315,2,330, N'Home Leave Expenses',0,65),
(2722,4,3,11,20394,1,20399,5,10, N'Ownership',0,8),
(2723,4,7,NULL,20399,1,10582,4,10, N'Required Documents',0,61),
(2724,4,2,NULL,20404,1,11388,2,10, N'Self-Employment/Business',0,65),
(2725,4,1,10,20424,1,10002,3,500, N'Notes',0,14),
(2726,4,1,10,20425,1,20175,3,600, N'Notes',0,14),
(2727,4,1,10,20427,1,10113,3,390, N'Notes',0,14),
(2728,4,1,10,20429,1,10130,3,675, N'Notes',0,14),
(2729,4,1,10,20430,1,12004,3,80, N'Notes',0,14),
(2730,4,1,10,20431,1,12009,3,200, N'Notes',0,14),
(2731,4,1,10,20440,1,20387,3,310, N'Notes',0,14),
(2732,4,1,10,20442,1,12123,5,960, N'Notes',0,14),
(2733,4,1,10,20469,1,10393,3,300, N'Notes',0,14),
(2734,4,1,10,20474,1,20393,3,20, N'Notes',0,14),
(2735,4,1,10,20475,1,10513,5,300, N'Notes',0,14),
(2736,4,1,10,20476,1,91700,4,80, N'Notes',0,14),
(2737,4,1,10,20477,1,10506,3,400, N'Notes',0,14),
(2738,4,3,11,20489,1,12188,5,10, N'Ownership',0,8),
(2739,4,4,NULL,20502,1,20185,5,240, N'Distribution Information',1,4),
(2740,4,1,7,20503,1,20185,5,290, N'Type of distribution',0,2),
(2741,4,4,NULL,20505,1,20185,5,510, N'Remittance Details (if applicable)',1,4),
(2742,4,2,NULL,20517,1,10001,2,3, N'Questions to Determine Your Tax Residency',0,67),
(2743,4,6,NULL,20518,1,20211,3,370, N'Non Cash Contributions',0,58),
(2744,4,1,10,20519,1,10581,3,200, N'Notes',0,14),
(2745,4,1,10,20520,1,20399,5,850, N'Notes',0,14),
(2746,4,1,10,20524,1,10616,5,160, N'Notes',0,14),
(2747,4,1,10,20525,1,10621,5,200, N'Notes',0,14),
(2748,4,1,10,20534,1,10680,3,100, N'Notes',0,14),
(2749,4,1,10,20537,1,20375,3,90, N'Notes',0,14),
(2750,4,1,10,20538,1,10725,5,210, N'Notes',0,14),
(2751,4,1,10,20539,1,10735,3,50, N'Notes',0,14),
(2752,4,1,10,20540,1,10751,3,90, N'Notes',0,14),
(2753,4,1,10,20541,1,20187,5,290, N'Notes',0,14),
(2754,4,1,10,20542,1,20189,3,150, N'Notes',0,14),
(2755,4,1,10,20543,1,20190,5,500, N'Notes',0,14),
(2756,4,1,10,20545,1,20191,3,100, N'Notes',0,14),
(2757,4,1,10,20546,1,10796,5,700, N'Notes',0,14),
(2758,4,1,10,20547,1,10829,3,50, N'Notes',0,14),
(2759,4,1,10,20548,1,20194,5,740, N'Notes',0,14),
(2760,4,1,10,20549,1,10853,3,55, N'Notes',0,14),
(2761,4,1,10,20555,1,20196,5,1000, N'Notes',0,14),
(2762,4,1,10,20556,1,10928,3,50, N'Notes',0,14),
(2763,4,1,10,20562,1,10569,3,80, N'Notes',0,14),
(2764,4,1,10,20564,1,20198,3,80, N'Notes',0,14),
(2765,4,1,10,20566,1,20404,3,150, N'Notes',0,14),
(2766,4,1,10,20574,1,20200,3,150, N'Notes',0,14),
(2767,4,1,10,20575,1,11106,5,1000, N'Notes',0,14),
(2768,4,1,10,20581,1,11152,5,300, N'Notes',0,14),
(2769,4,1,10,20596,1,20377,3,130, N'Notes',0,14),
(2770,4,1,10,20597,1,11360,5,260, N'Notes',0,14),
(2771,4,1,10,20601,1,20208,3,70, N'Notes',0,14),
(2772,4,1,10,20602,1,12188,5,100, N'Notes',0,14),
(2773,4,1,10,20603,1,11732,5,300, N'Notes',0,14),
(2774,4,1,10,20616,1,20211,3,350, N'Notes',0,14),
(2775,4,1,10,20617,1,11435,5,150, N'Notes',0,14),
(2776,4,1,10,20618,1,11443,5,150, N'Notes',0,14),
(2777,4,1,10,20645,1,20222,3,30, N'Notes',0,14),
(2778,4,6,NULL,20674,1,20375,3,100, N'Government Payments',0,58),
(2779,4,1,10,20676,1,11915,3,60, N'Notes',0,14),
(2780,4,6,NULL,20716,1,20393,3,30, N'Home Leave Expenses',0,58),
(2781,4,1,10,20717,1,20185,5,660, N'Notes',0,14),
(2782,4,1,2,20769,1,20194,5,350, N'Net interest amount',0,6),
(2783,4,1,9,20777,1,20377,3,80, N'Did you remit to the UK any other types of non-UK source income or gains?',0,15),
(2784,4,1,9,20778,1,20377,3,90,N'Did you remit to the UK either non-UK sourced income, or proceeds from the sale or disposal of non-UK assets, which arose in a tax year preceding 2018/2019?',0,15),
(2785,4,1,9,20779,1,20377,3,100, N'Did you receive any other types of UK source income or gains?',0,15),
(2786,4,1,9,20780,1,20211,3,280,N'Did you donate shares, securities or land/buildings to a recognized UK or EU registered charity in the tax year?',0,15),
(2787,4,1,6,20781,1,11435,5,100, N'Date donated',0,5),
(2788,4,1,5,20790,1,20196,5,525, N'Currency',0,12),
(2789,4,4,NULL,20792,1,20196,5,500, N'Tax Withholding Details',1,4),
(2790,4,4,NULL,20794,1,20194,5,600, N'Remittance Details',1,4),
(2791,4,4,NULL,20795,1,20196,5,600, N'Remittance Details',1,4),
(2792,4,7,NULL,20797,1,25380,4,1, N'Details',0,51),
(2793,4,1,5,20800,1,20797,5,30, N'Currency',0,12),
(2794,4,1,2,20801,1,20797,5,40, N'Amount of non-UK earnings remitted to the UK',0,6),
(2795,4,1,10,20804,1,20797,5,50, N'Notes',0,14),
(2796,4,1,2,20807,1,10506,3,80, N'Council tax',0,6),
(2797,4,1,2,20808,1,10506,3,90, N'Water rates',0,6),
(2798,4,1,2,20809,1,10506,3,130, N'Travel (see information for more detail)',0,6),
(2799,4,1,2,20810,1,10506,3,140, N'Meals (see information for more details)',0,6),
(2800,4,1,6,20812,1,20399,5,100, N'Employment start date (if during the UK tax year ended 05 Apr 2019)',0,5),
(2801,4,1,6,20813,1,20399,5,110, N'Employment end date (if during the UK tax year ended 05 Apr 2019)',0,5),
(2802,4,1,13,20814,1,22457,4,10, N'Employer name',0,1),
(2803,4,1,2,20816,1,20179,5,150, N'Car (box 9)',0,6),
(2804,4,1,2,20817,1,20179,5,220, N'Private medical (box 11)',0,6),
(2805,4,1,2,20818,1,20179,5,110, N'Living accommodation (box 14)',0,6),
(2806,4,1,2,20820,1,20179,5,240, N'Qualifying relocation expenses (box 15)',0,6),
(2807,4,1,2,20821,1,20179,5,320, N'Travel and subsistence (box 16)',0,6),
(2808,4,2,NULL,20858,1,10315,2,90, N'Share Awards',0,65),
(2809,4,6,NULL,20902,1,20904,3,3, N'Offshore Payment of Employment Income',0,58),
(2810,4,1,13,20903,1,10616,5,10, N'Employer',0,1),
(2811,4,2,NULL,20904,1,10315,2,180, N'Offshore Payment of Employment Income',0,65),
(2812,4,1,9,20905,1,20904,3,1,N'Was any of your employment income (remuneration/earnings) paid offshore (i.e., to a non-UK bank account)?',0,15),
(2813,4,1,10,20906,1,20904,3,2, N'Notes',0,14),
(2814,4,1,2,20971,1,10513,5,140, N'Home leave expenses (net of any employer reimbursements)',0,6),
(2815,4,1,3,21460,1,11507,4,40, N'Country',0,9),
(2816,4,4,NULL,21533,1,91578,3,895, N'UK Bank Account Information',1,4),
(2817,4,1,14,21534,1,91578,3,900,N'If you have an overpayment of UK taxes, would you like it paid directly into your bank account?',0,13),
(2818,4,4,NULL,21536,1,91578,3,905,N'If Yes, please complete the following information:',1,4),
(2819,4,1,13,21538,1,91578,3,930, N'Name of bank or building society',0,1),
(2820,4,1,13,21539,1,91578,3,925, N'Branch sort code (six digit format: xx-xx-xx)',0,1),
(2821,4,1,13,21540,1,91578,3,920, N'Account number (eight digits)',0,1),
(2822,4,1,7,21547,1,20194,5,210, N'Interest type',0,2),
(2823,4,1,9,21901,1,20393,3,10, N'Did you bear any expenses - not reimbursed - in regards to home leave (please do not include your business trips) for you or your spouse?',0,15),
(2824,4,1,13,21908,1,20185,5,300,N'If Other, please specify',0,1),
(2825,4,1,3,21976,1,11443,5,40, N'Location of organization/beneficiary',0,9),
(2826,4,1,2,22411,1,20179,5,40, N'Assets transferred (box 13)',0,6),
(2827,4,1,2,22412,1,20179,5,60, N'Payments made on behalf of employee (box 15)',0,6),
(2828,4,1,2,22413,1,20179,5,90, N'Vouchers or credit cards (box 12)',0,6),
(2829,4,1,2,22414,1,20179,5,130, N'Mileage allowance and passenger payments (box 12)',0,6),
(2830,4,1,2,22415,1,20179,5,160, N'Car fuel (box 10)',0,6),
(2831,4,1,2,22416,1,20179,5,180, N'Vans (box 9)',0,6),
(2832,4,1,2,22417,1,20179,5,200, N'Interest-free or low interest loans (box 15)',0,6),
(2833,4,1,2,22418,1,20179,5,260, N'Services supplied to employee (box 15)',0,6),
(2834,4,1,2,22419,1,20179,5,280, N'Assets placed at the employee''s disposal (box 13)',0,6),
(2835,4,1,2,22420,1,20179,5,330, N'Entertainment (box 16)',0,6),
(2836,4,1,2,22421,1,20179,5,340, N'General expenses allowance for business travel (box 16)',0,6),
(2837,4,1,2,22422,1,20179,5,350, N'Payments for use of home telephone (box 16)',0,6),
(2838,4,1,2,22423,1,20179,5,360, N'Non-qualifying relocation expenses (box 16)',0,6),
(2839,4,1,9,22424,1,20189,3,140,N'Did you make any contributions to a non-company UK pension plan? This would include a Personal Pension Plan (PPP), a Stakeholder Pension Plan (ST), or a Free Standing Additional Voluntary Contribution arrangement (FSAVC).',0,15),
(2840,4,1,13,22425,1,20399,5,30, N'Employer tax reference',0,1),
(2841,4,1,9,22427,1,20198,3,70, N'Did you have income from a UK trust and/or remit income from a non-UK trust to the UK?',0,15),
(2842,4,1,13,22428,1,91578,3,915, N'Building society reference',0,1),
(2843,4,1,13,22434,1,10002,3,110, N'Please specify',0,1),
(2844,4,1,6,22436,1,20517,3,2260,N'If you were not living in the UK on 05 Apr 2019 but previously resided in the UK, please specify the date you left (you should leave this box blank if you have never resided in the UK or resided in the UK for the whole 2018/2019 tax year)',0,5),
(2845,4,1,7,22437,1,10113,3,20, N'Marital status at 05 Apr 2019',0,2),
(2846,4,1,13,22438,1,91578,3,910, N'Name of account holder',0,1),
(2847,4,1,7,22439,1,91700,4,10, N'Type of residence that you lived in during the tax year',0,2),
(2848,4,1,13,22447,1,22457,4,20, N'Employer address',0,1),
(2849,4,1,13,22448,1,22457,4,30, N'Employer address line 2',0,1),
(2850,4,1,13,22449,1,22457,4,40, N'Employer address line 3',0,1),
(2851,4,1,13,22450,1,22457,4,50, N'Employer address line 4',0,1),
(2852,4,1,13,22451,1,22457,4,60, N'Employer postal code/zip code',0,1),
(2853,4,7,NULL,22452,1,92359,4,20, N'Details',0,56),
(2854,4,1,2,22453,1,22452,5,30, N'Amount received',0,6),
(2855,4,1,7,22454,1,22452,5,10, N'Type of payment',0,2),
(2856,4,1,14,22455,1,22452,5,40, N'Is this amount included in your P60 figure?',0,13),
(2857,4,1,5,22456,1,22452,5,20, N'Currency',0,12),
(2858,4,6,NULL,22457,1,24371,3,20, N'Dual Contracts',0,51),
(2859,4,1,6,22458,1,22457,4,100, N'Date remitted (if any compensation amount was remitted to the UK during the tax year ending 05 Apr 2019)',0,5),
(2860,4,1,13,22459,1,22457,4,90, N'Total remuneration for the year ended 05 Apr 2019',0,1),
(2861,4,1,5,22460,1,22457,4,80, N'Currency',0,12),
(2862,4,1,2,22461,1,22457,4,110, N'Amount remitted',0,6),
(2863,4,1,2,22462,1,22457,4,120, N'Amount of tax paid on this income',0,6),
(2864,4,1,9,22463,1,25379,3,1,N'In 2018/2019, did you remit to the UK any employment income which you received prior to 06 Apr 2018 and which you had previously kept outside the UK in order to benefit from the overseas workday deduction income? (Please note that this does not apply to employment income earned while a non-resident of the UK).',0,15),
(2865,4,1,2,22464,1,20185,5,410,N'Gross amount of payment (if annuity, provide total amount received in 2018/2019)',0,6),
(2866,4,1,2,22465,1,20185,5,480,N'UK tax withheld at source from payment(s), (if annuity, provide total amount withheld in 2018/2019)',0,6),
(2867,4,1,2,22466,1,10796,5,330, N'Net dividend received',0,6),
(2868,4,1,9,22467,1,20191,3,50,N'Did you have any dividend income from UK sources, and/or remit to the UK any dividend income from non-UK sources? Please enter the UK dividend income below and the details of any non-UK dividend income remitted to the UK in the Remittance Details section.',0,15),
(2869,4,1,9,22468,1,10829,3,30,N'Did you have any UK interest income, and/or remit to the UK any interest income from non-UK sources? Please enter the UK interest below and the details of any non-UK interest remitted to the UK in the Remittance Details section.',0,15),
(2870,4,4,NULL,22470,1,24278,4,20,N'If you were non-resident of the UK throughout the tax year 06 Apr 2018 to 05 Apr 2019, then although gains realized in the year (with the exception of disposals of UK Residential Property) do not have to be recorded on your 2018/2019 tax return, they may be reportable and taxable if and when you return to the UK. Please refer to the information icon for further details.',1,17),
(2871,4,4,NULL,22471,1,24278,4,40,N'If you arrived in the UK (or returned to the UK) in the tax year, please refer to the information icon for details on ''Temporary residence outside the UK'' and ''Year of return to the UK''.',1,17),
(2872,4,4,NULL,22472,1,24278,4,60,N'If you left the UK in the tax year and you expect to be regarded as a non-resident of the UK following your departure, please refer to the information icon for details on ''Your departure from the UK''.',1,17),
(2873,4,1,9,22473,1,10853,3,30,N'Did you sell or dispose of any UK chargeable assets during the 2018/2019 tax year, or remit to the UK the proceeds of gains made on the sale or disposition of non-UK chargeable assets? ''Assets'' refers to stocks, property, assets held for investment, or currency.',0,15),
(2874,4,1,12,22547,1,20175,3,310, N'HIDDEN PROFORMA QUESTION - Do you claim to be Domiciled outside the UK?',0,16),
(2875,4,1,9,22550,1,20200,3,70,N'Did you have any income from a property outside the UK (i.e., rental income) and/or remit to the UK any income from a property outside the UK?',0,15),
(2876,4,2,NULL,22551,1,11778,2,260, N'UK Notice of Coding',0,65),
(2877,4,1,9,22552,1,22551,3,10, N'Did you have any underpaid tax from a previous year ''coded out'' with your UK ''Notice of Coding''?',0,15),
(2878,4,6,NULL,22553,1,22551,3,20, N'UK Notice of Coding',0,51),
(2879,4,1,13,22554,1,22553,4,10, N'Underpaid tax for earlier years included in your tax code for 2018/2019',0,1),
(2880,4,1,13,22555,1,22553,4,20, N'Underpaid tax for 2018/2019 included in your tax code for 2019/2020',0,1),
(2881,4,2,NULL,22620,1,10001,2,26, N'Travel Details',0,67),
(2882,4,1,13,22700,1,10113,3,150, N'Name of your spouse (if applicable and not already provided)',0,1),
(2883,4,1,2,22957,1,20187,5,100, N'Personal contributions (before any tax relief given at source)',0,6),
(2884,4,4,NULL,22958,1,22620,3,5,N'You are required to provide accurate details of your travel for the year.  Failure to provide this information will result in further information being requested, which could lead to delays and subsequently, interest and penalties being incurred with HMRC.  Please ensure that full and accurate information is provided.',1,18),
(2885,4,4,NULL,22963,1,10506,3,10,N'Amounts you enter in the boxes below must be the totals relating only to the period you were in the UK during the tax year. We will not know to adjust for any monthly or annualized amounts you enter (unless you specify in the Notes). The deduction is only available for your personal costs, or your share of household costs. Please report the full costs incurred for your household and enter, in the following questions, which family members lived with you during the tax year (e.g., spouse, two children, etc.) or confirm you lived on your own. We may reduce the deductible amounts as appropriate.',1,18),
(2886,4,2,NULL,23114,1,10315,2,350, N'Union Dues/Subscriptions to Professional Organizations',0,65),
(2887,4,1,9,23115,1,23114,3,10, N'Did you pay any union dues/subscriptions to professional organizations?',0,15),
(2888,4,1,10,23116,1,23114,3,40, N'Notes',0,14),
(2889,4,1,2,23372,1,10451,3,10, N'Number of UK workdays',0,6),
(2890,4,1,2,23373,1,10506,3,60,N'If different, annual rent paid by you (and not reimbursed by your employer)',0,6),
(2891,4,1,2,23374,1,10506,3,190, N'Council tax',0,6),
(2892,4,1,2,23375,1,10506,3,200, N'Water rates',0,6),
(2893,4,1,2,23376,1,10506,3,210,N'Utilities (other than telephone, television or internet)',0,6),
(2894,4,1,13,23377,1,10506,3,260, N'Other (description)',0,1),
(2895,4,1,2,23378,1,10506,3,270, N'Other (amount)',0,6),
(2896,4,1,2,23379,1,10506,3,240, N'Travel (see information for more detail)',0,6),
(2897,4,1,2,23380,1,10506,3,250, N'Meals (see information for more detail)',0,6),
(2898,4,1,14,23381,1,11869,3,200, N'Did you receive any benefit from pre-owned assets?',0,13),
(2899,4,1,2,23382,1,11732,5,290, N'Amount reimbursed by your employer',0,6),
(2900,4,1,2,23384,1,11869,3,240,N'If your employer(s) has/have deducted Student Loan repayments, please enter the total amount deducted by all employers here',0,6),
(2901,4,1,14,23385,1,11869,3,220, N'Have you received notification from the Student Loans Company that repayment of an Income Contingent Student Loan began before 06 Apr 2019?',0,13),
(2902,4,1,7,23389,1,20517,3,2320, N'Explain what has changed',0,2),
(2903,4,1,6,23390,1,20517,3,2325, N'Specify when the change was agreed upon',0,5),
(2904,4,1,9,23392,1,20375,3,80, N'Did you receive any UK State Retirement Pension or other UK State benefits (excluding Child Benefit received by you or your partner/spouse)?',0,15),
(2905,4,1,14,23393,1,20187,5,270, N'Have you received any loan or other benefit from any retirement benefit plan during the tax year?',0,13),
(2906,4,2,NULL,23395,1,10001,2,4, N'UK Domicile',0,67),
(2907,4,1,6,23396,1,23395,3,40,N'If you had a domicile of origin in the UK, and believe it has changed, enter the date it changed',0,5),
(2908,4,1,14,23397,1,23395,3,50, N'Were you born in the UK?',0,13),
(2909,4,4,NULL,23516,1,10130,3,620,N'The UK has mandatory electronic filing of UK Tax Returns. You will not be able to file your return without a UTR number. This number will be found on the front page of any issued Tax Return or on any self-assessment correspondence from HMRC. If KPMG is not authorized to hold a tax briefing at the start of your assignment or you have not yet contacted KPMG to schedule this briefing, it is essential that you contact your KPMG representative as soon as possible for further guidance.',1,4),
(2910,4,4,NULL,23637,1,11869,3,10,N'The help provided in this questionnaire is intended to assist you in the completion of the questionnaire but cannot possibly cover every form of income or gain in the examples given, or provide technical advice to cover every situation. You are reminded that when signing your tax return you have a legal responsibility to ensure that it is complete and correct.',1,18),
(2911,4,1,5,23695,1,11732,5,150, N'Currency',0,12),
(2912,4,4,NULL,24024,1,20179,5,30, N'P11D Section A',1,4),
(2913,4,4,NULL,24025,1,20179,5,50, N'P11D Section B',1,4),
(2914,4,4,NULL,24026,1,20179,5,80, N'P11D Section C',1,4),
(2915,4,4,NULL,24027,1,20179,5,100, N'P11D Section D',1,4),
(2916,4,4,NULL,24028,1,20179,5,120, N'P11D Section E',1,4),
(2917,4,4,NULL,24029,1,20179,5,140, N'P11D Section F',1,4),
(2918,4,4,NULL,24030,1,20179,5,170, N'P11D Section G',1,4),
(2919,4,4,NULL,24031,1,20179,5,190, N'P11D Section H',1,4),
(2920,4,4,NULL,24032,1,20179,5,210, N'P11D Section I',1,4),
(2921,4,4,NULL,24033,1,20179,5,230, N'P11D Section J',1,4),
(2922,4,4,NULL,24034,1,20179,5,250, N'P11D Section K',1,4),
(2923,4,4,NULL,24035,1,20179,5,270, N'P11D Section L',1,4),
(2924,4,4,NULL,24036,1,20179,5,290, N'P11D Section M',1,4),
(2925,4,4,NULL,24037,1,20179,5,310, N'P11D Section N',1,4),
(2926,4,1,2,24038,1,20179,5,70, N'Tax on notional payments not borne by employee within 90 days (box 15)',0,6),
(2927,4,1,14,24058,1,23395,3,30, N'Do you claim to be domiciled outside the UK?',0,13),
(2928,4,1,3,24060,1,20196,5,490, N'Country where sold or disposed of if different from country of origin',0,9),
(2929,4,2,NULL,24061,1,11778,2,240, N'Foreign Tax Issues',0,65),
(2930,4,2,NULL,24062,1,11778,2,250, N'EU Special Withholding Tax And Tax Withheld Under The Swiss/UK Tax Cooperation Agreement',0,65),
(2931,4,1,9,24063,1,24061,3,10, N'Did you pay any non UK income or capital gains tax relating to income and/or gains arising outside the UK during the tax year?',0,15),
(2932,4,1,9,24064,1,24062,3,10, N'Did you pay any ''Special Withholding Tax'' under the EU Savings Directive or have tax withheld under the Swiss/UK Tax Cooperation agreement?',0,15),
(2933,4,2,NULL,24066,1,11831,2,400, N'Remittance Basis Charge (RBC)',0,61),
(2934,4,4,NULL,24067,1,24066,3,30,N'If you have been resident in the UK for any part of seven of the nine UK tax years ended 05 Apr 2018 and you wish to claim the remittance basis, you will be required to pay a 30,000 pounds sterling tax charge. The payment of the charge does not mean you will not be taxable on any remittances you make. They will still be taxable and should be reported in this Tax Questionnaire.',1,4),
(2935,4,1,7,24068,1,24066,3,60,N'I have discussed the Remittance Basis Charge with KPMG and I wish to claim the remittance basis and pay the 30,000 pounds sterling Remittance Basis Charge.',0,2),
(2936,4,1,7,24069,1,24066,3,70,N'I have not discussed the matter with KPMG but I wish to claim the remittance basis and pay the 30,000 pounds sterling Remittance Basis Charge.',0,2),
(2937,4,1,7,24070,1,24066,3,80, N'I have discussed the remittance basis charge with KPMG and I do not wish to pay the remittance basis charge. I wish to be taxed on the arising basis.',0,2),
(2938,4,1,7,24071,1,24066,3,90,N'I do not know whether it is beneficial for me to claim the remittance basis and pay the 30,000 pounds sterling Remittance Basis Charge or not pay the Remittance Basis Charge and be taxable on the arising basis.',0,2),
(2939,4,1,13,24072,1,20185,5,130, N'Name of pension plan provider',0,1),
(2940,4,1,13,24073,1,20187,5,40, N'Name of pension plan provider',0,1),
(2941,4,1,7,24074,1,20187,5,260, N'Is the pension scheme a defined benefit (final salary) scheme or a defined contributions scheme?',0,2),
(2942,4,1,14,24075,1,11869,3,210, N'Do you own a property in the UK through a trust or a company?',0,13),
(2943,4,1,9,24076,1,10853,3,40,N'Did you, in UK Pounds Sterling terms, make any capital losses on the disposal of non-UK assets?',0,15),
(2944,4,1,14,24077,1,11106,5,650, N'Did you cease to receive income from this property during the year ended 05 Apr 2019 and are you not expecting to receive any income from it during the year ending 05 Apr 2020?',0,13),
(2945,4,1,3,24078,1,11869,3,250,N'If you were a tax resident of a country other than the UK during the year ended 05 Apr 2019, please select the country',0,9),
(2946,4,1,10,24079,1,24062,4,15, N'Notes',0,14),
(2947,4,1,13,24202,1,11146,5,10, N'Property address (including city and country)',0,1),
(2948,4,1,2,24203,1,20196,5,260, N'Acquisition costs',0,6),
(2949,4,4,NULL,24205,1,24066,3,40,N'If you are unsure if your level of offshore income and gains merit making the election, please contact your KPMG tax adviser.',1,4),
(2950,4,1,14,24206,1,20196,5,110,N'If you have disposed of shares, were the shares acquired by way of a share incentive such as the exercise of an option by your employer?',0,13),
(2951,4,6,NULL,24245,1,24062,3,20, N'EU Special Withholding Tax And Tax Withheld Under The Swiss/UK Tax Cooperation Agreement',0,62),
(2952,4,1,14,24246,1,24245,4,10, N'In the Interview section you stated that you had tax withheld under the provisions of the EU Savings Directive or the Swiss/UK Tax Cooperation Agreement. Has this information been included elsewhere in the Questionnaire?',0,13),
(2953,4,1,10,24247,1,24245,4,60, N'Notes',0,14),
(2954,4,1,3,24248,1,20517,3,2250, N'Which country were you living in on 05 Apr 2018?',0,9),
(2955,4,1,14,24249,1,24066,3,50,N'Do you wish to claim the remittance basis and pay the 30,000 pounds sterling Remittance Basis Charge?',0,13),
(2956,4,2,NULL,24252,1,11831,2,390, N'Remittance Basis de Minimis Limit',0,61),
(2957,4,4,NULL,24253,1,24252,3,29,N'Before 06 Apr 2008, claiming the remittance basis did not have a UK tax cost. This meant that it was almost always better to file your tax return on the remittance basis. For an overview of the remittance basis, please review the information text on top of this page.',1,17),
(2958,4,4,NULL,24254,1,24252,3,30,N'Since 06 Apr 2008, claiming the remittance basis comes with a tax cost. That cost is the loss of the annual personal allowance and the capital gains tax exemption. However from 06 Apr 2010, separate rules restrict the amount of the personal allowance for taxpayers whose taxable income for the year is greater than 100,000 pounds sterling. There is a gradual reduction until taxable income is greater than 123,700 pounds sterling. At this point there is no personal allowance available.',1,17),
(2959,4,1,14,24256,1,24252,3,50, N'Do you agree to the preparation of your tax return on the remittance basis?',0,13),
(2960,4,4,NULL,24260,1,24252,3,40,N'The exception to the above rules is if an individual has less than 2,000 pounds sterling of unremitted foreign income and gains during the year ended 05 April 2019. In this case, the remittance basis of taxation can be chosen without the cost of losing the annual personal allowance and capital gains annual exemption. Note that the separate rules restricting the personal allowance where income is greater than 100,000 pounds sterling would still apply.',1,17),
(2961,4,1,9,24270,1,10751,3,20, N'Were you a member of any pension/retirement plan(s)?',0,15),
(2962,4,1,9,24271,1,20191,3,40, N'Did you have any UK dividend income?',0,15),
(2963,4,1,9,24272,1,10829,3,40, N'Did you have any UK interest income?',0,15),
(2964,4,1,9,24273,1,10735,3,40, N'Did you receive any pension or annuity payments from a UK pension or retirement plan?',0,15),
(2965,4,1,9,24274,1,10735,3,30,N'Did you receive any non-annuity pension payments or benefits, for example lump-sum payments, loans, distributions etc., from a UK or non-UK pension or retirement plan?',0,15),
(2966,4,1,9,24275,1,20200,3,60,N'Did you have any income from a property in the UK (i.e., rental income)?',0,15),
(2967,4,1,3,24277,1,22457,4,70, N'Country',0,9),
(2968,4,7,NULL,24278,1,10853,3,65, N'Capital Gains Instructions',0,51),
(2969,4,1,10,24282,1,22551,3,15, N'Notes',0,14),
(2970,4,1,13,24283,1,20196,5,300, N'Enhancement/Improvement costs (please provide details of the amounts and the date of the enhancement/improvement)',0,1),
(2971,4,2,NULL,24284,1,11778,2,230, N'Payments on Account',0,65),
(2972,4,1,9,24285,1,24284,3,10, N'Did you make any UK tax Payments On Account?',0,15),
(2973,4,1,10,24286,1,24284,3,15, N'Notes',0,14),
(2974,4,7,NULL,24290,1,25288,4,10, N'Details',0,51),
(2975,4,4,NULL,24306,1,24278,4,10, N'Full Year Non-Resident',1,4),
(2976,4,4,NULL,24307,1,24278,4,30, N'Year of Arrival or Return to the UK',1,4),
(2977,4,4,NULL,24308,1,24278,4,50, N'If you left the UK to become Non-Resident',1,4),
(2978,4,1,7,24309,1,20517,3,2330, N'Have you been regarded as a resident of the UK for any part of seven of the nine tax years ending 05 Apr 2018?',0,2),
(2979,4,4,NULL,24350,1,11360,5,170, N'Remittance Details',1,4),
(2980,4,2,NULL,24362,1,10263,2,360, N'Detached Duty',0,65),
(2981,4,1,9,24363,1,24362,3,10, N'Did you arrive in the UK during 2018/2019 on an assignment expected to last for two years or less?',0,15),
(2982,4,1,10,24365,1,24362,3,25, N'Notes',0,14),
(2983,4,1,9,24366,1,20211,3,270,N'Did you make, or do you intend to make, any charitable contributions after 05 Apr 2019 but before 31 Jan 2020 and want to claim relief for the contributions on your 2018/2019 tax return?',0,15),
(2984,4,2,NULL,24371,1,10315,2,150, N'Dual Contracts',0,65),
(2985,4,1,10,24372,1,24371,3,15, N'Notes',0,14),
(2986,4,2,NULL,24542,1,10263,2,10, N'Contact Information - E-mail',0,61),
(2987,4,4,NULL,24574,1,11106,5,340, N'Property Details - Rent',1,4),
(2988,4,4,NULL,24579,1,20196,5,95, N'If Shares please provide the following information',1,4),
(2989,4,1,10,24692,1,24542,3,50, N'Notes',0,14),
(2990,4,4,NULL,25192,1,23395,3,20, N'Based on the information in the above paragraph:',1,4),
(2991,4,1,14,25196,1,22620,3,35,N'Did you spend any days in the UK during the year ended 05 Apr 2019 due to exceptional circumstances beyond your control (i.e., illness to yourself or a member of your immediate family)?',0,13),
(2992,4,1,14,25198,1,22620,3,30, N'I confirm that my Travel Tracker data accurately reflects the number of non-UK workdays and total workdays I had in tax year 2018/2019',0,13),
(2993,4,4,NULL,25199,1,20399,5,470,N'If you received income or taxable benefits, or had tax withholding from this employer that is not included in the details above, please provide details in the Notes.',1,18),
(2994,4,4,NULL,25200,1,20797,5,10,N'Please provide details of employment income which fits the following criteria: (1) received in a tax year prior to the year ending 05 Apr 2019, and (2) remitted to the UK during the year ending 05 Apr 2019, and (3) you benefited from a deduction in respect of compensation relating to overseas workdays in the tax year in which it was received',1,17),
(2995,4,1,6,25202,1,10796,5,570, N'Date remitted dividends were originally paid',0,5),
(2996,4,1,13,25203,1,10796,5,580,N'If remitted dividends were received on various dates, please describe the period',0,1),
(2997,4,1,6,25204,1,20194,5,690, N'Date remitted interest was originally paid',0,5),
(2998,4,1,13,25205,1,20194,5,700,N'If remitted interest was not received on a specific date, please describe the period over which it accrued',0,1),
(2999,4,1,6,25206,1,11146,5,40, N'Date remitted income was originally paid',0,5),
(3000,4,1,13,25207,1,11146,5,50,N'If remitted income was not received on a specific date, please describe the period over which it accrued',0,1),
(3001,4,1,13,25208,1,11360,5,210,N'If remitted income was not received on a specific date, please describe the period over which it accrued',0,1),
(3002,4,1,6,25209,1,11360,5,200, N'Date remitted income was originally paid',0,5),
(3003,4,1,14,25210,1,11732,5,10,N'Did you use your privately-owned car for business purposes, other than commuting, during the tax year?',0,13),
(3004,4,1,7,25211,1,10616,5,60, N'Was this account jointly held or solely in your name?',0,2),
(3005,4,1,14,25212,1,10616,5,90,N'Indicate Yes if the account contains only: 1) employment income, and 2) any interest income accrued on that employment income (i.e., you have not transferred any other funds into that account). If this is not the case, indicate No and provide details of funds transferred in the Notes.',0,13),
(3006,4,1,13,25213,1,11106,5,20,N'If jointly owned with other, please indicate the name of the joint owner and their relationship to you (for example: Mrs. Smith; sister)',0,1),
(3007,4,1,14,25214,1,11106,5,490,N'If furnished, is this property considered a Furnished Holiday Letting? (HMRC has expanded the definition of Furnished Holiday Lettings to include non-UK properties if they qualify; review the specific criteria in the information icon.)',0,13),
(3008,4,1,6,25215,1,20196,5,650, N'Date remitted proceeds were originally realized',0,5),
(3009,4,1,7,25216,1,11869,3,270,N'If you have filed a UK tax return since 05 April 2008 on the remittance basis, did you make a foreign loss election?',0,2),
(3010,4,4,NULL,25217,1,11869,3,260,N'If KPMG did not prepare your tax return for the year ended 05 Apr 2018, please answer the following:',1,17),
(3011,4,4,NULL,25218,1,91874,5,20,N'If No, please answer the questions below. Your KPMG representative may need to contact you for additional information.',1,17),
(3012,4,4,NULL,25219,1,24245,4,20, N'Please answer the questions below. Your KPMG representative may need to contact you for additional information.',1,17),
(3013,4,1,3,25220,1,24245,4,30, N'Country',0,9),
(3014,4,1,5,25221,1,24245,4,40, N'Currency',0,12),
(3015,4,1,2,25222,1,24245,4,50, N'Amount',0,6),
(3016,4,4,NULL,25223,1,10506,3,70, N'Annual Amount of Other Housing Expenses',1,4),
(3017,4,4,NULL,25224,1,10506,3,180, N'Annual Amounts Paid by You (and not reimbursed by your employer)',1,4),
(3018,4,1,14,25250,1,11106,5,70, N'Please confirm only your share of any income and/or expenses will be entered in the subsequent Property Income pages',0,13),
(3019,4,4,NULL,25267,1,23395,3,10,N'You normally acquire a domicile of origin from your father when you are born. It need not be the country in which you are born. For example, if you were born in France while your father is working there, but his permanent home is in the UK, your domicile of origin is in the UK. Your domicile could change either because the person on whom you were legally dependent as a minor changed their domicile, or you have taken steps to acquire a domicile of choice by leaving your current country and settling permanently in another country (for example with a view of retiring in your chosen country). If you are merely on assignment in another country, that will not change your current country of domicile or domicile of origin.',1,18),
(3020,4,4,NULL,25268,1,20175,3,20,N'In answering the following profiling questions, please treat your home country as the country of your permanent home (e.g., family, social, economic ties) and your host country as the country in which you are primarily working for a defined period of time. If you travel from your home to your host country on a weekly (commuter) basis please answer for the entire period of your host country working arrangements.',1,17),
(3021,4,4,NULL,25280,1,24252,3,80,N'Please be aware that if, in preparing your Tax Return, KPMG considers that it may be tax advantageous for you to file a particular way which your responses above do not match, your KPMG representative will contact you to discuss the options.',1,18),
(3022,4,4,NULL,25281,1,20196,5,670,N'Please provide any additional information in the Notes that you feel is material to the calculation of your capital gains tax liability (e.g., gains on assets such as shares acquired under a share scheme of a past or present employer, gains on shares that were the subject of hold-over relief or deferral relief claims or losses to be carried forward from prior years).',1,18),
(3023,4,4,NULL,25285,1,20179,5,10, N'Please copy the details from your Form P11D into the corresponding box below:',1,4),
(3024,4,1,14,25287,1,11360,5,230,N'If KPMG has not prepared your UK tax return in previous years and in one of those years, you remitted part, or all, of the proceeds from a disposal of a non-UK sited asset, please respond ''Yes'' to this statement and your KPMG representative will contact you for additional information as necessary.',0,13),
(3025,4,6,NULL,25288,1,24284,3,20, N'Payments on Account',0,58),
(3026,4,1,5,25289,1,91874,5,50, N'Currency',0,12),
(3027,4,1,3,25290,1,91874,5,40, N'Country',0,9),
(3028,4,1,14,25291,1,91874,5,10, N'In the Interview section you stated that you had paid non-UK tax on income and/or gains during the year. Has this information been included elsewhere in the Questionnaire?',0,13),
(3029,4,1,6,25292,1,91874,5,30, N'Date on which non-UK tax paid (leave blank if tax was not paid on a specific date)',0,5),
(3030,4,1,2,25293,1,91874,5,70, N'Amount of income or gains on which non-UK tax arose',0,6),
(3031,4,1,2,25294,1,91874,5,80, N'Amount of non-UK tax paid',0,6),
(3032,4,1,13,25297,1,10621,5,90, N'Periods of UK service during this employment',0,1),
(3033,4,1,7,25298,1,10621,5,100,N'If known, were you considered Resident in the UK for any of the period indicated above?',0,2),
(3034,4,1,13,25299,1,10621,5,110,N'If Yes, specify the period that you were considered Resident. If No or I don''t know, please leave blank.',0,1),
(3035,4,1,10,25368,1,23395,3,70, N'Notes',0,14),
(3036,4,4,NULL,25374,1,20194,5,65, N'Enter your UK interest below and enter the details of any non-UK interest remitted to the UK in the Remittance Details section at the bottom of this page.',1,18),
(3037,4,4,NULL,25375,1,10796,5,53, N'Enter your UK dividends below and enter the details of any non-UK dividends remitted to the UK in the Remittance Details section at the bottom of this page.',1,18),
(3038,4,4,NULL,25376,1,11360,5,45, N'Enter your UK ''Other Income'' below and enter the details of any non-UK ''Other Income'' remitted to the UK in the Remittance Details section at the bottom of this page.',1,18),
(3039,4,1,9,25377,1,24362,3,20,N'Were you already on assignment in the UK at 06 Apr 2018 and, at that date, the expected total length of your assignment was two years or less?',0,15),
(3040,4,2,NULL,25379,1,10315,2,170, N'Prior Year Remittances of Employment Income',0,65),
(3041,4,6,NULL,25380,1,25379,3,60, N'Prior Year Remittances of Employment Income',0,58),
(3042,4,1,5,25381,1,20194,5,670, N'Currency',0,12),
(3043,4,1,5,25382,1,11360,5,180, N'Currency',0,12),
(3044,4,1,5,25383,1,10796,5,600, N'Currency',0,12),
(3045,4,1,6,25388,1,24290,5,10, N'Date taxes paid',0,5),
(3046,4,1,5,25389,1,24290,5,20, N'Currency',0,12),
(3047,4,1,2,25390,1,24290,5,30, N'Amount of taxes paid',0,6),
(3048,4,1,13,25396,1,91874,5,60,N'Type of income or gains on which non-UK tax arose (e.g., dividends, interest, sales of stock, etc.)',0,1),
(3049,4,1,10,25511,1,12120,3,2490, N'Notes',0,14),
(3050,4,7,NULL,25687,1,11105,4,80, N'Other Expenses - Summary',0,56),
(3051,4,1,7,25688,1,25687,5,10, N'Expense type',0,2),
(3052,4,1,13,25689,1,25687,5,20,N'If Other, specify the expense type',0,1),
(3053,4,1,2,25690,1,25687,5,30, N'Amount',0,6),
(3054,4,1,6,25691,1,25687,5,50, N'Date of payment',0,5),
(3055,4,1,7,25726,1,91700,4,40,N'If rented by you or your employer, is there a break clause in the current lease? This is a clause that would enable you to end the lease before the specified end date.',0,2),
(3056,4,1,2,25727,1,20399,5,420, N'Total student loan deductions made for this employment per Form P60 or Form P45',0,6),
(3057,4,1,6,25728,1,10621,5,50,N'If Yes, please enter the start date of this employment',0,5),
(3058,4,4,NULL,25733,1,23395,3,60,N'In the year ended 2019, if there have been any changes in your circumstances or intentions which may be relevant to your domicile, please indicate in the Notes.',1,18),
(3059,4,1,9,25734,1,27335,3,10, N'Did you arrive in or depart from the UK in the tax year ended 05 Apr 2019?',0,15),
(3060,4,4,NULL,25737,1,20517,3,2245,N'A response to ALL of the following questions is required, otherwise your questionnaire cannot be submitted. If a question does not apply to you, please select Not applicable.',1,18),
(3061,4,1,12,25741,1,20175,3,320, N'HIDDEN PROFORMA QUESTION - Prior year tax return?',0,16),
(3062,4,4,NULL,25747,1,10796,5,60,N'Please provide the name of the country in which the company paying the dividend is located. If you are not sure, please leave blank and ensure that you have entered the full company name to assist KPMG determine the location of the company. Please provide any additional detail in the Notes.',1,18),
(3063,4,1,7,26019,1,24252,3,70,N'Please indicate how much of the amount above you kept outside the UK during the year ended 05 Apr 2019 (if less than £2000, enter the estimated amount in the Notes field below)',0,2),
(3064,4,1,7,26020,1,24252,3,60,N'Excluding your employment income, please provide the amount of your non-UK investment income and gains during the year ended 05 Apr 2019. (Please note that, if you have non-UK rental income, the method of calculating a gain or loss for UK tax purposes may be different to that in which the property is located.  In particular, the UK does not give relief for depreciation and, for 2018/19, only 50% of any mortgage interest paid can be set against the rental income when calculating the profit/loss for UK purposes and the £2,000 limit.  If you are unsure of your position in respect of any non-UK rental income, please provide further details in the notes section below and we will contact you separately regarding this.)',0,2),
(3065,4,1,10,26059,1,22620,3,120, N'Notes',0,14),
(3066,4,1,13,26092,1,20196,5,33,N'If Joint, state percentage of ownership',0,1),
(3067,4,1,9,26113,1,20198,3,60, N'Did you have income from a UK trust?',0,15),
(3068,4,1,13,26114,1,11869,3,280,N'On occasion, HMRC can issue an in-year refund (relating to the 2018/2019 tax year). For example they may have sent you a check. If this applies to you, please provide details of the amount you received.',0,1),
(3069,4,1,13,26700,1,20196,5,250, N'Description of acquisition costs',0,1),
(3070,4,4,NULL,26725,1,24066,3,100,N'If you have been resident in the UK for any part of the twelve of the fourteen UK tax years ended 05 Apr 2018 and you wish to claim the remittance basis, you will be required to pay a 60,000 pounds sterling tax charge. The payment of the charge does not mean you will not be taxable on any remittances you make. They will still be taxable and should be reported in this Tax Questionnaire.',1,4),
(3071,4,4,NULL,26726,1,24066,3,110,N'If you are unsure if your level of offshore income and gains merit making the election, please contact your KPMG tax adviser.',1,4),
(3072,4,1,14,26727,1,24066,3,120,N'Do you wish to claim the remittance basis and pay the 60,000 pounds sterling Remittance Basis Charge?',0,13),
(3073,4,1,7,26728,1,24066,3,130,N'I have discussed the Remittance Basis Charge with KPMG and I wish to claim the remittance basis and pay the 60,000 pounds sterling Remittance Basis Charge.',0,2),
(3074,4,1,7,26729,1,24066,3,140,N'I have not discussed the matter with KPMG but I wish to claim the remittance basis and pay the 60,000 pounds sterling Remittance Basis Charge.',0,2),
(3075,4,1,7,26730,1,24066,3,150, N'I have discussed the remittance basis charge with KPMG and I do not wish to pay the remittance basis charge. I wish to be taxed on the arising basis.',0,2),
(3076,4,1,7,26731,1,24066,3,160,N'I do not know whether it is beneficial for me to claim the remittance basis and pay the 60,000 pounds sterling Remittance Basis Charge or not pay the Remittance Basis Charge and be taxable on the arising basis.',0,2),
(3077,4,1,7,26732,1,20517,3,2335, N'Have you been regarded as a resident of the UK for any part of twelve of the fourteen tax years ending 05 Apr 2018?',0,2),
(3078,4,1,14,26870,1,11869,3,230,N'If Yes, do you think your Student Loan may be fully repaid within the next two years (i.e., by 05 Apr 2021)?',0,13),
(3079,4,1,5,27283,1,20185,5,515, N'Currency',0,12),
(3080,4,4,NULL,27319,1,10616,5,40,N'In order to use a simpler statutory method of calculating remittances to the UK, a non-UK bank account must be nominated. Please provide the following information to allow us to make the nomination:',1,4),
(3081,4,4,NULL,27320,1,10616,5,50, N'In order to be a qualifying account the nominated bank account must have been: (a) an ordinary or savings bank account; (b) if it was an existing account the balance must have been reduced to £10 or less immediately before the date from which could have been regarded as a qualifying account (c) The ''qualifying bank account'' must have only received earnings from your employment under which duties were performed in and outside of the UK or bank interest arising on the account itself.',1,18),
(3082,4,1,14,27321,1,10616,5,100,N'Was the account into which you received the offshore payment of your earnings, a new account (as of when you started your UK assignment) or an existing account?',0,13),
(3083,4,1,13,27324,1,10616,5,70,N'Please provide details of the offshore account into which you were paid (Name of account holder(s), name of bank, location, account number, sort code, other account identification number)',0,1),
(3084,4,1,14,27325,1,10616,5,80,N'Did you change the account into which you received the offshore payment of your earnings during the year? If Yes, please provide details in the Notes.',0,13),
(3085,4,1,14,27326,1,20517,3,2270, N'Were you a resident in the UK during any of the three prior tax years ending 05 Apr 2018?',0,13),
(3086,4,1,7,27327,1,20517,3,2265, N'How many days did you spend in the UK during the year ended 05 Apr 2019?',0,2),
(3087,4,1,14,27328,1,20517,3,2290,N'Is there a period of at least 365 days, part of which falls between 06 Apr 2018 and 05 Apr 2019, where you worked full time in the UK, with no significant break from UK work?',0,13),
(3088,4,1,14,27329,1,20517,3,2280, N'Did you work full time (average of at least 35 hours per week) for the whole of the year ended 05 Apr 2019?',0,13),
(3089,4,1,14,27330,1,20517,3,2275, N'Did you spend 31 days or more working in the UK during the year ended 05 Apr 2019?',0,13),
(3090,4,2,NULL,27335,1,10263,2,350, N'Split Year Treatment',0,65),
(3091,4,1,10,27336,1,27335,3,30, N'Notes',0,14),
(3092,4,6,NULL,27337,1,27335,3,40, N'Split Year Treatment',0,62),
(3093,4,1,13,27338,1,20517,3,2285,N'On average, how many hours do you work per week?',0,1),
(3094,4,1,14,27339,1,27337,4,15,N'Did you have any accommodation that you considered to be a home during the year ended 05 Apr 2019, that ceased to be a home? If Yes, please provide details below:',0,13),
(3095,4,1,13,27340,1,27337,4,20, N'Details of accommodation that ceased to be a home in the year ended 05 Apr 2019',0,1),
(3096,4,1,7,27341,1,27337,4,30,N'If you did not have a home in the UK on 06 Apr 2018, did you begin to have a home in the UK during the tax year?',0,2),
(3097,4,1,6,27342,1,27337,4,40,N'If you did not have a home in the UK on 06 Apr 2018, but you began to have a home in the UK during the year, please provide the date that you began to have a home in the UK.',0,5),
(3098,4,1,14,27343,1,27337,4,50,N'During the year ended 05 Apr 2019, did you cease being in full time employment abroad?',0,13),
(3099,4,1,7,27344,1,27337,4,70, N'Were you considered resident in the UK at any point from 06 Apr 2013 - 05 Apr 2017?',0,2),
(3100,4,1,13,27345,1,27337,4,80, N'Please provide details',0,1),
(3101,4,1,10,27346,1,27337,4,90, N'Notes',0,14),
(3102,4,2,NULL,27347,1,10263,2,340, N'UK Residential Ties',0,62),
(3103,4,4,NULL,27348,1,27347,3,10, N'Family Ties',1,4),
(3104,4,4,NULL,27349,1,27347,3,20, N'Please provide us with the following details regarding your family during the tax year ended 05 Apr 2019.',1,18),
(3105,4,1,14,27350,1,27347,3,30,N'During the year ending 05 Apr 2019, were any of the following people considered UK resident for tax purposes: (a) Your husband, wife or civil partner (unless you were separated) (b) Your partner, if you were living together as husband and wife or as civil partners (c) Your child, if under 18-years old',0,13),
(3106,4,1,14,27352,1,12123,5,610, N'Is your child only in the UK for educational purposes?',0,13),
(3107,4,1,14,27353,1,12123,5,630, N'Did you see your child on fewer than 61 days in the UK during the year ended 05 Apr 2019?',0,13),
(3108,4,4,NULL,27355,1,27347,3,50, N'Please provide us with details of any UK accommodation available to you during the year ended 05 Apr 2019.',1,18),
(3109,4,4,NULL,27356,1,27347,3,40, N'Accommodation Ties',1,4),
(3110,4,1,14,27357,1,27347,3,60, N'Did you own accommodation in the UK and stay in that accommodation for at least one night during the year ended 05 Apr 2019?',0,13),
(3111,4,1,14,27358,1,27347,3,70, N'Did you stay in accommodation that you rented for at least one night?',0,13),
(3112,4,1,14,27359,1,27347,3,80, N'Was your UK accommodation available to you for a continuous period of at least 91 days during the tax year?',0,13),
(3113,4,1,13,27360,1,27347,3,90,N'If you rented accommodation, can you please provide us with details of your lease (length of lease, is there a break clause?)',0,1),
(3114,4,1,14,27361,1,27347,3,100,N'During the tax year ended 05 Apr 2019, did you stay with relatives in the UK for at least 16 nights?',0,13),
(3115,4,1,13,27362,1,27347,3,120,N'If you answered No to all of the above questions, please provide details of where you stayed while in the UK',0,1),
(3116,4,1,10,27363,1,27347,3,130, N'Notes',0,14),
(3117,4,2,NULL,27364,1,10263,2,330, N'Accommodation & Ties to UK',0,62),
(3118,4,1,14,27365,1,27364,3,20, N'Did you have a home (owned or rented) outside the UK during the year ended 05 Apr 2019?',0,13),
(3119,4,4,NULL,27366,1,27364,3,30,N'If the answer to the above question is Yes, please answer the questions below for each property. If the answer to the above question is No, please continue to Home in the UK.',1,18),
(3120,4,1,14,27367,1,27364,3,40, N'Did you spend at least 30 days in this property during the year ended 05 Apr 2019?',0,13),
(3121,4,1,13,27368,1,27364,3,50,N'If you had more than one home outside the UK, or a home ceased to be a home during the year, please provide additional details here (e.g., the number of days spent in each home, the date the home ceased to be a home)',0,1),
(3122,4,1,14,27369,1,27364,3,70,N'During the tax year ending 05 Apr 2019, did you have a home (owned or rented) within the UK?',0,13),
(3123,4,4,NULL,27370,1,27364,3,80,N'If the answer to the above question is Yes, please answer the questions below for each property. If the answer to the above question is No, please continue to the next page.',1,18),
(3124,4,1,14,27371,1,27364,3,90, N'Did you spend at least 30 days in this property during the year ended 05 Apr 2019?',0,13),
(3125,4,1,13,27372,1,27364,3,100,N'If you had more than one UK home, or a home ceased to be a home during the year, please provide additional details here (e.g., the number of days spent in each home, the date the home ceased to be a home)',0,1),
(3126,4,4,NULL,27373,1,27364,3,10, N'Home Outside of the UK',1,4),
(3127,4,4,NULL,27374,1,27364,3,60, N'Home in the UK',1,4),
(3128,4,1,10,27375,1,27364,3,110, N'Notes',0,14),
(3129,4,2,NULL,27376,1,10263,2,610, N'UK Child Benefit',0,65),
(3130,4,1,9,27377,1,27376,3,1, N'Did you or your spouse/partner make a claim for UK Child Benefit during the tax year ended 05 Apr 2019?',0,15),
(3131,4,6,NULL,27378,1,27376,3,60, N'UK Child Benefit',0,58),
(3132,4,7,NULL,27379,1,27378,4,1, N'Details',0,51),
(3133,4,1,2,27380,1,27379,5,10, N'Amount of Child Benefit received for the period 06 Apr 2018 - 05 Apr 2019',0,6),
(3134,4,1,2,27381,1,27379,5,20, N'Number of children for whom Child Benefit is received',0,6),
(3135,4,1,14,27382,1,27379,5,30,N'Did you or your spouse/partner have an individual income of more than £50,000 during the year ended 05 Apr 2019?',0,13),
(3136,4,1,10,27383,1,27379,5,40, N'Notes',0,14),
(3137,4,4,NULL,27387,1,10616,5,110, N'New Account:',1,4),
(3138,4,1,6,27388,1,10616,5,120,N'If the account into which you received the offshore payment of your earnings was a new account, on which date was the account opened?',0,5),
(3139,4,1,6,27389,1,10616,5,130,N'If the account into which you received the offshore payment of your earnings was a new account, on which date did you receive the first payment of earnings?',0,5),
(3140,4,4,NULL,27390,1,10616,5,140, N'Existing Account:',1,4),
(3141,4,1,6,27391,1,10616,5,150,N'If the account into which you received the offshore payment of your earnings was an existing account, on which date was the balance reduced to £10 or less?',0,5),
(3142,4,1,13,27392,1,27347,3,110, N'If you stayed with relatives please describe their relationship to you',0,1),
(3143,4,1,14,27393,1,20517,3,2300, N'Were you a UK resident but not ordinarily resident at 05 Apr 2013?',0,16),
(3144,4,1,14,27394,1,20517,3,2305, N'Were you a UK resident throughout the whole of the two year period from 06 Apr 2015 to 05 Apr 2017?',0,16),
(3145,4,1,12,27395,1,20517,3,2295, N'HIDDEN PROFORMA QUESTION - Were you UK resident but not ordinarily resident at 05 Apr 2013?',0,16),
(3146,4,1,14,27396,1,12123,5,620,N'If the answer to the above question is Yes, was your child in the UK for more than 20 days outside of term time?',0,13),
(3147,4,1,14,27397,1,27337,4,60,N'During the year ended 05 Apr 2019, did you begin full time employment abroad?',0,13),
(3148,4,1,6,27608,1,27379,5,25,N'If you and your spouse/partner stopped receiving Child Benefit payments during the year ended 05 Apr 2019, on what date did the payments cease?',0,5),
(3149,4,1,14,27633,1,27376,3,2,N'Did you elect not to receive payments on the grounds that your or your spouse/partner''s income level would make you liable to the High Income Child Benefit Charge (i.e., income greater than £50,000)?',0,13),
(3150,4,1,14,27634,1,27637,3,10,N'Did your total pension contributions to the UK and overseas schemes (including personal contributions and those made by your employer) exceed the annual allowance of £40,000 during the pension input period (i.e., the annual accounting period for your policy for UK schemes or the tax year for foreign schemes)? If Yes, please provide the total amount paid in the Notes.',0,13),
(3151,4,1,14,27635,1,10735,3,45,N'Did you receive any benefits/payments from a pension plan during the UK tax year where the total value of the pension plan exceeded the lifetime allowance (currently £1m for 2018/2019)? If Yes, please provide the amount in excess of the lifetime allowance in the Notes.',0,13),
(3152,4,2,NULL,27637,1,11778,2,310, N'Total Pension Contributions',0,65),
(3153,4,1,10,27638,1,27637,3,20, N'Notes',0,14),
(3154,4,4,NULL,27779,1,91123,4,51,N'If uploading the requested information, you will not have to choose ADD NEW to create entries on the following page. Existing entries should be reviewed carefully and edited as required.',1,17),
(3155,4,4,NULL,27780,1,91123,4,52, N'Please enter the details on the following page.',1,17),
(3156,4,1,15,27846,1,20517,3,2336, N'Have you been regarded as a resident of the UK for any part of fifteen of the twenty tax years ending 05 Apr 2018?',0,2),
(3157,4,1,6,27849,1,12009,3,85,N'If your Current Residence Address changed during the year ended 05 Apr 2019, provide the date changed.',0,5),
(3158,4,1,14,27850,1,27337,4,11, N'Did you arrive in or repatriate to the UK in the tax year ended 05 Apr 2019?',0,13),
(3159,4,1,14,27851,1,27337,4,12,N'Did you leave the UK, either permanently, or for full time work overseas, in the year ended 05 Apr 2019?',0,13),
(3160,4,1,14,27852,1,27337,4,25, N'Did you spend fewer than 16 days in the UK after this date?',0,13),
(3161,4,1,6,27853,1,27337,4,23, N'Date accommodation ceased to be a home during the year ended 05 Apr 2019',0,5),
(3162,4,1,6,27854,1,27337,4,55, N'What was your last day of work overseas before returning to the UK?',0,5),
(3163,4,1,6,27855,1,27337,4,58, N'What was your first day of work in the UK after returning to the UK?',0,5),
(3164,4,1,6,27856,1,27337,4,65, N'What was your first day of work overseas?',0,5),
(3165,4,1,14,27857,1,27637,3,12,N'Were you a member of a UK scheme (employer or personal) during the tax year ended 05 Apr 2018? If Yes, provide total contributions made to all UK schemes in the Notes.',0,13),
(3166,4,1,14,27858,1,27637,3,15,N'Were you a member of a UK scheme (employer or personal) during the tax year ended 05 Apr 2017? If Yes, provide total contributions made to all UK schemes in the Notes.',0,13),
(3167,4,1,14,27859,1,27637,3,17,N'Were you a member of a UK scheme (employer or personal) during the tax year ended 05 Apr 2016? If Yes, provide total contributions made to all UK schemes in the Notes.',0,13),
(3168,4,1,14,27877,1,10928,3,20, N'Did you dispose of any UK Residential Property?',0,13),
(3169,4,1,14,27878,1,10928,3,30, N'Did you complete a Non-Resident Capital Gains Tax Return for the disposal?',0,13),
(3170,4,1,13,28130,1,27637,3,5,N'Did your total pension contributions to the UK and overseas schemes (including personal contributions and those made by your employer) exceed the tapered annual allowance of £10,000 during the pension input period (i.e., the annual accounting period for your policy for UK schemes or the tax year for foreign schemes)? If Yes, please provide the total amount paid in the Notes.',0,13),
(3171,4,1,6,28131,1,27364,3,98, N'From what date did the property become available?',0,5),
(3172,4,1,13,28132,1,27364,3,96,N'If relocating to the UK, was the property available for you to reside in before relocating?',0,13),
(3173,4,1,6,28133,1,27364,3,94, N'From what date did the property cease to be available?',0,5),
(3174,4,1,13,28134,1,27364,3,92,N'If relocating out of the UK, did the property continue to be available for you to reside in after relocating?',0,13),
(3175,4,1,13,28135,1,27364,3,42,N'If relocating to the UK, did the property continue to be available for you to reside in after relocating?',0,13),
(3176,4,1,6,28136,1,27364,3,44, N'From what date did the property cease to be available?',0,5),
(3177,4,1,13,28137,1,27364,3,46,N'If relocating out of the UK, was the property available for you to reside in before relocating?',0,13),
(3178,4,1,6,28138,1,27364,3,48, N'From what date did the property become available to you?',0,5),
(3179,4,1,6,28142,1,11869,3,235,N'If your Student Loan was repaid in full during the year ended 5 April 2019, please provide the date that it was paid off',0,5),
(3180,4,1,14,28328,1,20377,3,50,N'Do you have any income or gains from a non-UK policy of life assurance, a life annuity, a capital redemption policy, income from a personal portfolio bond or income treated as arising from a personal portfolio bond?  If yes, please provide details.',0,13),
(3181,4,1,14,28329,1,22457,4,115, N'Did you perform any duties of this contract in the UK?',0,13),
(3182,4,1,14,28330,1,27637,3,18,N'Have you applied for Lifetime Allowance Protection?  If Yes, provide details in the Notes.',0,13),
(3183,4,1,10,28331,1,27376,3,50, N'Notes',0,14),
(3184,4,1,10,28332,1,25379,3,50, N'Notes',0,14),
(3185,4,1,10,28346,1,24252,3,85, N'Notes',0,14),
(3186,4,4,NULL,90019,1,91700,4,70,N'If you intend to purchase a UK property, please contact your KPMG representative to discuss the tax implications.',1,18),
(3187,4,1,2,90034,1,20190,5,220, N'Amount of tax relief already claimed',0,6),
(3188,4,4,NULL,90083,1,10130,3,630,N'This refers to your UK Social Security number, which is needed to process your tax return. Your NI Number will be in one of the following formats: "AA999999A", "AA999999", or "99A99999". You will find your NI Number on your UK payslip, or detailed as your Tax Reference on any HMRC correspondence.',1,18),
(3189,4,4,NULL,90152,1,20399,5,460,N'If you do not have a Form P60, we will need a copy of your wage statement or last payslip showing your employment income data.',1,18),
(3190,4,1,5,90212,1,20196,5,435, N'Currency',0,12),
(3191,4,1,9,90318,1,20198,3,50, N'Did you have income from a trust?',0,15),
(3192,4,1,9,90319,1,20198,3,30,N'Are you a settlor, trustee, or beneficiary of any trusts/estates?',0,15),
(3193,4,1,9,90334,1,20211,3,260, N'Did you make any donations or one-off payments to a UK or EU registered charity through gift aid or under a deed of covenant?',0,15),
(3194,4,1,13,90341,1,11443,5,60, N'Description of shares/securities/land or buildings',0,1),
(3195,4,4,NULL,90413,1,11152,5,10,N'Only include income for the period that the property was rented or available for rent. You already informed us about the ownership. Within the following section, please provide amounts consistent with your ownership percentage.',1,18),
(3196,4,1,5,90418,1,25687,5,25, N'Currency',0,12),
(3197,4,1,2,90443,1,11106,5,160,N'If KPMG did not prepare your UK tax return for the year ending 05 Apr 2018 and if you had any losses relating to this rental property to bring forward from last year, please enter the amount of the loss here',0,6),
(3198,4,4,NULL,90454,1,11416,6,10, N'Mortgage Information',1,4),
(3199,4,1,9,90572,1,20377,3,110, N'Did you receive any other types of non-UK source income or gains?',0,15),
(3200,4,1,9,90749,1,10735,3,35, N'Did you receive any pension or annuity payments from any non-UK pension or retirement plans?',0,15),
(3201,4,4,NULL,90756,1,10393,3,140, N'Host country employer address',1,17),
(3202,4,1,3,90762,1,20517,3,2255, N'Which country were you living in on 05 Apr 2019?',0,9),
(3203,4,4,NULL,90792,1,20517,3,2240, N'United Kingdom',1,4),
(3204,4,1,10,90793,1,20517,3,2340, N'Notes',0,14),
(3205,4,4,NULL,90913,1,10113,3,140, N'Spouse Information',1,4),
(3206,4,4,NULL,91122,1,91123,4,10, N'The sale of land and/or buildings is addressed in a separate section.',1,17),
(3207,4,6,NULL,91123,1,10853,3,60, N'Sale or Disposition of Assets (Capital Gains and Losses) - General Information',0,61),
(3208,4,1,5,91296,1,27379,5,5, N'Currency',0,12),
(3209,4,4,NULL,91570,1,12120,3,2230, N'United Kingdom',1,4),
(3210,4,4,NULL,91571,1,12120,3,2240, N'The UK has mandatory electronic filing of UK Tax Returns.',1,4),
(3211,4,2,NULL,91578,1,10263,2,460, N'Bank Account/Direct Deposit Information',0,61),
(3212,4,1,6,91652,1,91874,5,90, N'Date of payment',0,5),
(3213,4,6,NULL,91700,1,24362,3,30, N'Detached Duty',0,62),
(3214,4,1,9,91713,1,10581,3,20, N'Have you changed employment during the year or received compensation from a prior employment during the year?',0,15),
(3215,4,1,10,91872,1,24061,3,20, N'Notes',0,14),
(3216,4,6,NULL,91873,1,24061,3,30, N'Foreign Tax Issues',0,58),
(3217,4,7,NULL,91874,1,91873,4,1, N'Details',0,51),
(3218,4,1,10,91875,1,91874,5,100, N'Notes',0,14),
(3219,4,1,5,91899,1,11160,5,15, N'Currency',0,12),
(3220,4,1,13,92330,1,20175,3,32, N'Please specify',0,1),
(3221,4,6,NULL,92343,1,10581,3,205, N'Employment Income - General Information',0,51),
(3222,4,4,NULL,92344,1,92343,4,10,N'If your compensation has already been provided to KPMG by your employer, you do not need to complete the next section regarding your employment income.',1,17),
(3223,4,4,NULL,92345,1,92343,4,20,N'However, if this is not the case, or for example:',1,17),
(3224,4,1,10,92346,1,92343,4,300, N'Notes',0,14),
(3225,4,4,NULL,92348,1,20399,5,45,N'Utilizing the ''Upload Documents'' link in the Utilities menu, please provide a copy of:',1,17),
(3226,4,4,NULL,92349,1,20399,5,50, N'All Annual Wage Statements ',1,17),
(3227,4,4,NULL,92350,1,20399,5,55, N'An annual compensation statement detailing the components of your remuneration received. The statement should be in English.',1,17),
(3228,4,4,NULL,92351,1,92343,4,30,N'In order to prepare your tax return, KPMG in general needs information regarding:     your pre and post assignment income    your home and host as well as third country income    your income received from current as well as other employers. ',1,17),
(3229,4,2,NULL,92358,1,10315,2,60, N'Termination Payments',0,65),
(3230,4,6,NULL,92359,1,92358,3,30, N'Termination Payments',0,53),
(3231,4,1,13,92360,1,10621,5,10, N'Employer name',0,1),
(3232,4,1,2,92362,1,11152,5,55, N'Utilities included in gross rent income',0,6),
(3233,4,4,NULL,92384,1,91123,4,20,N'If you have a significant amount of data, you may opt not to enter any details and directly upload the supporting documentation utilizing the ''Upload Documents'' link in the Utilities menu.',1,17),
(3234,4,4,NULL,92385,1,91123,4,30,N'You need to provide the annual (tax) certificates from your investment agency. If the certificates do not contain detailed information such as asset type, date of sale, acquisition cost and sales price as well as taxes withheld, please provide a spreadsheet in English language containing the respective information.',1,17),
(3235,4,1,7,92386,1,91123,4,40, N'Specify how you will submit the requested information',0,2),
(3236,4,1,13,92387,1,91123,4,50, N'Please specify',0,1),
(3237,4,4,NULL,92393,1,11106,5,190,N'If Mixed, please choose',1,4),
(3238,4,1,14,92394,1,11106,5,200, N'Partly self-occupied',0,13),
(3239,4,1,13,92395,1,11106,5,210, N'Please specify the period',0,1),
(3240,4,1,14,92396,1,11106,5,220, N'Partly vacant',0,13),
(3241,4,1,13,92397,1,11106,5,230, N'Please specify the period',0,1),
(3242,4,1,14,92398,1,11106,5,240, N'Partly rented/let out',0,13),
(3243,4,1,13,92399,1,11106,5,250, N'Please specify the period',0,1),
(3244,4,1,9,92416,1,20858,3,20,N'In 2018/2019 did you own any other share based compensation (e.g., Restricted Stock, RSU, Performance Shares, Employee Stock Purchase Plan)?',0,15),
(3245,4,1,9,92429,1,10680,3,20, N'In 2018/2019 did you own stock options received from your current or any previous employer?',0,15),
(3246,4,2,NULL,92458,1,10315,2,95, N'Cash Awards',0,65),
(3247,4,1,9,92460,1,92458,3,20,N'In 2018/2019 did you receive any other cash awards relating to equity (e.g., Phantom Stock, Stock Appreciation Rights)?',0,15),
(3248,4,4,NULL,92490,1,20175,3,33,N'ROTATOR:Rotators (often found in the oil, gas, and mining industries) commute to and from work a designated number of days in the host country, followed by a similar number of days off in the home country, on a cyclical basis. The rotator''s family remains in the home country.',1,17),
(3249,4,4,NULL,92491,1,20175,3,34,N'BUSINESS TRAVELER:Generally, a short-term business traveler travels away from his/her home work location to one specific location to work on a specific project for a period of less than one year. The short-term business traveler may make more than one trip in a single year. For example, John''s home work location is Miami, Florida. His employer sent him to Oslo, Norway from March 1 through May 31 to assist on a project. At the end of the three-month project John returned to his home work location in Miami, Florida. Later, John''s employer sent him to Caracas, Venezuela from September 1 through October 31 to work on another project. John is a short-term business traveler.',1,17),
(3250,4,1,7,92550,1,10506,3,170, N'Were these expenses borne by your employer?',0,2),
(3251,4,1,2,92551,1,10506,3,110, N'Insurance',0,6),
(3252,4,1,2,92552,1,10506,3,120, N'Furniture rental',0,6),
(3253,4,7,NULL,92554,1,11105,4,60, N'Mortgage',0,58),
(3254,4,1,7,92565,1,20175,3,31, N'Your employment situation in 2018/2019',0,2),
(3255,4,1,6,92573,1,20175,3,65,N'If the date of arrival in the host country for the assignment is different from the assignment start date as mentioned in the assignment letter, then please specify your date of arrival',0,5),
(3256,4,1,6,92574,1,20175,3,85,N'If your current assignment has ended and the date of departure is different than the assignment end date, then please specify your date of departure',0,5),
(3257,4,4,NULL,92576,1,92343,4,21, N'you have changed employment during the year',1,17),
(3258,4,4,NULL,92577,1,92343,4,22, N'you received compensation for a prior employment',1,17),
(3259,4,4,NULL,92579,1,92343,4,24, N'please complete the next section regarding employment income.',1,17),
(3260,4,1,13,92633,1,11152,5,90,N'If the amount paid from your tenant was a premium paid for a lease of two years or more (a "lease premium") or rent was received under the "rent a room" or "furnished holiday lettings" provisions, please indicate this. In the case of lease premiums, please state the amount paid for the lease and the term of the lease.',0,1),
(3261,4,1,3,92635,1,11416,6,30, N'Country where the mortgage loan was obtained/has been concluded',0,9),
(3262,4,4,NULL,92646,1,11416,6,122, N'Expenses',1,4),
(3263,4,1,5,92647,1,11416,6,123, N'Currency',0,12),
(3264,4,1,2,92648,1,11416,6,124, N'Mortgage interest paid',0,6),
(3265,4,1,10,92696,1,11416,6,680, N'Notes',0,14),
(3266,4,1,14,92780,1,20399,5,70,N'Does your compensation as reported by your employer accurately reflect your earnings (e.g., housing expenses, tax payments, home leave)?If No, please provide details on the Compensation/Remuneration Detail Page.',0,13),
(3267,4,1,9,92784,1,92358,3,10, N'Did your employment terminate during the year?',0,15),
(3268,4,1,10,92785,1,92358,3,20, N'Notes',0,14),
(3269,4,1,2,92796,1,10506,3,50, N'Annual rent paid to the landlord',0,6),
(3270,4,1,7,92962,1,11106,5,10, N'Ownership',0,2),
(3271,4,1,10,93011,1,20858,3,60, N'Notes',0,14),
(3272,4,1,10,93030,1,92458,3,30, N'Notes',0,14),
(3273,4,1,10,93058,1,91123,4,300, N'Notes',0,14),
(3274,4,1,7,93091,1,20185,5,120, N'Type of pension insurance/pension plan',0,2),
(3275,4,4,NULL,93114,1,11869,3,420,N'If you believe that there are other factors to be taken into account in preparing your Tax Return, or you have doubts about whether any item of income or gain should be reported on your Tax Return, please provide details in the Notes. We will prepare your Tax Return based on the information you have supplied in this questionnaire and, if appropriate, information supplied directly to us by your employer.',1,18),
(3276,4,1,10,93115,1,11869,3,430, N'Notes',0,14),
(3277,4,4,NULL,28924,1,10113,3,155,N'The Marriage Allowance allows you to transfer £1,190 of your Personal Allowance to your spouse. You are eligible for this benefit if you meet all of the following qualifications:You are either married or in a civil partnership; You do not pay income tax or your income is below your Personal Allowance (usually £11,850); Your spouse/partner pays income tax at the basic rate - usually means income is between £11,851 and £46,350 (£43,430 in Scotland). If you satisfy these conditions, please provide the following information:',1,17),
(3278,4,1,6,25490,1,10113,3,160,N'Spouse date of birth (e.g., 31 Dec 1980)',0,5),
(3279,4,1,13,28925,1,10113,3,215,N'Spouse/Civil Partner''s National Insurance number (NI), if known',0,1),
(3280,4,1,2,25277,1,20399,5,405, N'Total tax deducted per P60/P45',0,6),
(3281,4,1,7,28940,1,10506,3,15, N'Which Family members accompanied you on assignment?',0,2),
(3282,4,1,2,28941,1,10506,3,16, N'Number of accompanying children?',0,6),
(3283,4,1,2,24377,1,11507,4,100, N'Amount reimbursed by employer',0,6),
(3284,4,1,9,28918,1,10829,3,14, N'Did you receive interest income during 2018/2019?',0,15),
(3285,4,1,9,28919,1,20191,3,18, N'Did you receive dividend income during 2018/2019?',0,15),
(3286,4,1,7,28942,1,11869,3,223, N'Plan Type?',0,2),
(3287,4,1,6,28943,1,11869,3,227, N'Date of commencement of the course to which the Student Loan relates',0,5)

) AS Source ([Id], [OrganizerFormId], [OrganizerQuestionTypeId], [OrganizerReponseTypeId], [StaticCode], [IsActive], [ParentCode], [Level], [Sort], [Question], [IsReadOnly], [FormatNumber])    
ON Target.Id = Source.Id

WHEN MATCHED THEN
UPDATE SET 
	[OrganizerFormId] = Source.[OrganizerFormId],
	[OrganizerQuestionTypeId] = Source.[OrganizerQuestionTypeId], 
	StaticCode = Source.StaticCode,
	IsActive = Source.IsActive, 
	ParentCode = Source.ParentCode,
	[Level] = Source.[Level], 
	[Sort] = Source.[Sort],
	[Question] = Source.[Question], 
	[IsReadOnly] = Source.[IsReadOnly],
	[FormatNumber] =  Source.[FormatNumber]
		 
-- Insert new rows
WHEN NOT MATCHED BY TARGET THEN
INSERT ([Id], [OrganizerFormId], [OrganizerQuestionTypeId], [OrganizerReponseTypeId], [StaticCode], [IsActive], [ParentCode], [Level], [Sort], [Question], [IsReadOnly], [FormatNumber]) 
VALUES ([Id], [OrganizerFormId], [OrganizerQuestionTypeId], [OrganizerReponseTypeId], [StaticCode], [IsActive], [ParentCode], [Level], [Sort], [Question], [IsReadOnly], [FormatNumber]);

SET IDENTITY_INSERT [dbo].[OrganizerQuestion] OFF

--Ca.DataBase_Data_3.12.2_To_3.12.3

--Ca.DataBase_Data_3.12.3_To_3.13

PRINT 'Updating Currency data...';

MERGE INTO [dbo].[Currency] AS Target
USING (
VALUES 

(163, N'Saotome and Principe Dobra', N'STN')

) AS Source ([Id], [Name],[Code])
ON Target.Id = Source.Id

-- Update matched rows (except date)
WHEN MATCHED THEN
UPDATE SET 
	Name = Source.Name, 
	Code = Source.Code

-- Insert new rows
WHEN NOT MATCHED BY TARGET THEN
INSERT ([Id], [Name],[Code])
VALUES ([Id], [Name],[Code]);

PRINT 'Updating HmrcFxRate data...';

SET IDENTITY_INSERT [dbo].[HmrcFxRate]  ON

MERGE INTO [dbo].[HmrcFxRate] AS Target
USING (VALUES

--(432, 161, 13, 477.586458, GETDATE())
(433, 1, 14, 4.7986, GETDATE()),
(434, 3, 14, 143.31, GETDATE()),
(435, 4, 14, 636.98, GETDATE()),
(436, 6, 14, 409.83, GETDATE()),
(437, 7, 14, 52.93, GETDATE()),
(438, 8, 14, 1.8231, GETDATE()),
(439, 9, 14, 2.3385, GETDATE()),
(440, 11, 14, 2.2514, GETDATE()),
(441, 12, 14, 2.6128, GETDATE()),
(442, 13, 14, 109.91, GETDATE()),
(443, 14, 14, 2.2516, GETDATE()),
(444, 15, 14, 0.4925, GETDATE()),
(445, 16, 14, 2378.96, GETDATE()),
(446, 17, 14, 1.3064, GETDATE()),
(447, 18, 14, 1.7846, GETDATE()),
(448, 19, 14, 9.0273, GETDATE()),
(449, 20, 14, 4.853, GETDATE()),
(450, 21, 14, 1.3064, GETDATE()),
(451, 22, 14, 92.94, GETDATE()),
(452, 23, 14, 13.8, GETDATE()),
(453, 24, 14, 2.8, GETDATE()),
(454, 25, 14, 2.6112, GETDATE()),
(455, 26, 14, 1.7207, GETDATE()),
(456, 27, 14, 2129.43, GETDATE()),
(457, 28, 14, 1.3059, GETDATE()),
(458, 29, 14, 853.02, GETDATE()),
(459, 30, 14, 8.7848, GETDATE()),
(460, 31, 14, 4069.3, GETDATE()),
(461, 32, 14, 795.84, GETDATE()),
(462, 34, 14, 1.3064, GETDATE()),
(463, 35, 14, 127.53, GETDATE()),
(464, 36, 14, 29.53, GETDATE()),
(465, 37, 14, 232.17, GETDATE()),
(466, 38, 14, 8.5891, GETDATE()),
(467, 39, 14, 66.11, GETDATE()),
(468, 40, 14, 154.99, GETDATE()),
(469, 41, 14, 22.94, GETDATE()),
(470, 42, 14, 19.59, GETDATE()),
(471, 43, 14, 37.15, GETDATE()),
(472, 44, 14, 1.1511, GETDATE()),
(473, 45, 14, 2.7728, GETDATE()),
(474, 48, 14, 3.4711, GETDATE()),
(475, 52, 14, 65.32, GETDATE()),
(476, 53, 14, 11919.93, GETDATE()),
(477, 54, 14, 10.08, GETDATE()),
(478, 55, 14, 273.37, GETDATE()),
(479, 56, 14, 10.25, GETDATE()),
(480, 57, 14, 31.86, GETDATE()),
(481, 58, 14, 8.5357, GETDATE()),
(482, 59, 14, 108.61, GETDATE()),
(483, 60, 14, 364.93, GETDATE()),
(484, 61, 14, 18345.19, GETDATE()),
(485, 62, 14, 4.7142, GETDATE()),
(486, 64, 14, 92.94, GETDATE()),
(487, 65, 14, 1554.62, GETDATE()),
(488, 67, 14, 156.21, GETDATE()),
(489, 69, 14, 173.61, GETDATE()),
(490, 70, 14, 0.9259, GETDATE()),
(491, 71, 14, 144.7, GETDATE()),
(492, 72, 14, 131.09, GETDATE()),
(493, 73, 14, 91.12, GETDATE()),
(494, 74, 14, 5225.61, GETDATE()),
(495, 75, 14, 566.31, GETDATE()),
(496, 77, 14, 1467.87, GETDATE()),
(497, 78, 14, 0.3967, GETDATE()),
(498, 79, 14, 1.0713, GETDATE()),
(499, 80, 14, 493.83, GETDATE()),
(500, 81, 14, 11215.47, GETDATE()),
(501, 82, 14, 1970.31, GETDATE()),
(502, 83, 14, 234.75, GETDATE()),
(503, 84, 14, 1.3064, GETDATE()),
(504, 85, 14, 18.27, GETDATE()),
(505, 86, 14, 1.8094, GETDATE()),
(506, 87, 14, 12.43, GETDATE()),
(507, 88, 14, 22.38, GETDATE()),
(508, 89, 14, 4601.81, GETDATE()),
(509, 90, 14, 70.95, GETDATE()),
(510, 91, 14, 2014.86, GETDATE()),
(511, 92, 14, 3439.1, GETDATE()),
(512, 93, 14, 10.56, GETDATE()),
(513, 94, 14, 466.77, GETDATE()),
(514, 95, 14, 44.54, GETDATE()),
(515, 96, 14, 20.19, GETDATE()),
(516, 97, 14, 953.45, GETDATE()),
(517, 98, 14, 25.08, GETDATE()),
(518, 99, 14, 5.3131, GETDATE()),
(519, 102, 14, 472.91, GETDATE()),
(520, 103, 14, 42.52, GETDATE()),
(521, 104, 14, 11.22, GETDATE()),
(522, 105, 14, 148.71, GETDATE()),
(523, 106, 14, 1.9031, GETDATE()),
(524, 107, 14, 0.503, GETDATE()),
(525, 108, 14, 1.3064, GETDATE()),
(526, 109, 14, 4.332, GETDATE()),
(527, 110, 14, 4.4023, GETDATE()),
(528, 111, 14, 68.01, GETDATE()),
(529, 112, 14, 181.06, GETDATE()),
(530, 113, 14, 4.9917, GETDATE()),
(531, 114, 14, 7937.78, GETDATE()),
(532, 115, 14, 4.7566, GETDATE()),
(533, 118, 14, 85.78, GETDATE()),
(534, 119, 14, 1174.21, GETDATE()),
(535, 120, 14, 4.8995, GETDATE()),
(536, 121, 14, 10.43, GETDATE()),
(537, 122, 14, 18.2, GETDATE()),
(538, 123, 14, 62.23, GETDATE()),
(539, 124, 14, 12.16, GETDATE()),
(540, 125, 14, 1.7646, GETDATE()),
(541, 127, 14, 11222.02, GETDATE()),
(542, 128, 14, 759.02, GETDATE()),
(543, 130, 14, 9.7432, GETDATE()),
(544, 132, 14, 11.43, GETDATE()),
(545, 134, 14, 18.27, GETDATE()),
(546, 135, 14, 40.6, GETDATE()),
(547, 138, 14, 3.9864, GETDATE()),
(548, 139, 14, 2.9278, GETDATE()),
(549, 141, 14, 8.8332, GETDATE()),
(550, 143, 14, 40.26, GETDATE()),
(551, 144, 14, 3046.53, GETDATE()),
(552, 145, 14, 35.33, GETDATE()),
(553, 146, 14, 4794.5, GETDATE()),
(554, 147, 14, 1.3064, GETDATE()),
(555, 148, 14, 42.7, GETDATE()),
(556, 149, 14, 10963.61, GETDATE()),
(557, 151, 14, 30307.34, GETDATE()),
(558, 152, 14, 148.55, GETDATE()),
(559, 153, 14, 3.3688, GETDATE()),
(560, 154, 14, 755.08, GETDATE()),
(561, 155, 14, 3.5273, GETDATE()),
(562, 156, 14, 755.08, GETDATE()),
(563, 157, 14, 137.36, GETDATE()),
(564, 158, 14, 326.78, GETDATE()),
(565, 159, 14, 18.27, GETDATE()),
(566, 161, 14, 472.78, GETDATE()),
(567, 163, 14, 28251, GETDATE()),
(568, 10, 14, 2.2163, GETDATE()),
(569, 117, 14, 136.01, GETDATE()),
(570, 50, 14, 6.9076, GETDATE()),
(571, 100, 14, 81.91, GETDATE()),
(572, 116, 14, 5.4721, GETDATE()),
(573, 137, 14, 4.5855, GETDATE()),
(574, 140, 14, 6.9546, GETDATE()),
(575, 150, 14, 321045.54, GETDATE()),
(576, 160, 14, 15.57, GETDATE())

) AS Source ([Id], [CurrencyId], [TaxYearId], [Amount], [CreatedDate])
ON Target.Id = Source.Id

-- Update matched rows (except date)
WHEN MATCHED THEN
UPDATE SET 
	[CurrencyId] = Source.	[CurrencyId],
	TaxYearId = Source.TaxYearId,
	Amount = Source.Amount,
	CreatedDate = Source.CreatedDate 

-- Insert new rows
WHEN NOT MATCHED BY TARGET THEN
INSERT ([Id], [CurrencyId], [TaxYearId], [Amount], [CreatedDate])
VALUES ([Id], [CurrencyId], [TaxYearId], [Amount], [CreatedDate]);

SET IDENTITY_INSERT [dbo].[HmrcFxRate] OFF

--Ca.DataBase_Data_3.12.3_To_3.13

--Ca.DataBase_Data_3.13_To_3.13.1

PRINT 'Updating PensionForm data...';

--Add values to existing populations
UPDATE [dbo].[PensionForm]
SET [DefinedBenefitTaxableValue] = 0

--Ca.DataBase_Data_3.13_To_3.13.1

--Ca.DataBase_Data_3.13.1_To_3.13.2

PRINT N'Updating [dbo].[DdrAssigneeQuestion]...';

MERGE INTO [dbo].[DdrAssigneeQuestion] AS Target
USING (VALUES

(1, 1, 92796, N'Annual rent paid to the landlord', 1, 1, 0),
(2, 1, 20807, N'Council tax', 1, 2, 0),
(3, 1, 20808, N'Water rates', 1, 1, 0),
(4, 1, 20127, N'Utilities (e.g., gas, heating, electricity)', 1, 1, 0),
(5, 1, 92551, N'Insurance', 1, 1, 0),
(6, 1, 92552, N'Furniture rental', 1, 1, 0),
(7, 1, 20809, N'Travel', 1, 3, 0),
(8, 1, 20810, N'Meals', 1, 3, 0),
(9, 1, 20134, N'Other', 1, 3, 0),
(10, 1, 20133, N'Other description', 2, NULL, 1),
(11, 1, 23373, N'If different, annual rent paid by you (and not reimbursed by your employer)', 2, NULL, 0),
(12, 1, 92550, N'Were these expenses borne by your employer?', 2, NULL, 0),
(13, 2, 92796, N'Annual rent paid to the landlord', 1, 1, 0),
(14, 2, 20807, N'Council tax', 1, 2, 0),
(15, 2, 20808, N'Water rates', 1, 1, 0),
(16, 2, 20127, N'Utilities (e.g., gas, heating, electricity)', 1, 1, 0),
(17, 2, 92551, N'Insurance', 1, 1, 0),
(18, 2, 92552, N'Furniture rental', 1, 1, 0),
(19, 2, 20809, N'Travel', 1, 3, 0),
(20, 2, 20810, N'Meals', 1, 3, 0),
(21, 2, 20134, N'Other', 1, 3, 0),
(22, 2, 20133, N'Other description', 2, NULL, 1),
(23, 2, 23373, N'If different, annual rent paid by you (and not reimbursed by your employer)', 2, NULL, 0),
(24, 2, 92550, N'Were these expenses borne by your employer?', 2, NULL, 0),
(25, 13, 92796, N'Annual rent paid to the landlord', 1, 1, 0),
(26, 13, 20807, N'Council tax', 1, 2, 0),
(27, 13, 20808, N'Water rates', 1, 1, 0),
(28, 13, 20127, N'Utilities (e.g., gas, heating, electricity)', 1, 1, 0),
(29, 13, 92551, N'Insurance', 1, 1, 0),
(30, 13, 92552, N'Furniture rental', 1, 1, 0),
(31, 13, 20809, N'Travel', 1, 3, 0),
(32, 13, 20810, N'Meals', 1, 3, 0),
(33, 13, 20134, N'Other', 1, 3, 0),
(34, 13, 20133, N'Other description', 2, NULL, 1),
(35, 13, 23373, N'If different, annual rent paid by you (and not reimbursed by your employer)', 2, NULL, 0),
(36, 13, 92550, N'Were these expenses borne by your employer?', 2, NULL, 0),
(37, 14, 92796, N'Annual rent paid to the landlord', 1, 1, 0),
(38, 14, 20807, N'Council tax', 1, 2, 0),
(39, 14, 20808, N'Water rates', 1, 1, 0),
(40, 14, 20127, N'Utilities (e.g., gas, heating, electricity)', 1, 1, 0),
(41, 14, 92551, N'Insurance', 1, 1, 0),
(42, 14, 92552, N'Furniture rental', 1, 1, 0),
(43, 14, 20809, N'Travel', 1, 3, 0),
(44, 14, 20810, N'Meals', 1, 3, 0),
(45, 14, 20134, N'Other', 1, 3, 0),
(46, 14, 20133, N'Other description', 2, NULL, 1),
(47, 14, 23373, N'If different, annual rent paid by you (and not reimbursed by your employer)', 2, NULL, 0),
(48, 14, 92550, N'Were these expenses borne by your employer?', 2, NULL, 0)

) AS Source ([Id], [TaxYearId], [OrganizerStaticCode], [Text], [DdrAssigneeQuestionTypeId], [DdrReductionTypeId], [Hidden])
ON Target.Id = Source.Id

-- Update matched rows (except date)
WHEN MATCHED THEN
UPDATE SET 
	[TaxYearId] = Source.[TaxYearId],
	[OrganizerStaticCode] = Source.[OrganizerStaticCode],
	[DdrAssigneeQuestionTypeId] = Source.[DdrAssigneeQuestionTypeId],
	[DdrReductionTypeId] = Source.[DdrReductionTypeId],
	[Hidden] = Source.[Hidden]

-- Insert new rows
WHEN NOT MATCHED BY TARGET THEN
INSERT ([Id], [TaxYearId], [OrganizerStaticCode], [Text], [DdrAssigneeQuestionTypeId], [DdrReductionTypeId], [Hidden])
VALUES ([Id], [TaxYearId], [OrganizerStaticCode], [Text], [DdrAssigneeQuestionTypeId], [DdrReductionTypeId], [Hidden])

-- Delete missing rows
WHEN NOT MATCHED BY SOURCE THEN
DELETE;

--Ca.DataBase_Data_3.13.1_To_3.13.2

--Ca.DataBase_Data_3.13.2_To_3.13.3

PRINT N'Updating [dbo].[Country]...';

MERGE INTO [dbo].[Country] AS Target
USING (VALUES

(1, 'AF', N'Afghanistan', 'AFG'),
(2, 'AX', N'Aland Islands', 'ALA'),
(3, 'AL', N'Albania', 'ALB'),
(4, 'DZ', N'Algeria', 'DZA'),
(5, 'AS', N'American Samoa', 'ASM'),
(6, 'AD', N'Andorra', 'AND'),
(7, 'AI', N'Anguilla', 'AIA'),
(8, 'AG', N'Antigua & Barbuda', 'ATG'),
(9, 'AR', N'Argentina', 'ARG'),
(10, 'AM', N'Armenia', 'ARM'),
(11, 'AW', N'Aruba', 'ABW'),
(12, 'AU', N'Australia', 'AUS'),
(13, 'AT', N'Austria', 'AUT'),
(14, 'AZ', N'Azerbaijan', 'AZE'),
(15, 'BS', N'Bahamas', 'BHS'),
(16, 'BH', N'Bahrain', 'BHR'),
(17, 'BD', N'Bangladesh', 'BGD'),
(18, 'BB', N'Barbados', 'BRB'),
(19, 'BY', N'Belarus', 'BLR'),
(20, 'BE', N'Belgium', 'BEL'),
(21, 'BZ', N'Belize', 'BLZ'),
(22, 'BJ', N'Benin', 'BEN'),
(23, 'BM', N'Bermuda', 'BMU'),
(24, 'BT', N'Bhutan', 'BTN'),
(25, 'BO', N'Bolivia', 'BOL'),
(26, 'BA', N'Bosnia & H''govina', 'BIH'),
(27, 'BW', N'Botswana', 'BWA'),
(28, 'BV', N'Bouvet Island', 'BVT'),
(29, 'BR', N'Brazil', 'BRA'),
(30, 'IO', N'Br Indian Ocean Tr''', 'IOT'),
(31, 'BN', N'Brunei Darussalam''', 'BRN'),
(32, 'BG', N'Bulgaria', 'BGR'),
(33, 'BF', N'Burkina Faso', 'BFA'),
(34, 'BI', N'Burundi', 'BDI'),
(35, 'KH', N'Cambodia', 'KHM'),
(36, 'CM', N'Cameroon', 'CMR'),
(37, 'CA', N'Canada', 'CAN'),
(38, 'CV', N'Cape Verde', 'CPV'),
(39, 'KY', N'Cayman Islands', 'CYM'),
(40, 'CF', N'Cen African Rep', 'CAF'),
(41, 'TD', N'Chad', 'TCD'),
(42, 'CL', N'Chile', 'CHL'),
(43, 'CN', N'China', 'CHN'),
(44, 'CX', N'Christmas Island', 'CXR'),
(45, 'CC', N'Cocos Islands', 'CCK'),
(46, 'CO', N'Colombia', 'COL'),
(47, 'KM', N'Comoros', 'COM'),
(48, 'CG', N'Congo', 'COG'),
(49, 'CK', N'Cook Islands', 'COK'),
(50, 'CR', N'Costa Rica', 'CRI'),
(51, 'CI', N'Cote D''Ivoire', 'CIV'),
(52, 'HR', N'Croatia', 'HRV'),
(53, 'CU', N'Cuba', 'CUB'),
(54, 'CY', N'Cyprus', 'CYP'),
(55, 'CZ', N'Czech Republic', 'CZE'),
(56, 'DK', N'Denmark', 'DNK'),
(57, 'DJ', N'Djibouti', 'DJI'),
(58, 'DM', N'Dominica', 'DMA'),
(59, 'DO', N'Dominican Republic', 'DOM'),
(60, 'EC', N'Ecuador', 'ECU'),
(61, 'EG', N'Egypt', 'EGY'),
(62, 'SV', N'El Salvador', 'SLV'),
(63, 'GQ', N'Equatorial Guinea', 'GNQ'),
(64, 'ER', N'Eritrea', 'ERI'),
(65, 'EE', N'Estonia', 'EST'),
(66, 'ET', N'Ethiopia', 'ETH'),
(67, 'FK', N'Falkland Islands', 'FLK'),
(68, 'FO', N'Faroe Islands', 'FRO'),
(69, 'FJ', N'Fiji', 'FJI'),
(70, 'FI', N'Finland', 'FIN'),
(71, 'FR', N'France', 'FRA'),
(72, 'GF', N'French Guiana', 'GUF'),
(73, 'PF', N'French Polynesia', 'PYF'),
(74, 'TF', N'French S.Territory', 'ATF'),
(75, 'GA', N'Gabon', 'GAB'),
(76, 'GM', N'Gambia', 'GMB'),
(77, 'GE', N'Georgia', 'GEO'),
(78, 'DE', N'Germany', 'DEU'),
(79, 'GH', N'Ghana', 'GHA'),
(80, 'GI', N'Gibraltar', 'GIB'),
(81, 'GR', N'Greece', 'GRC'),
(82, 'GL', N'Greenland', 'GRL'),
(83, 'GD', N'Grenada', 'GRD'),
(84, 'GP', N'Guadeloupe', 'GLP'),
(85, 'GU', N'Guam', 'GUM'),
(86, 'GT', N'Guatemala', 'GTM'),
(87, 'GG', N'Guernsey', 'GGY'),
(88, 'GN', N'Guinea', 'GIN'),
(89, 'GW', N'Guinea-Bissau', 'GNB'),
(90, 'GY', N'Guyana', 'GUY'),
(91, 'HT', N'Haiti', 'HTI'),
(92, 'HM', N'Heard & McDonald', 'HMD'),
(93, 'VA', N'Vatican City', 'VAT'),
(94, 'HN', N'Honduras', 'HND'),
(95, 'HK', N'Hong Kong', 'HKG'),
(96, 'HU', N'Hungary', 'HUN'),
(97, 'IS', N'Iceland', 'ISL'),
(98, 'IN', N'India', 'IND'),
(99, 'ID', N'Indonesia', 'IDN'),
(100, 'IR', N'Iran', 'IRN'),
(101, 'IQ', N'Iraq', 'IRQ'),
(102, 'IE', N'Ireland', 'IRL'),
(103, 'IM', N'Isle Of Man', 'IMN'),
(104, 'IL', N'Israel', 'ISR'),
(105, 'IT', N'Italy', 'ITA'),
(106, 'JM', N'Jamaica', 'JAM'),
(107, 'JP', N'Japan', 'JPN'),
(108, 'JE', N'Jersey', 'JEY'),
(109, 'JO', N'Jordan', 'JOR'),
(110, 'KZ', N'Kazakhstan', 'KAZ'),
(111, 'KE', N'Kenya', 'KEN'),
(112, 'KI', N'Kiribati', 'KIR'),
(113, 'KP', N'North Korea', 'PRK'),
(114, 'KR', N'South Korea', 'KOR'),
(115, 'KW', N'Kuwait', 'KWT'),
(116, 'KG', N'Kyrgyzstan', 'KGZ'),
(117, 'LA', N'Laos', 'LAO'),
(118, 'LV', N'Latvia', 'LVA'),
(119, 'LB', N'Lebanon', 'LBN'),
(120, 'LS', N'Lesotho', 'LSO'),
(121, 'LR', N'Liberia', 'LBR'),
(122, 'LY', N'Libya', 'LBY'),
(123, 'LI', N'Liechtenstein', 'LIE'),
(124, 'LT', N'Lithuania', 'LTU'),
(125, 'LU', N'Luxembourg', 'LUX'),
(126, 'MO', N'Macao', 'MAC'),
(127, 'MK', N'Macedonia, F.Y.R.O', 'MKD'),
(128, 'MG', N'Madagascar', 'MDG'),
(129, 'MW', N'Malawi', 'MWI'),
(130, 'MY', N'Malaysia', 'MYS'),
(131, 'MV', N'Maldives', 'MDV'),
(132, 'ML', N'Mali', 'MLI'),
(133, 'MT', N'Malta', 'MLT'),
(134, 'MH', N'Marshall Islands', 'MHL'),
(135, 'MQ', N'Martinique', 'MTQ'),
(136, 'MR', N'Mauritania', 'MRT'),
(137, 'MU', N'Mauritius', 'MUS'),
(138, 'YT', N'Mayotte', 'MYT'),
(139, 'MX', N'Mexico', 'MEX'),
(140, 'FM', N'Micronesia', 'FSM'),
(141, 'MD', N'Moldova', 'MDA'),
(142, 'MC', N'Monaco', 'MCO'),
(143, 'MN', N'Mongolia', 'MNG'),
(144, 'ME', N'Montenegro', 'MNE'),
(145, 'MS', N'Montserrat', 'MSR'),
(146, 'MA', N'Morocco', 'MAR'),
(147, 'MZ', N'Mozambique', 'MOZ'),
(148, 'MM', N'Myanmar', 'MMR'),
(149, 'NA', N'Namibia', 'NAM'),
(150, 'NR', N'Nauru', 'NRU'),
(151, 'NP', N'Nepal', 'NPL'),
(152, 'NL', N'Netherlands', 'NLD'),
(153, 'AN', N'Netherlands Antilles', 'ANT'),
(154, 'NC', N'New Caledonia', 'NCL'),
(155, 'NZ', N'New Zealand', 'NZL'),
(156, 'NI', N'Nicaragua', 'NIC'),
(157, 'NE', N'Niger', 'NER'),
(158, 'NG', N'Nigeria', 'NGA'),
(159, 'NU', N'Niue', 'NIU'),
(160, 'NF', N'Norfolk Island', 'NFK'),
(161, 'MP', N'N. Mariana Islands', 'MNP'),
(162, 'NO', N'Norway', 'NOR'),
(163, 'OM', N'Oman', 'OMN'),
(164, 'PK', N'Pakistan', 'PAK'),
(165, 'PW', N'Palau', 'PLW'),
(166, 'PS', N'Palestine', 'PSE'),
(167, 'PA', N'Panama', 'PAN'),
(168, 'PG', N'Papua New Guinea', 'PNG'),
(169, 'PY', N'Paraguay', 'PRY'),
(170, 'PE', N'Peru', 'PER'),
(171, 'PH', N'Philippines', 'PHL'),
(172, 'PN', N'Pitcairn', 'PCN'),
(173, 'PL', N'Poland', 'POL'),
(174, 'PT', N'Portugal', 'PRT'),
(175, 'PR', N'Puerto Rico', 'PRI'),
(176, 'QA', N'Qatar', 'QAT'),
(177, 'RE', N'Reunion', 'REU'),
(178, 'RO', N'Romania', 'ROU'),
(179, 'RU', N'Russian Federation', 'RUS'),
(180, 'RW', N'Rwanda', 'RWA'),
(181, 'SH', N'St Helena', 'SHN'),
(182, 'KN', N'St Kitts & Nevis', 'KNA'),
(183, 'LC', N'Saint Lucia', 'LCA'),
(184, 'PM', N'St Pierre & Miqu''n', 'SPM'),
(185, 'VC', N'St Vincent & Gren''', 'VCT'),
(186, 'WS', N'Samoa', 'WSM'),
(187, 'SM', N'San Marino', 'SMR'),
(188, 'ST', N'S. Tome & Principe', 'STP'),
(189, 'SA', N'Saudi Arabia', 'SAU'),
(190, 'SN', N'Senegal', 'SEN'),
(191, 'RS', N'Serbia', 'SRB'),
(192, 'SC', N'Seychelles', 'SYC'),
(193, 'SL', N'Sierra Leone', 'SLE'),
(194, 'SG', N'Singapore', 'SGP'),
(195, 'SK', N'Slovakia', 'SVK'),
(196, 'SI', N'Slovenia', 'SVN'),
(197, 'SB', N'Solomon Islands', 'SLB'),
(198, 'SO', N'Somalia', 'SOM'),
(199, 'ZA', N'South Africa', 'ZAF'),
(200, 'GS', N'South Georgia ', 'SGS'),
(201, 'ES', N'Spain', 'ESP'),
(202, 'LK', N'Sri Lanka', 'LKA'),
(203, 'SD', N'Sudan', 'SDN'),
(204, 'SR', N'Suriname', 'SUR'),
(205, 'SJ', N'Svalbard & J''Mayen', 'SJM'),
(206, 'SZ', N'Swaziland', 'SWZ'),
(207, 'SE', N'Sweden', 'SWE'),
(208, 'CH', N'Switzerland', 'CHE'),
(209, 'SY', N'Syria', 'SYR'),
(210, 'TW', N'Taiwan', 'TWN'),
(211, 'TJ', N'Tajikistan', 'TJK'),
(212, 'TZ', N'Tanzania', 'TZA'),
(213, 'TH', N'Thailand', 'THA'),
(214, 'TL', N'Timor-Leste', 'TLS'),
(215, 'TG', N'Togo', 'TGO'),
(216, 'TK', N'Tokelau', 'TKL'),
(217, 'TO', N'Tonga', 'TON'),
(218, 'TT', N'Trinidad & Tobago', 'TTO'),
(219, 'TN', N'Tunisia', 'TUN'),
(220, 'TR', N'Turkey', 'TUR'),
(221, 'TM', N'Turkmenistan', 'TKM'),
(222, 'TC', N'Turks & Caicos Is', 'TCA'),
(223, 'TV', N'Tuvalu', 'TUV'),
(224, 'UG', N'Uganda', 'UGA'),
(225, 'UA', N'Ukraine', 'UKR'),
(226, 'AE', N'UAE', 'ARE'),
(227, 'GB', N'United Kingdom', 'GBR'),
(228, 'US', N'United States', 'USA'),
(229, 'UM', N'US Minor Outl''g Is', 'UMI'),
(230, 'UY', N'Uruguay', 'URY'),
(231, 'UZ', N'Uzbekistan', 'UZB'),
(232, 'VU', N'Vanuatu', 'VUT'),
(233, 'VE', N'Venezuela', 'VEN'),
(234, 'VN', N'Vietnam', 'VNM'),
(235, 'VG', N'Virgin Is, British', 'VGB'),
(236, 'VI', N'Virgin Is, US', 'VIR'),
(237, 'WF', N'Wallis And Futuna', 'WLF'),
(238, 'EH', N'Western Sahara', 'ESH'),
(239, 'YE', N'Yemen', 'YEM'),
(240, 'ZM', N'Zambia', 'ZMB'),
(241, 'ZW', N'Zimbabwe', 'ZWE'),
(242, 'AO', N'Angola', 'AGO'),
(243, 'KV', N'Kosovo', 'XKX'),
(244, 'CW', N'Curacao', 'CUW'),
(245, 'AQ', N'Antarctica', 'ATA'),
(246, 'CD', N'DR Congo', 'COD'),
(247, 'BL', N'Saint-Barthélemy', 'BLM'),
(248, 'MF', N'Saint-Martin (French part)', 'MAF'),
(249, 'SS', N'South Sudan', 'SSD'),
(250, 'IW', N'International Waters', NULL),
(251, 'CS', N'Serbia and Montenegro', 'SCG'),
(252, 'BQ', N'Bonaire', 'BES'),
(253, 'XK', N'Kosovo', 'XKX')

) AS Source ([Id], [Code], [Name], [HMRC3LetterCode])
ON Target.Id = Source.Id

-- Update matched rows (except date)
WHEN MATCHED THEN
UPDATE SET 
	Code = Source.Code,
	Name = Source.Name,
	HMRC3LetterCode = Source.HMRC3LetterCode

-- Insert new rows
WHEN NOT MATCHED BY TARGET THEN
INSERT ([Id], [Code], [Name], [HMRC3LetterCode])
VALUES ([Id], [Code], [Name], [HMRC3LetterCode])

-- Delete missing rows
WHEN NOT MATCHED BY SOURCE THEN
DELETE;

--Ca.DataBase_Data_3.13.2_To_3.13.3

--Ca.DataBase_Data_3.13.3_To_3.13.4

PRINT N'Updating [dbo].[FamilyAccompaniment]...';

MERGE INTO [dbo].[FamilyAccompaniment] AS Target
USING (VALUES

(1, N'Unaccompanied', 0),
(2, N'Spouse', 0),
(3, N'Spouse with Children', 1),
(4, N'Children', 1)

) AS Source ([Id], [Name], [ChildrenRequired])
ON Target.Id = Source.Id

-- Update matched rows (except date)
WHEN MATCHED THEN
UPDATE SET 
	Name = Source.Name,
	ChildrenRequired = Source.ChildrenRequired

-- Insert new rows
WHEN NOT MATCHED BY TARGET THEN
INSERT ([Id], [Name], [ChildrenRequired])
VALUES ([Id], [Name], [ChildrenRequired])

-- Delete missing rows
WHEN NOT MATCHED BY SOURCE THEN
DELETE;

--Ca.DataBase_Data_3.13.3_To_3.13.4

/*************************** Data script end **************************/


PRINT N'Data update complete.'


DECLARE @VersionName varchar(50) = 'Data'
DECLARE @Version varchar(50) = '3.13'

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