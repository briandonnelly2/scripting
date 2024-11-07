/*
Ca data update script from release 2.13 to release 2.14

*/
set noexec off

GO
SET ANSI_NULLS, ANSI_PADDING, ANSI_WARNINGS, ARITHABORT, CONCAT_NULL_YIELDS_NULL, QUOTED_IDENTIFIER ON;

SET NUMERIC_ROUNDABORT OFF;

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
DECLARE @FromVersion varchar(50) = '2.14'
DECLARE @ToVersion varchar(50) = '3.13'
DECLARE @CurrentVersion varchar(50) = (SELECT [Version] FROM [dbo].[Version] WHERE [Key] = @VersionKey)

IF (@CurrentVersion <> @FromVersion)
BEGIN
	PRINT N'The current version of ' + @CurrentVersion + N' does not match the required version of ' + @FromVersion + N' for this script to execute.'
	set noexec on
	-- Nothing will execute from now on...
END

GO

BEGIN TRANSACTION;

SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

SET XACT_ABORT ON;

BEGIN TRY

/*------------------------------------------------------- Schema Script Start */

PRINT N'Updating [dbo].[Country]...'

SET IDENTITY_INSERT [dbo].[Country]  ON

MERGE INTO [dbo].[Country] AS Target
USING (VALUES

(1, 'AF', 'AFG', N'Afghanistan', NULL, 0, 0, 0, 0, 0, 0),
(2, 'AX', 'ALA', N'Aland Islands', NULL, 1, 1, 1, 1, 0, 0),
(3, 'AL', 'ALB', N'Albania', NULL, 0, 0, 0, 0, 0, 0),
(4, 'DZ', 'DZA', N'Algeria', NULL, 0, 1, 1, 1, 0, 0),
(5, 'AS', 'ASM', N'American Samoa', NULL, 1, 1, 1, 1, 0, 0),
(6, 'AD', 'AND', N'Andorra', NULL, 0, 0, 0, 0, 0, 0),
(7, 'AI', 'AIA', N'Anguilla', NULL, 0, 0, 0, 1, 0, 0),
(8, 'AG', 'ATG', N'Antigua & Barbuda', NULL, 0, 0, 0, 0, 0, 0),
(9, 'AR', 'ARG', N'Argentina', NULL, 1, 0, 0, 1, 0, 0),
(10, 'AM', 'ARM', N'Armenia', NULL, 1, 1, 1, 1, 0, 0),
(11, 'AW', 'ABW', N'Aruba', NULL, 1, 1, 1, 1, 0, 0),
(12, 'AU', 'AUS', N'Australia', NULL, 1, 1, 1, 0, 0, 0),
(13, 'AT', 'AUT', N'Austria', NULL, 1, 0, 0, 0, 1, 0),
(14, 'AZ', 'AZE', N'Azerbaijan', NULL, 0, 0, 0, 0, 0, 0),
(15, 'BS', 'BHS', N'Bahamas', NULL, 0, 0, 0, 0, 0, 0),
(16, 'BH', 'BHR', N'Bahrain', NULL, 0, 1, 1, 0, 0, 0),
(17, 'BD', 'BGD', N'Bangladesh', NULL, 0, 0, 0, 0, 0, 0),
(18, 'BB', 'BRB', N'Barbados', NULL, 0, 0, 0, 0, 0, 0),
(19, 'BY', 'BLR', N'Belarus', NULL, 0, 0, 0, 0, 0, 0),
(20, 'BE', 'BEL', N'Belgium', NULL, 1, 1, 0, 0, 1, 0),
(21, 'BZ', 'BLZ', N'Belize', NULL, 0, 0, 0, 0, 0, 0),
(22, 'BJ', 'BEN', N'Benin', NULL, 0, 0, 0, 0, 0, 0),
(23, 'BM', 'BMU', N'Bermuda', NULL, 1, 1, 1, 1, 0, 0),
(24, 'BT', 'BTN', N'Bhutan', NULL, 1, 1, 1, 1, 0, 0),
(25, 'BO', 'BOL', N'Bolivia', NULL, 0, 0, 0, 0, 0, 0),
(26, 'BA', 'BIH', N'Bosnia & H''govina', NULL, 0, 0, 0, 0, 0, 0),
(27, 'BW', 'BWA', N'Botswana', NULL, 0, 0, 0, 0, 0, 0),
(28, 'BV', 'BVT', N'Bouvet Island', NULL, 0, 0, 0, 0, 0, 0),
(29, 'BR', 'BRA', N'Brazil', NULL, 0, 0, 0, 0, 0, 0),
(30, 'IO', 'IOT', N'Br Indian Ocean Tr''', NULL, 0, 0, 0, 0, 0, 0),
(31, 'BN', 'BRN', N'Brunei Darussalam''', NULL, 0, 0, 0, 0, 0, 0),
(32, 'BG', 'BGR', N'Bulgaria', NULL, 1, 1, 0, 0, 0, 0),
(33, 'BF', 'BFA', N'Burkina Faso', NULL, 1, 1, 1, 1, 0, 0),
(34, 'BI', 'BDI', N'Burundi', NULL, 0, 0, 0, 0, 0, 0),
(35, 'KH', 'KHM', N'Cambodia', NULL, 0, 0, 0, 0, 0, 0),
(36, 'CM', 'CMR', N'Cameroon', NULL, 0, 0, 0, 0, 0, 0),
(37, 'CA', 'CAN', N'Canada', NULL, 0, 0, 0, 0, 0, 1),
(38, 'CV', 'CPV', N'Cape Verde', NULL, 0, 0, 0, 0, 0, 0),
(39, 'KY', 'CYM', N'Cayman Islands', NULL, 0, 0, 0, 0, 0, 0),
(40, 'CF', 'CAF', N'Cen African Rep', NULL, 0, 0, 0, 0, 0, 0),
(41, 'TD', 'TCD', N'Chad', NULL, 0, 0, 0, 0, 0, 0),
(42, 'CL', 'CHL', N'Chile', NULL, 0, 0, 0, 0, 0, 0),
(43, 'CN', 'CHN', N'China', NULL, 0, 0, 0, 0, 0, 0),
(44, 'CX', 'CXR', N'Christmas Island', NULL, 0, 0, 0, 0, 0, 0),
(45, 'CC', 'CCK', N'Cocos Islands', NULL, 0, 0, 0, 0, 0, 0),
(46, 'CO', 'COL', N'Colombia', NULL, 0, 0, 0, 0, 0, 0),
(47, 'KM', 'COM', N'Comoros', NULL, 0, 0, 0, 0, 0, 0),
(48, 'CG', 'COG', N'Congo', NULL, 0, 0, 0, 0, 0, 0),
(49, 'CK', 'COK', N'Cook Islands', NULL, 0, 0, 0, 0, 0, 0),
(50, 'CR', 'CRI', N'Costa Rica', NULL, 0, 0, 0, 0, 0, 0),
(51, 'CI', 'CIV', N'Cote D''Ivoire', NULL, 0, 0, 0, 0, 0, 0),
(52, 'HR', 'HRV', N'Croatia', NULL, 0, 0, 0, 0, 0, 0),
(53, 'CU', 'CUB', N'Cuba', NULL, 0, 0, 0, 0, 0, 0),
(54, 'CY', 'CYP', N'Cyprus', NULL, 1, 1, 0, 0, 0, 0),
(55, 'CZ', 'CZE', N'Czech Republic', NULL, 1, 1, 1, 0, 1, 0),
(56, 'DK', 'DNK', N'Denmark', NULL, 1, 1, 0, 0, 1, 0),
(57, 'DJ', 'DJI', N'Djibouti', NULL, 0, 0, 0, 0, 0, 0),
(58, 'DM', 'DMA', N'Dominica', NULL, 0, 0, 0, 0, 0, 0),
(59, 'DO', 'DOM', N'Dominican Republic', NULL, 0, 0, 0, 0, 0, 0),
(60, 'EC', 'ECU', N'Ecuador', NULL, 0, 0, 0, 0, 0, 0),
(61, 'EG', 'EGY', N'Egypt', NULL, 0, 0, 0, 0, 0, 0),
(62, 'SV', 'SLV', N'El Salvador', NULL, 1, 1, 1, 1, 0, 0),
(63, 'GQ', 'GNQ', N'Equatorial Guinea', NULL, 0, 0, 0, 0, 0, 0),
(64, 'ER', 'ERI', N'Eritrea', NULL, 0, 0, 0, 0, 0, 0),
(65, 'EE', 'EST', N'Estonia', NULL, 1, 1, 1, 0, 1, 0),
(66, 'ET', 'ETH', N'Ethiopia', NULL, 0, 0, 0, 0, 0, 0),
(67, 'FK', 'FLK', N'Falkland Islands', NULL, 0, 0, 0, 0, 0, 0),
(68, 'FO', 'FRO', N'Faroe Islands', NULL, 0, 0, 0, 0, 0, 0),
(69, 'FJ', 'FJI', N'Fiji', NULL, 0, 0, 0, 0, 0, 0),
(70, 'FI', 'FIN', N'Finland', NULL, 1, 1, 0, 0, 1, 0),
(71, 'FR', 'FRA', N'France', NULL, 1, 1, 0, 0, 1, 0),
(72, 'GF', 'GUF', N'French Guiana', NULL, 0, 0, 0, 0, 0, 0),
(73, 'PF', 'PYF', N'French Polynesia', NULL, 0, 0, 0, 0, 0, 0),
(74, 'TF', 'ATF', N'French S.Territory', NULL, 0, 0, 0, 0, 0, 0),
(75, 'GA', 'GAB', N'Gabon', NULL, 0, 0, 0, 0, 0, 0),
(76, 'GM', 'GMB', N'Gambia', NULL, 0, 0, 0, 0, 0, 0),
(77, 'GE', 'GEO', N'Georgia', NULL, 0, 0, 0, 0, 0, 0),
(78, 'DE', 'DEU', N'Germany', NULL, 1, 1, 0, 0, 1, 0),
(79, 'GH', 'GHA', N'Ghana', NULL, 0, 0, 0, 0, 0, 0),
(80, 'GI', 'GIB', N'Gibraltar', NULL, 0, 0, 0, 0, 0, 0),
(81, 'GR', 'GRC', N'Greece', NULL, 1, 1, 0, 0, 1, 0),
(82, 'GL', 'GRL', N'Greenland', NULL, 0, 0, 0, 0, 0, 0),
(83, 'GD', 'GRD', N'Grenada', NULL, 0, 0, 0, 0, 0, 0),
(84, 'GP', 'GLP', N'Guadeloupe', NULL, 0, 0, 0, 0, 0, 0),
(85, 'GU', 'GUM', N'Guam', NULL, 0, 0, 0, 0, 0, 0),
(86, 'GT', 'GTM', N'Guatemala', NULL, 0, 0, 0, 0, 0, 0),
(87, 'GG', 'GGY', N'Guernsey', NULL, 0, 0, 0, 0, 0, 0),
(88, 'GN', 'GIN', N'Guinea', NULL, 0, 0, 0, 0, 0, 0),
(89, 'GW', 'GNB', N'Guinea-Bissau', NULL, 0, 0, 0, 0, 0, 0),
(90, 'GY', 'GUY', N'Guyana', NULL, 0, 0, 0, 0, 0, 0),
(91, 'HT', 'HTI', N'Haiti', NULL, 0, 0, 0, 0, 0, 0),
(92, 'HM', 'HMD', N'Heard & McDonald', NULL, 0, 0, 0, 0, 0, 0),
(93, 'VA', 'VAT', N'Vatican City', NULL, 0, 0, 0, 0, 0, 0),
(94, 'HN', 'HND', N'Honduras', NULL, 0, 0, 0, 0, 0, 0),
(95, 'HK', 'HKG', N'Hong Kong', NULL, 0, 0, 0, 0, 0, 0),
(96, 'HU', 'HUN', N'Hungary', NULL, 1, 1, 1, 0, 1, 0),
(97, 'IS', 'ISL', N'Iceland', NULL, 1, 1, 0, 0, 1, 0),
(98, 'IN', 'IND', N'India', NULL, 0, 0, 0, 0, 0, 0),
(99, 'ID', 'IDN', N'Indonesia', NULL, 0, 0, 0, 0, 0, 0),
(100, 'IR', 'IRN', N'Iran', NULL, 0, 0, 0, 0, 0, 0),
(101, 'IQ', 'IRQ', N'Iraq', NULL, 0, 0, 0, 0, 0, 0),
(102, 'IE', 'IRL', N'Ireland', NULL, 1, 1, 0, 0, 0, 0),
(103, 'IM', 'IMN', N'Isle Of Man', NULL, 0, 0, 0, 0, 0, 0),
(104, 'IL', 'ISR', N'Israel', NULL, 0, 0, 0, 0, 0, 0),
(105, 'IT', 'ITA', N'Italy', NULL, 1, 1, 0, 0, 1, 0),
(106, 'JM', 'JAM', N'Jamaica', NULL, 0, 0, 0, 0, 0, 0),
(107, 'JP', 'JPN', N'Japan', NULL, 0, 0, 0, 0, 0, 0),
(108, 'JE', 'JEY', N'Jersey', NULL, 0, 0, 0, 0, 0, 0),
(109, 'JO', 'JOR', N'Jordan', NULL, 0, 0, 0, 0, 0, 0),
(110, 'KZ', 'KAZ', N'Kazakhstan', NULL, 0, 0, 0, 0, 0, 0),
(111, 'KE', 'KEN', N'Kenya', NULL, 0, 0, 0, 0, 0, 0),
(112, 'KI', 'KIR', N'Kiribati', NULL, 0, 0, 0, 0, 0, 0),
(113, 'KP', 'PRK', N'North Korea', NULL, 0, 0, 0, 0, 0, 0),
(114, 'KR', 'KOR', N'South Korea', NULL, 0, 0, 0, 0, 0, 0),
(115, 'KW', 'KWT', N'Kuwait', NULL, 0, 0, 0, 0, 0, 0),
(116, 'KG', 'KGZ', N'Kyrgyzstan', NULL, 0, 0, 0, 0, 0, 0),
(117, 'LA', 'LAO', N'Laos', NULL, 0, 0, 0, 0, 0, 0),
(118, 'LV', 'LVA', N'Latvia', NULL, 1, 1, 1, 0, 1, 0),
(119, 'LB', 'LBN', N'Lebanon', NULL, 0, 0, 0, 0, 0, 0),
(120, 'LS', 'LSO', N'Lesotho', NULL, 0, 0, 0, 0, 0, 0),
(121, 'LR', 'LBR', N'Liberia', NULL, 0, 0, 0, 0, 0, 0),
(122, 'LY', 'LBY', N'Libya', NULL, 0, 0, 0, 0, 0, 0),
(123, 'LI', 'LIE', N'Liechtenstein', NULL, 1, 1, 0, 0, 1, 0),
(124, 'LT', 'LTU', N'Lithuania', NULL, 1, 1, 1, 0, 1, 0),
(125, 'LU', 'LUX', N'Luxembourg', NULL, 1, 1, 0, 0, 1, 0),
(126, 'MO', 'MAC', N'Macao', NULL, 0, 0, 0, 0, 0, 0),
(127, 'MK', 'MKD', N'Macedonia, F.Y.R.O', NULL, 0, 0, 0, 0, 0, 0),
(128, 'MG', 'MDG', N'Madagascar', NULL, 0, 0, 0, 0, 0, 0),
(129, 'MW', 'MWI', N'Malawi', NULL, 0, 0, 0, 0, 0, 0),
(130, 'MY', 'MYS', N'Malaysia', NULL, 0, 0, 0, 0, 0, 0),
(131, 'MV', 'MDV', N'Maldives', NULL, 0, 0, 0, 0, 0, 0),
(132, 'ML', 'MLI', N'Mali', NULL, 0, 0, 0, 0, 0, 0),
(133, 'MT', 'MLT', N'Malta', NULL, 1, 1, 0, 0, 1, 0),
(134, 'MH', 'MHL', N'Marshall Islands', NULL, 0, 0, 0, 0, 0, 0),
(135, 'MQ', 'MTQ', N'Martinique', NULL, 0, 0, 0, 0, 0, 0),
(136, 'MR', 'MRT', N'Mauritania', NULL, 0, 0, 0, 0, 0, 0),
(137, 'MU', 'MUS', N'Mauritius', NULL, 0, 0, 0, 0, 0, 0),
(138, 'YT', 'MYT', N'Mayotte', NULL, 0, 0, 0, 0, 0, 0),
(139, 'MX', 'MEX', N'Mexico', NULL, 0, 0, 0, 0, 0, 0),
(140, 'FM', 'FSM', N'Micronesia', NULL, 0, 0, 0, 0, 0, 0),
(141, 'MD', 'MDA', N'Moldova', NULL, 0, 0, 0, 0, 0, 0),
(142, 'MC', 'MCO', N'Monaco', NULL, 0, 0, 0, 0, 0, 0),
(143, 'MN', 'MNG', N'Mongolia', NULL, 0, 0, 0, 0, 0, 0),
(144, 'ME', 'MNE', N'Montenegro', NULL, 0, 0, 0, 0, 0, 0),
(145, 'MS', 'MSR', N'Montserrat', NULL, 0, 0, 0, 0, 0, 0),
(146, 'MA', 'MAR', N'Morocco', NULL, 0, 0, 0, 0, 0, 0),
(147, 'MZ', 'MOZ', N'Mozambique', NULL, 0, 0, 0, 0, 0, 0),
(148, 'MM', 'MMR', N'Myanmar', NULL, 0, 0, 0, 0, 0, 0),
(149, 'NA', 'NAM', N'Namibia', NULL, 0, 0, 0, 0, 0, 0),
(150, 'NR', 'NRU', N'Nauru', NULL, 0, 0, 0, 0, 0, 0),
(151, 'NP', 'NPL', N'Nepal', NULL, 1, 0, 0, 1, 0, 0),
(152, 'NL', 'NLD', N'Netherlands', NULL, 1, 1, 1, 1, 1, 0),
(153, 'AN', 'ANT', N'Netherlands Antilles', NULL, 0, 0, 0, 0, 0, 0),
(154, 'NC', 'NCL', N'New Caledonia', NULL, 0, 0, 0, 0, 0, 0),
(155, 'NZ', 'NZL', N'New Zealand', NULL, 0, 0, 0, 0, 0, 0),
(156, 'NI', 'NIC', N'Nicaragua', NULL, 0, 0, 0, 0, 0, 0),
(157, 'NE', 'NER', N'Niger', NULL, 0, 0, 0, 0, 0, 0),
(158, 'NG', 'NGA', N'Nigeria', NULL, 0, 0, 0, 0, 0, 0),
(159, 'NU', 'NIU', N'Niue', NULL, 0, 0, 0, 0, 0, 0),
(160, 'NF', 'NFK', N'Norfolk Island', NULL, 0, 0, 0, 0, 0, 0),
(161, 'MP', 'MNP', N'N. Mariana Islands', NULL, 0, 0, 0, 0, 0, 0),
(162, 'NO', 'NOR', N'Norway', NULL, 1, 1, 0, 0, 1, 0),
(163, 'OM', 'OMN', N'Oman', NULL, 0, 0, 0, 0, 0, 0),
(164, 'PK', 'PAK', N'Pakistan', NULL, 0, 0, 0, 0, 0, 0),
(165, 'PW', 'PLW', N'Palau', NULL, 0, 0, 0, 0, 0, 0),
(166, 'PS', 'PSE', N'Palestine', NULL, 0, 0, 0, 0, 0, 0),
(167, 'PA', 'PAN', N'Panama', NULL, 0, 0, 0, 0, 0, 0),
(168, 'PG', 'PNG', N'Papua New Guinea', NULL, 0, 0, 0, 0, 0, 0),
(169, 'PY', 'PRY', N'Paraguay', NULL, 0, 0, 0, 0, 0, 0),
(170, 'PE', 'PER', N'Peru', NULL, 0, 0, 0, 0, 0, 0),
(171, 'PH', 'PHL', N'Philippines', NULL, 0, 0, 0, 0, 0, 0),
(172, 'PN', 'PCN', N'Pitcairn', NULL, 0, 0, 0, 0, 0, 0),
(173, 'PL', 'POL', N'Poland', NULL, 1, 1, 1, 0, 1, 0),
(174, 'PT', 'PRT', N'Portugal', NULL, 1, 1, 0, 0, 1, 0),
(175, 'PR', 'PRI', N'Puerto Rico', NULL, 0, 0, 0, 0, 0, 0),
(176, 'QA', 'QAT', N'Qatar', NULL, 0, 0, 0, 0, 0, 0),
(177, 'RE', 'REU', N'Reunion', NULL, 0, 0, 0, 0, 0, 0),
(178, 'RO', 'ROU', N'Romania', NULL, 1, 1, 0, 0, 0, 0),
(179, 'RU', 'RUS', N'Russian Federation', NULL, 0, 0, 0, 0, 0, 0),
(180, 'RW', 'RWA', N'Rwanda', NULL, 0, 0, 0, 0, 0, 0),
(181, 'SH', 'SHN', N'St Helena', NULL, 0, 0, 0, 0, 0, 0),
(182, 'KN', 'KNA', N'St Kitts & Nevis', NULL, 0, 0, 0, 0, 0, 0),
(183, 'LC', 'LCA', N'Saint Lucia', NULL, 0, 0, 0, 0, 0, 0),
(184, 'PM', 'SPM', N'St Pierre & Miqu''n', NULL, 0, 0, 0, 0, 0, 0),
(185, 'VC', 'VCT', N'St Vincent & Gren''', NULL, 0, 0, 0, 0, 0, 0),
(186, 'WS', 'WSM', N'Samoa', NULL, 0, 0, 0, 0, 0, 0),
(187, 'SM', 'SMR', N'San Marino', NULL, 0, 0, 0, 0, 0, 0),
(188, 'ST', 'STP', N'S. Tome & Principe', NULL, 0, 0, 0, 0, 0, 0),
(189, 'SA', 'SAU', N'Saudi Arabia', NULL, 0, 0, 0, 0, 0, 0),
(190, 'SN', 'SEN', N'Senegal', NULL, 0, 0, 0, 0, 0, 0),
(191, 'RS', 'SRB', N'Serbia', NULL, 0, 0, 0, 0, 0, 0),
(192, 'SC', 'SYC', N'Seychelles', NULL, 0, 0, 0, 0, 0, 0),
(193, 'SL', 'SLE', N'Sierra Leone', NULL, 0, 0, 0, 0, 0, 0),
(194, 'SG', 'SGP', N'Singapore', NULL, 0, 0, 0, 0, 0, 0),
(195, 'SK', 'SVK', N'Slovakia', NULL, 1, 1, 1, 0, 1, 0),
(196, 'SI', 'SVN', N'Slovenia', NULL, 1, 1, 1, 0, 1, 0),
(197, 'SB', 'SLB', N'Solomon Islands', NULL, 0, 0, 0, 0, 0, 0),
(198, 'SO', 'SOM', N'Somalia', NULL, 0, 0, 0, 0, 0, 0),
(199, 'ZA', 'ZAF', N'South Africa', NULL, 0, 0, 0, 0, 0, 0),
(200, 'GS', 'SGS', N'South Georgia ', NULL, 0, 0, 0, 0, 0, 0),
(201, 'ES', 'ESP', N'Spain', NULL, 1, 1, 0, 0, 1, 0),
(202, 'LK', 'LKA', N'Sri Lanka', NULL, 0, 0, 0, 0, 0, 0),
(203, 'SD', 'SDN', N'Sudan', NULL, 0, 0, 0, 0, 0, 0),
(204, 'SR', 'SUR', N'Suriname', NULL, 0, 0, 0, 0, 0, 0),
(205, 'SJ', 'SJM', N'Svalbard & J''Mayen', NULL, 0, 0, 0, 0, 0, 0),
(206, 'SZ', 'SWZ', N'Swaziland', NULL, 0, 0, 0, 0, 0, 0),
(207, 'SE', 'SWE', N'Sweden', NULL, 1, 1, 0, 0, 1, 0),
(208, 'CH', 'CHE', N'Switzerland', NULL, 0, 1, 0, 0, 1, 1),
(209, 'SY', 'SYR', N'Syria', NULL, 0, 0, 0, 0, 0, 0),
(210, 'TW', 'TWN', N'Taiwan', NULL, 0, 0, 0, 0, 0, 0),
(211, 'TJ', 'TJK', N'Tajikistan', NULL, 0, 0, 0, 0, 0, 0),
(212, 'TZ', 'TZA', N'Tanzania', NULL, 0, 0, 0, 0, 0, 0),
(213, 'TH', 'THA', N'Thailand', NULL, 0, 0, 0, 0, 0, 0),
(214, 'TL', 'TLS', N'Timor-Leste', NULL, 0, 0, 0, 0, 0, 0),
(215, 'TG', 'TGO', N'Togo', NULL, 0, 0, 0, 0, 0, 0),
(216, 'TK', 'TKL', N'Tokelau', NULL, 0, 0, 0, 0, 0, 0),
(217, 'TO', 'TON', N'Tonga', NULL, 0, 0, 0, 0, 0, 0),
(218, 'TT', 'TTO', N'Trinidad & Tobago', NULL, 0, 0, 0, 0, 0, 0),
(219, 'TN', 'TUN', N'Tunisia', NULL, 0, 0, 0, 0, 0, 0),
(220, 'TR', 'TUR', N'Turkey', NULL, 0, 0, 0, 0, 0, 0),
(221, 'TM', 'TKM', N'Turkmenistan', NULL, 0, 0, 0, 0, 0, 0),
(222, 'TC', 'TCA', N'Turks & Caicos Is', NULL, 0, 0, 0, 0, 0, 0),
(223, 'TV', 'TUV', N'Tuvalu', NULL, 0, 0, 0, 0, 0, 0),
(224, 'UG', 'UGA', N'Uganda', NULL, 0, 0, 0, 0, 0, 0),
(225, 'UA', 'UKR', N'Ukraine', NULL, 0, 0, 0, 0, 0, 0),
(226, 'AE', 'ARE', N'UAE', NULL, 0, 0, 0, 0, 0, 0),
(227, 'GB', 'GBR', N'United Kingdom', NULL, 1, 1, 0, 0, 0, 0),
(228, 'US', 'USA', N'United States', NULL, 0, 0, 0, 0, 0, 1),
(229, 'UM', 'UMI', N'US Minor Outl''g Is', NULL, 0, 0, 0, 0, 0, 0),
(230, 'UY', 'URY', N'Uruguay', NULL, 0, 0, 0, 0, 0, 0),
(231, 'UZ', 'UZB', N'Uzbekistan', NULL, 0, 0, 0, 0, 0, 0),
(232, 'VU', 'VUT', N'Vanuatu', NULL, 0, 0, 0, 0, 0, 0),
(233, 'VE', 'VEN', N'Venezuela', NULL, 0, 0, 0, 0, 0, 0),
(234, 'VN', 'VNM', N'Vietnam', NULL, 0, 0, 0, 0, 0, 0),
(235, 'VG', 'VGB', N'Virgin Is, British', NULL, 0, 0, 0, 0, 0, 0),
(236, 'VI', 'VIR', N'Virgin Is, US', NULL, 0, 0, 0, 0, 0, 0),
(237, 'WF', 'WLF', N'Wallis And Futuna', NULL, 0, 0, 0, 0, 0, 0),
(238, 'EH', 'ESH', N'Western Sahara', NULL, 0, 0, 0, 0, 0, 0),
(239, 'YE', 'YEM', N'Yemen', NULL, 0, 0, 0, 0, 0, 0),
(240, 'ZM', 'ZMB', N'Zambia', NULL, 0, 0, 0, 0, 0, 0),
(241, 'ZW', 'ZWE', N'Zimbabwe', NULL, 1, 1, 1, 0, 0, 0),
(242, 'AO', 'AGO', N'Angola', NULL, 1, 1, 1, 1, 0, 0),
(243, 'KV', 'KVO', N'Kosovo', NULL, 0, 0, 0, 0, 0, 0),
(244, 'CW', 'CUW', N'Curacao', NULL, 0, 0, 0, 0, 0, 0),
(245, 'AQ', 'ATA', N'Antarctica', NULL, 0, 0, 0, 0, 0, 0),
(246, 'CD', 'COD', N'DR Congo', NULL, 0, 0, 0, 0, 0, 0),
(247, 'IW', 'IW', N'International Waters', NULL, 0, 0, 0, 0, 0, 0),
(248, 'BL', 'BLM', N'Saint-Barthélemy', NULL, 0, 0, 0, 0, 0, 0),
(249, 'MF', 'MAF', N'Saint-Martin (French part)', NULL, 0, 0, 0, 0, 0, 0),
(250, 'SS', 'SSD', N'South Sudan', NULL, 0, 0, 0, 0, 0, 0),
(251, 'CS', 'SCG', N'Serbia and Montenegro', NULL, 0, 0, 0, 0, 0, 0),
(252, 'BQ', 'BES', N'Bonaire', NULL, 0, 0, 0, 0, 0, 0),
(253, 'XK', 'XKX', N'Kosovo', NULL, 0, 0, 0, 0, 0, 0)

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
VALUES ([CountryID], [CountryCode], [ThreeCharCode], [CountryName], [CurrencyID], [ECCountry], [EEACountry], [A8Country], [ESTACountry], [SchengenCountry], [HasState])

-- Delete missing rows
WHEN NOT MATCHED BY SOURCE THEN
DELETE;

SET IDENTITY_INSERT [dbo].[Country] OFF

/*------------------------------------------------------- Schema Script End */

PRINT N'Update complete.';

PRINT 'The database update succeeded.'
PRINT ''
PRINT N'Updating the KPMG version table.';

DECLARE @VersionKey varchar(50) = 'Data'
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
