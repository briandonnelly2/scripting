
/*
Compensation Anaylser UAT data update script from releases 3.15 to release 3.15.1
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
DECLARE @ToVersion varchar(50) = '3.15.1'
DECLARE @CurrentVersion varchar(50) = (SELECT [Version] FROM [dbo].[Version] WHERE [Key] = @VersionKey)

IF (@CurrentVersion IS NOT NULL AND @CurrentVersion NOT IN ('3.15') AND @CurrentVersion <> @ToVersion)
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

--Ca.DataBase_Data_3.15_To_3.15.1

PRINT N'Updating [dbo].[UsFtcLabel]...';

MERGE INTO [dbo].[UsFtcLabel] AS Target
USING (VALUES

(1, N'Balance of US Federal Tax per form 1040 (line 44 minus lines 48-53)'),
(2, N'(Do not subtract AMT credit from form 8801, form 1040 line 54)')

) AS Source ([Id], [Text])
ON Target.Id = Source.Id

-- Update matched rows
WHEN MATCHED THEN
UPDATE SET 
	[Text] = Source.[Text]

-- Insert new rows
WHEN NOT MATCHED BY TARGET THEN
INSERT ([Id], [Text])
VALUES ([Id], [Text])

-- Delete missing rows
WHEN NOT MATCHED BY SOURCE THEN
DELETE;



PRINT N'Updating [dbo].[HmrcFxRate]...';

SET IDENTITY_INSERT [dbo].[HmrcFxRate]  ON

MERGE INTO [dbo].[HmrcFxRate] AS Target
USING (VALUES

 (433, 1, 14, 4.848117, GETDATE()),
(434, 3, 14, 142.6475, GETDATE()),
(435, 4, 14, 637.659167, GETDATE()),
(436, 6, 14, 358.4575, GETDATE()),
(437, 7, 14, 41.434542, GETDATE()),
(438, 8, 14, 1.795092, GETDATE()),
(439, 9, 14, 2.362617, GETDATE()),
(440, 11, 14, 2.215933, GETDATE()),
(441, 12, 14, 2.639783, GETDATE()),
(442, 13, 14, 110.600833, GETDATE()),
(443, 14, 14, 2.215967, GETDATE()),
(444, 15, 14, 0.4978, GETDATE()),
(445, 16, 14, 2367.751667, GETDATE()),
(446, 17, 14, 1.319892, GETDATE()),
(447, 18, 14, 1.789833, GETDATE()),
(448, 19, 14, 9.120467, GETDATE()),
(449, 20, 14, 4.944692, GETDATE()),
(450, 21, 14, 1.319892, GETDATE()),
(451, 22, 14, 91.846667, GETDATE()),
(452, 23, 14, 13.646925, GETDATE()),
(453, 24, 14, 2.721175, GETDATE()),
(454, 25, 14, 2.638142, GETDATE()),
(455, 26, 14, 1.728133, GETDATE()),
(456, 27, 14, 2138.955833, GETDATE()),
(457, 28, 14, 1.302, GETDATE()),
(458, 29, 14, 863.108333, GETDATE()),
(459, 30, 14, 8.808783, GETDATE()),
(460, 31, 14, 3958.056667, GETDATE()),
(461, 32, 14, 766.96, GETDATE()),
(462, 34, 14, 1.319892, GETDATE()),
(463, 35, 14, 125.289167, GETDATE()),
(464, 36, 14, 29.111667, GETDATE()),
(465, 37, 14, 234.565833, GETDATE()),
(466, 38, 14, 8.449217, GETDATE()),
(467, 39, 14, 65.701667, GETDATE()),
(468, 40, 14, 155.033333, GETDATE()),
(469, 41, 14, 23.5325, GETDATE()),
(470, 42, 14, 19.793333, GETDATE()),
(471, 43, 14, 36.584167, GETDATE()),
(472, 44, 14, 1.132983, GETDATE()),
(473, 45, 14, 2.765633, GETDATE()),
(474, 48, 14, 3.380358, GETDATE()),
(475, 52, 14, 64.351667, GETDATE()),
(476, 53, 14, 11955.29083, GETDATE()),
(477, 54, 14, 10.07415, GETDATE()),
(478, 55, 14, 275.079167, GETDATE()),
(479, 56, 14, 10.349583, GETDATE()),
(480, 57, 14, 31.7275, GETDATE()),
(481, 58, 14, 8.403867, GETDATE()),
(482, 59, 14, 93.466067, GETDATE()),
(483, 60, 14, 362.254167, GETDATE()),
(484, 61, 14, 18905.83083, GETDATE()),
(485, 62, 14, 4.783058, GETDATE()),
(486, 64, 14, 91.846667, GETDATE()),
(487, 65, 14, 1501.203333, GETDATE()),
(488, 67, 14, 147.640833, GETDATE()),
(489, 69, 14, 171.441667, GETDATE()),
(490, 70, 14, 0.936617, GETDATE()),
(491, 71, 14, 145.915, GETDATE()),
(492, 72, 14, 133.354167, GETDATE()),
(493, 73, 14, 91.198333, GETDATE()),
(494, 74, 14, 5336.055833, GETDATE()),
(495, 75, 14, 557.3875, GETDATE()),
(496, 77, 14, 1465.995, GETDATE()),
(497, 78, 14, 0.399475, GETDATE()),
(498, 79, 14, 1.082308, GETDATE()),
(499, 80, 14, 466.338333, GETDATE()),
(500, 81, 14, 11175.88417, GETDATE()),
(501, 82, 14, 1995.086667, GETDATE()),
(502, 83, 14, 220.923333, GETDATE()),
(503, 84, 14, 1.319892, GETDATE()),
(504, 85, 14, 17.850833, GETDATE()),
(505, 86, 14, 1.8114, GETDATE()),
(506, 87, 14, 12.4575, GETDATE()),
(507, 88, 14, 22.28, GETDATE()),
(508, 89, 14, 4488.0575, GETDATE()),
(509, 90, 14, 69.740833, GETDATE()),
(510, 91, 14, 1949.66, GETDATE()),
(511, 92, 14, 3311.475833, GETDATE()),
(512, 93, 14, 10.659167, GETDATE()),
(513, 94, 14, 470.811667, GETDATE()),
(514, 95, 14, 45.18, GETDATE()),
(515, 96, 14, 20.386667, GETDATE()),
(516, 97, 14, 960.068333, GETDATE()),
(517, 98, 14, 25.420833, GETDATE()),
(518, 99, 14, 5.368717, GETDATE()),
(519, 102, 14, 477.175, GETDATE()),
(520, 103, 14, 41.9925, GETDATE()),
(521, 104, 14, 10.894167, GETDATE()),
(522, 105, 14, 146.9575, GETDATE()),
(523, 106, 14, 1.925333, GETDATE()),
(524, 107, 14, 0.508133, GETDATE()),
(525, 108, 14, 1.319892, GETDATE()),
(526, 109, 14, 4.354525, GETDATE()),
(527, 110, 14, 4.374908, GETDATE()),
(528, 111, 14, 69.8275, GETDATE()),
(529, 112, 14, 167.225833, GETDATE()),
(530, 113, 14, 4.855567, GETDATE()),
(531, 114, 14, 7676.394167, GETDATE()),
(532, 115, 14, 4.805792, GETDATE()),
(533, 118, 14, 84.786667, GETDATE()),
(534, 119, 14, 1162.525, GETDATE()),
(535, 120, 14, 4.950583, GETDATE()),
(536, 121, 14, 10.396667, GETDATE()),
(537, 122, 14, 18.2525, GETDATE()),
(538, 123, 14, 39.674167, GETDATE()),
(539, 124, 14, 11.714167, GETDATE()),
(540, 125, 14, 1.788167, GETDATE()),
(541, 127, 14, 10797.69667, GETDATE()),
(542, 128, 14, 764.484167, GETDATE()),
(543, 130, 14, 9.847992, GETDATE()),
(544, 132, 14, 11.545833, GETDATE()),
(545, 134, 14, 17.850833, GETDATE()),
(546, 135, 14, 42.57, GETDATE()),
(547, 138, 14, 3.612325, GETDATE()),
(548, 139, 14, 1.88715, GETDATE()),
(549, 141, 14, 8.906358, GETDATE()),
(550, 143, 14, 40.125833, GETDATE()),
(551, 144, 14, 3023.423333, GETDATE()),
(552, 145, 14, 35.79, GETDATE()),
(553, 146, 14, 4927.553333, GETDATE()),
(554, 147, 14, 1.319892, GETDATE()),
(555, 148, 14, 41.600833, GETDATE()),
(556, 149, 14, 10703.90167, GETDATE()),
(557, 151, 14, 30484.0975, GETDATE()),
(558, 152, 14, 147.9225, GETDATE()),
(559, 153, 14, 3.393825, GETDATE()),
(560, 154, 14, 743.184167, GETDATE()),
(561, 155, 14, 3.5637, GETDATE()),
(562, 156, 14, 743.184167, GETDATE()),
(563, 157, 14, 135.195833, GETDATE()),
(564, 158, 14, 330.29, GETDATE()),
(565, 159, 14, 17.850833, GETDATE()),
(566, 161, 14, 477.663333, GETDATE()),
(567, 163, 14, 27778.32167, GETDATE()),
(568, 10, 14, 2.24215, GETDATE()),
(569, 117, 14, 133.96, GETDATE()),
(570, 50, 14, 6.324283, GETDATE()),
(571, 100, 14, 80.041667, GETDATE()),
(572, 116, 14, 5.2947, GETDATE()),
(573, 137, 14, 4.625608, GETDATE()),
(574, 140, 14, 6.743333, GETDATE()),
(575, 150, 14, 225552.1842, GETDATE()),
(576, 160, 14, 14.2625, GETDATE())

) AS Source ([Id], [CurrencyId], [TaxYearId], [Amount], [CreatedDate])
ON Target.Id = Source.Id

-- Update matched rows (except date)
WHEN MATCHED THEN
UPDATE SET 
	[CurrencyId] = Source.[CurrencyId],
	TaxYearId = Source.TaxYearId,
	Amount = Source.Amount,
	CreatedDate = Source.CreatedDate 

-- Insert new rows
WHEN NOT MATCHED BY TARGET THEN
INSERT ([Id], [CurrencyId], [TaxYearId], [Amount], [CreatedDate])
VALUES ([Id], [CurrencyId], [TaxYearId], [Amount], [CreatedDate]);

SET IDENTITY_INSERT [dbo].[HmrcFxRate] OFF

--Ca.DataBase_Data_3.15_To_3.15.1

/*************************** Data script end **************************/


PRINT N'Data update complete.'


DECLARE @VersionName varchar(50) = 'Data'
DECLARE @Version varchar(50) = '3.15.1'

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