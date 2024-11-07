--V 1.0 - Original report sent by Digita
--KPMG mega report - requested by James Healy from Digita - we may be asked to run this again.
--amend name of database if not Taxywin
USE [TaxywinCOE]

DECLARE @TaxYear INT = 2019

SELECT	REFCODE AS ClientCode,
		C.SURNAME AS Surname,
		C.FIRSTNAMES AS FirstNames,
		TaxRef AS UTR,
		Partner,
		Manager,
		C.DOB AS DateOfBirth, 
		(CONVERT(int,CONVERT(char(8),GETDATE(),112))-CONVERT(char(8),C.DOB,112))/10000 AS AgeInYears,
		TF.Postcode,
		
		--bank interest
		CASE WHEN ISNULL(NB.NetBanks,0) + ISNULL(NUT.NetUT,0) + ISNULL(GB.GrossBanks,0) + ISNULL(GUT.GrossUT,0) + ISNULL(FB.ForeignInt,0) >= 50000 
				THEN 'Y' ELSE 'N' END AS SignificantInterest,
		ISNULL(NB.NetBanks,0) + ISNULL(NUT.NetUT,0) AS NetInterest_TR3_1,
		ISNULL(GB.GrossBanks,0) + ISNULL(GUT.GrossUT,0) AS GrossInterest_TR3_2,
		ISNULL(FB.ForeignInt,0) AS  ForeignInterest_TR3_3,

		--dividend income
		CASE WHEN ISNULL(UD.UKDividends,0)+ISNULL(OD.OtherDividends,0)+ISNULL(FD.ForeignDiv,0)  > = 150000 THEN 'Y' ELSE 'N' END AS SignificantDividends,
		ISNULL(UD.UKDividends,0) AS UKDividends_TR3_4,
		ISNULL(OD.OtherDividends,0) AS OtherDividends_TR3_5,
		ISNULL(FD.ForeignDiv,0) AS ForeignDividends_TR3_6,


		--Benefit from pre owned assests
		ISNULL(PO.BenefitFromPreOwned_TR3_20,0) AS BenefitFromPreOwned_TR3_20,

		--pension conts
		CASE WHEN ISNULL(PL.PersPen,0)+ISNULL(PL.RetAnn,0)+ISNULL(PL.PreTaxPen,0)+ISNULL(PL.OSPen,0) >=100000 THEN 'Y' ELSE 'N' END AS SignificantPensionConts,
		ISNULL(PL.PersPen,0) AS PensionContsWithRelief_TR4_1,
		ISNULL(PL.RetAnn,0) AS RetAnnuityConts_TR4_2,
		ISNULL(PL.PreTaxPen,0) AS PreTaxERConts_TR4_3,
		ISNULL(PL.OSPen,0) AS OverseasPenConts_TR4_4,

		--gifts to charity
		CASE WHEN ISNULL(Gaid.GiftAidPayments,0) > = 50000 THEN 'Y' ELSE 'N' END AS SignificantGiftAid,
		ISNULL(Gaid.GiftAidPayments,0) AS GiftAid_TR4_5,
		ISNULL(GAsset.GiftShares,0) AS GiftShares_TR4_9,
		ISNULL(GAsset.GiftProperty,0) AS GiftProperty_TR4_10,

		--child benefit
		ISNULL(ORI.cHICBCChargeable,0) AS HighIncomeChildBenefit_TR5_1,
		ISNULL(ORI.dtHICBCCeased,'') AS ChildBenefitCeaseDate_TR5_3,

		--Life Assurance gains
		CASE WHEN ISNULL(LAG.LAGainsTaxed,0) + ISNULL(LAG.LAGainsUntaxed,0) >= 50000 THEN 'Y' ELSE 'N' END AS SignificantLifeAssGains,
		ISNULL(LAG.LAGainsTaxed,0) AS LifeAssGainsTaxed_AI_1_4,
		ISNULL(LAG.LAGainsUntaxed,0) AS LifeAssGainsUntaxed_AI_1_6,

		--other reliefs
		CASE WHEN ISNULL(OO.EISSubscription,0)  >= 50000 THEN 'Y' ELSE 'N' END AS SignificantEISsubscription,
		ISNULL(OO.EISSubscription,0) AS EISSubscription_AI_2_2 ,
		CASE WHEN ISNULL(OO.VCTSubscription,0)  >= 50000 THEN 'Y' ELSE 'N' END AS SignificantVCTSubscription,
		ISNULL(OO.VCTSubscription,0) AS VCTSubscription_AI_2_1,
		CASE WHEN ISNULL(ForEarnNotUKTaxable,0)  >= 25000 THEN 'Y' ELSE 'N' END AS SignificantForEarnNotUKTaxable,
		ISNULL(ForEarnNotUKTaxable,0) AS ForEarnNotUKTaxable_AI_2_12,

		--pension tax charges
		CASE WHEN ISNULL(PTC.AllowanceLS,0)+ISNULL(PTC.AllowanceNonLS,0)+ISNULL(PTC.AnnAllowXS,0)  >= 50000 THEN 'Y' 
				ELSE 'N' END AS SignificantPensionCharges,
		ISNULL(PTC.AllowanceLS,0) AS ALAexcessLumpSum_AI4_7,
		ISNULL(PTC.AllowanceNonLS,0) AS ALAexcessNonLS_AI4_8,
		ISNULL(PTC.AnnAllowXS,0) AS ALAexcess_Savings_AI4_10,

		--property income
		CASE WHEN ISNULL(LP.NumProperties,0) >= 5 THEN 'Y'
			 WHEN ISNULL(LP.NumProperties,0) = 1 AND ISNULL(LP.RentalIncome,0)>=150000 THEN 'Y'
			 ELSE 'N' END AS SignificantPropertyIncome,
		ISNULL(LP.NumProperties,0) AS NumberProperties_UKP1_1,
		ISNULL(LP.RentalIncome,0) AS RentalIncome_UKP2_20,
		ISNULL(Pint.PropertyInterestExpenses,0) AS PropInterestExpenses_UKP2_26,
		ISNULL(FHL.FHLRentalIncome,0) AS FHLRentalIncome_UKP1_5,

		--foreign
		ISNULL(ORI.cForeignTaxCreditRelief,0) AS FTCR_F1_2,

		--residence
		ISNULL(bNotResidentUKThisYear,0) AS NotResidentUKThisYear_RR1_1,
		ISNULL(bNotDomiciledInUK,0) AS NotDomiciledInUK_RR2_23,
		ISNULL(bUKResidentSevenYears,0) AS UKResidentSevenYears_RR3_31,
		ISNULL(bUKResidentTwelveYears,0) AS UKResidentTwelveYears_RR3_32,

		--capital gains
		ISNULL(CG.ResidentialGains,0) AS ResidentialGains_CG1_6,
		ISNULL(CG.OtherGains,0) AS OtherGains_CG1_17,
		ISNULL(CG.QuotedGains,0) AS QuotedGains_CG2_26,
		ISNULL(CG.UnquotedGains,0) AS UnquotedGains_CG2_34,

		--CGT reliefs
		ISNULL(CGTClaims.Residential,'') AS ResidentialRelief_CG1_8,
		ISNULL(CGTClaims.Other,'')  AS OtherRelief_CG1_20,
		ISNULL(CGTClaims.Quoted,'')  AS QuotedRelief_CG2_28,
		ISNULL(CGTClaims.Unquoted,'')  AS UnQuotedRelief_CG2_36,

		--Entrepreneur Relief
		ISNULL(Erel.EntrepreneurReliefPre2010,0) AS EntrepreneurReliefPre2010_CG3_49,
		ISNULL(Erel.EntrepreneurReliefPost2010,0) AS EntrepreneurReliefPost2010_CG3_50,

		--CG estimates
		CASE WHEN Est.ClientID IS NOT NULL THEN 'Y' ELSE 'N' END AS EstimatedCGValues_CG3_53

FROM Client C INNER JOIN
	 Taxform TF ON C.CLIENTID = TF.CLIENTID LEFT JOIN
	 --residency information
			 (SELECT lClientID,
			   nYear,
			   bNotResidentUKThisYear,
			   bNotDomiciledInUK,
			   bUKResidentSevenYears,
			   bUKResidentTwelveYears
			  FROM Residence) R ON TF.CLIENTID = R.lClientID AND TF.YEAR = R.nYear LEFT JOIN
	--Pre Owned Benefit
			(SELECT CLIENTID, YEAR, SUM(ISNULL(cPreOwnedAssessable,0)) AS BenefitFromPreOwned_TR3_20
			FROM Income
			WHERE ClientID = 3433813 and year = 2018 AND [TYPE] = 'PREOWNED'
			GROUP BY CLIENTID, YEAR) PO ON TF.CLIENTID = PO.CLIENTID AND TF.YEAR = PO.YEAR LEFT JOIN
	--child benefit details
	OtherReturnInfo ORI ON TF.CLIENTID = ORI.lClientID AND TF.YEAR = ORI.nYear LEFT JOIN
	--gift aid
			(SELECT CLIENTID, YEAR, SUM(ISNULL(cAmountPaidNet,0)) AS GiftAidPayments
			FROM OtherOut
			WHERE TYPE = 'GAIDCOV'
			GROUP BY CLIENTID, YEAR) GAid ON TF.CLIENTID = GAid.CLIENTID AND TF.YEAR = GAid.YEAR LEFT JOIN
	--charity assets
			(SELECT CLIENTID, YEAR, SUM(ISNULL(cRealProperty,0)) AS GiftProperty, SUM(ISNULL(cSharesSecurities,0)) AS GiftShares
			FROM OtherOut
			WHERE TYPE = 'GIFTCHAR'
			GROUP BY CLIENTID, YEAR) GAsset ON TF.CLIENTID = GAsset.CLIENTID AND TF.YEAR = GAsset.YEAR LEFT JOIN
	--FHL
			(SELECT CLIENTID, YEAR, SUM(ISNULL(TotalIncome,0)) AS FHLRentalIncome
			FROM PropUK P
			WHERE [TYPE] = 'FURHLET'
			GROUP BY CLIENTID, YEAR) FHL ON TF.CLIENTID = FHL.CLIENTID AND TF.YEAR = FHL.YEAR LEFT JOIN
	--large property portfolio
			(SELECT CLIENTID, YEAR, SUM(CASE WHEN [TYPE] = 'UKRENT' THEN TotalIncome ELSE 0 END) AS RentalIncome ,SUM(ISNULL(nPropertiesRented,0)) AS NumProperties
			FROM PropUK P
			WHERE [TYPE] != 'PROPABRD'
			GROUP BY CLIENTID, YEAR) LP 	ON TF.CLIENTID = LP.CLIENTID AND TF.YEAR = LP.YEAR  LEFT JOIN
	--property interest expenses
			(SELECT CLIENTID, YEAR, SUM(ISNULL(FinChrgsIncInt,0)) AS PropertyInterestExpenses
			FROM PropUK P
			WHERE [TYPE] = 'UKRENT'
			GROUP BY CLIENTID, YEAR) PInt ON TF.CLIENTID = PInt.CLIENTID AND TF.YEAR = PInt.YEAR LEFT JOIN
	--life assurance gains
			(SELECT ClientID, Year, (SUM(CASE bPaidWithNotionalTax WHEN 1 THEN Amount ELSE 0 END)) AS LAGainsTaxed, (SUM(CASE bPaidWithNotionalTax WHEN 0 THEN Amount ELSE 0 END)) AS LAGainsUntaxed
			FROM Income
			WHERE ClientID = 3433813 and year = 2018 AND TYPE = 'LFEASSGN'
			GROUP BY ClientID, Year) LAG ON TF.CLIENTID = LAG.CLIENTID AND TF.YEAR = LAG.YEAR LEFT JOIN
	--other reliefs
			(SELECT CLIENTID, YEAR, SUM(CASE [TYPE] WHEN 'EISSCREL'  THEN ISNULL(GROSSAMT,0) ELSE 0 END) AS EISSubscription , SUM(CASE [TYPE] WHEN 'VNTCPTRS'  THEN ISNULL(GROSSAMT,0) ELSE 0 END) AS VCTSubscription
			FROM OtherOut
			WHERE TYPE IN ('EISSCREL','VNTCPTRS')
			GROUP BY ClientID, Year) OO ON TF.CLIENTID = OO.CLIENTID AND TF.YEAR = OO.YEAR LEFT JOIN
	-- non taxable foreign earnings
			(SELECT ClientID, Year, SUM(ISNULL(ef.cAmount,0)) AS ForEarnNotUKTaxable
			FROM NewEmploy ne inner join EmployForeign ef on ne.lEmployID = ef.lEmployID
			WHERE ef.lRefID = 20  
			GROUP BY ClientID, Year) FE ON TF.CLIENTID = FE.ClientID AND TF.YEAR = FE.Year LEFT JOIN
	--pension tax charges
			(SELECT	[lClientID],
					[nYear],
					SUM(CASE nSurchargeType WHEN 10 THEN ISNULL( [cSurchargeAmount],0) ELSE 0 END) AS AllowanceLS,
					SUM(CASE nSurchargeType WHEN 20 THEN ISNULL( [cSurchargeAmount],0) ELSE 0 END) AS AllowanceNonLS,
					SUM(CASE nSurchargeType WHEN 80 THEN ISNULL( [cSurchargeAmount],0) ELSE 0 END) AS AnnAllowXS
			FROM [PlanDetailsSurcharge]
			WHERE nSurchargeType IN (10,20,80)
			GROUP BY [lClientID] ,[nYear]) PTC ON TF.CLIENTID = PTC.lClientID AND TF.YEAR = PTC.nYear LEFT JOIN
	--pension conts			
			(SELECT ClientID, Year, SUM(CASE [TYPE] WHEN 'PERSPEN' THEN ISNULL(NOWGROSS,0) ELSE 0 END) AS PersPen,
					SUM(CASE WHEN [TYPE] = 'RETANNU' OR ( bRelievablePremium = 1 AND bNonUKScheme  = 0 AND bOutsideNetPayScheme = 0 AND bNHSPractitionerScheme = 0) THEN ISNULL(NOWGROSS,0) ELSE 0 END) AS RetAnn,
					SUM(CASE WHEN [TYPE] = 'OTHERPEN' AND bNonUKScheme = 1 THEN ISNULL(NOWGROSS,0) ELSE 0 END) AS OSPen,
					SUM(CASE WHEN [TYPE] = 'OTHERPEN' AND bOutsideNetPayScheme = 1 THEN ISNULL(NOWGROSS,0) ELSE 0 END) AS PreTaxPen
			FROM [Plan]
			GROUP BY ClientID, Year ) PL ON TF.CLIENTID = PL.CLIENTID AND TF.YEAR = PL.YEAR LEFT JOIN
	--CGT gains
		( SELECT ClientID, Year, SUM(ISNULL(QuotedDisposals,0)) AS QuotedDisposals ,SUM(ISNULL(QuotedGains,0)) AS QuotedGains ,SUM(ISNULL(QuotedLosses,0)) AS QuotedLosses ,
		 SUM(ISNULL(UnquotedDisposals,0)) AS UnquotedDisposals ,SUM(ISNULL(UnquotedGains,0)) AS UnquotedGains ,SUM(ISNULL(UnquotedLosses,0)) AS UnquotedLosses ,
		 SUM(ISNULL(ResidentialDisposals,0)) AS ResidentialDisposals ,SUM(ISNULL(ResidentialGains,0)) AS ResidentialGains ,SUM(ISNULL(ResidentialLosses,0)) AS ResidentialLosses ,
		 SUM(ISNULL(PropertyDisposals,0)) AS PropertyDisposals ,SUM(ISNULL(PropertyGains,0)) AS PropertyGains ,SUM(ISNULL(PropertyLosses,0)) AS PropertyLosses ,
		 SUM(ISNULL(OtherDisposals,0))+ SUM(ISNULL(PropertyDisposals,0)) AS OtherDisposals ,SUM(ISNULL(OtherGains,0))+SUM(ISNULL(PropertyGains,0)) AS OtherGains ,SUM(ISNULL(OtherLosses,0))+SUM(ISNULL(PropertyLosses,0))  AS OtherLosses 
		 FROM (
		 SELECT CGT.[CLIENTID], CGT.YEAR, QuotedDisposals, QuotedGains, QuotedLosses, UnquotedDisposals, UnquotedGains, UnquotedLosses,
					ResidentialDisposals, ResidentialGains, ResidentialLosses, PropertyDisposals, PropertyGains, PropertyLosses, OtherDisposals, OtherGains, OtherLosses
		 FROM (SELECT DISTINCT ClientID, Year FROM CGT) CGT  LEFT JOIN
		 (
		 --quoted
		 SELECT [CLIENTID]  ,YEAR ,SUM(CASE WHEN [TOTALGAIN] > 0 THEN [TOTALGAIN] ELSE 0 END) AS QuotedGains
			   ,SUM(CASE WHEN [TOTALGAIN] < 0 THEN [TOTALGAIN] ELSE 0 END) AS QuotedLosses ,COUNT([ID]) AS QuotedDisposals    
		  FROM [CGT]
		  WHERE nCategory = 1 AND ISNULL(cERAmountClaimed,0) = 0 AND ISNULL(cDeferredERAmount,0)  = 0
		  GROUP BY  [CLIENTID] ,YEAR) CGT1 ON CGT.CLIENTID = CGT1.CLIENTID AND CGT.YEAR = CGT1.YEAR LEFT JOIN
		  (
		   --unquoted
		 SELECT [CLIENTID]  ,YEAR ,SUM(CASE WHEN [TOTALGAIN] > 0 THEN [TOTALGAIN] ELSE 0 END) AS UnquotedGains
			   ,SUM(CASE WHEN [TOTALGAIN] < 0 THEN [TOTALGAIN] ELSE 0 END) AS UnquotedLosses ,COUNT([ID]) AS UnquotedDisposals    
		  FROM [CGT]
		  WHERE nCategory = 2 AND ISNULL(cERAmountClaimed,0) = 0 AND ISNULL(cDeferredERAmount,0)  = 0
		  GROUP BY  [CLIENTID] ,YEAR) CGT2 ON CGT.CLIENTID = CGT2.CLIENTID AND CGT.YEAR = CGT2.YEAR LEFT JOIN
		  (
		  --reseidential
		   SELECT [CLIENTID]  ,YEAR ,SUM(CASE WHEN [TOTALGAIN] > 0 THEN [TOTALGAIN] ELSE 0 END) AS ResidentialGains
			   ,SUM(CASE WHEN [TOTALGAIN] < 0 THEN [TOTALGAIN] ELSE 0 END) AS ResidentialLosses ,COUNT([ID]) AS ResidentialDisposals    
		  FROM [CGT]
		  WHERE nCategory = 13 AND ISNULL(cERAmountClaimed,0) = 0 AND ISNULL(cDeferredERAmount,0)  = 0
		  GROUP BY  [CLIENTID] ,YEAR) CGT3 ON CGT.CLIENTID = CGT3.CLIENTID AND CGT.YEAR = CGT3.YEAR LEFT JOIN
		  (
		  --other property
		   SELECT [CLIENTID]  ,YEAR ,SUM(CASE WHEN [TOTALGAIN] > 0 THEN [TOTALGAIN] ELSE 0 END) AS PropertyGains
			   ,SUM(CASE WHEN [TOTALGAIN] < 0 THEN [TOTALGAIN] ELSE 0 END) AS PropertyLosses ,COUNT([ID]) AS PropertyDisposals    
		  FROM [CGT]
		  WHERE nCategory = 4 AND ISNULL(cERAmountClaimed,0) = 0 AND ISNULL(cDeferredERAmount,0)  = 0
		  GROUP BY  [CLIENTID] ,YEAR) CGT4 ON CGT.CLIENTID = CGT4.CLIENTID AND CGT.YEAR = CGT4.YEAR LEFT JOIN
		  (
			--other 
		   SELECT [CLIENTID]  ,YEAR ,SUM(CASE WHEN [TOTALGAIN] > 0 THEN [TOTALGAIN] ELSE 0 END) AS OtherGains
			   ,SUM(CASE WHEN [TOTALGAIN] < 0 THEN [TOTALGAIN] ELSE 0 END) AS OtherLosses ,COUNT([ID]) AS OtherDisposals    
		  FROM [CGT]
		  WHERE nCategory = 5 OR ISNULL(cERAmountClaimed,0) != 0 OR ISNULL(cDeferredERAmount,0)  != 0
		  GROUP BY  [CLIENTID] ,YEAR) CGT5 ON CGT.CLIENTID = CGT5.CLIENTID AND CGT.YEAR = CGT5.YEAR 
		  UNION
		  (SELECT [ClientID],
			  [Year],
			  SUM(ISNULL([nQuotedDisposals],0)) AS QuotedDisposals,
			  SUM(ISNULL([cQuotedGain],0)) AS QuotedGain,
			  SUM(ISNULL([cQuotedLoss],0)) AS QuotedLoss,
			  SUM(ISNULL([nUnquotedDisposals],0)) AS UnquotedDisposals,
			  SUM(ISNULL([cUnquotedGain],0)) AS UnquotedGain,
			  SUM(ISNULL([cUnquotedLoss],0)) AS UnquotedLoss,
			  SUM(ISNULL([nResidentialDisposals],0)) AS ResidentialDisposals,
			  SUM(ISNULL([cResidentialGain],0)) AS ResidentialGain,
			  SUM(ISNULL([cResidentialLoss],0)) AS ResidentialLoss,
			  SUM(ISNULL([nPropertyDisposals],0)) AS PropertyDisposals,
			  SUM(ISNULL([cPropertyGain],0)) AS PropertyGain,
			  SUM(ISNULL([cPropertyLoss],0)) AS PropertyLoss,
			  SUM(ISNULL([nOtherDisposals],0)) AS OtherDisposals,
			  SUM(ISNULL([cOtherGain],0)) AS OtherGain,
			  SUM(ISNULL([cOtherLoss],0)) AS OtherLoss
		  FROM [CapitalGainsSummary]
		  GROUP BY  [ClientID]
			  ,[Year]) ) X
		GROUP BY ClientID, Year) CG ON TF.CLIENTID = CG.ClientID AND TF.Year = CG.YEAR LEFT JOIN
	--CGT relief claims
	(

SELECT ClientID, Year, [Quoted] ,[Unquoted],[Residential],[Other]
FROM
(
SELECT ClientID, Year, Category, CASE WHEN LEN(NVC+ERL+Claimcode) > 3 THEN 'MUL'
			ELSE ISNULL(ClaimCode, CASE WHEN NVC != '' THEN NVC ELSE ERL END) END AS Claimcode
FROM (
SELECT ClientID, Year, 
		CASE WHEN (ISNULL(cERAmountClaimed,0) = 0 AND ISNULL(cDeferredERAmount,0)  = 0) THEN 
				CASE nCategory
					WHEN 1 THEN 'Quoted'
					WHEN 2 THEN 'Unquoted'
					WHEN 3 THEN  'Other'
					WHEN 4 THEN 'Other'
					WHEN 13 THEN 'Residential'
					ELSE 'Other' END
			ELSE 'Other' END AS Category, 
			CASE bNegligibleValueClaim WHEN 1 THEN 'NVC' ELSE '' END AS NVC,
			CASE WHEN (ISNULL(cERAmountClaimed,0) != 0 OR ISNULL(cDeferredERAmount,0)  != 0) THEN 'ERL' ELSE '' END AS ERL,
			CGTA.ClaimCode AS ClaimCode--,
			--ROW_NUMBER() OVER (PARTITION BY ClientID ,Year ORDER BY CLientID, Year)
FROM CGT LEFT JOIN
		(SELECT [ID],
		 CASE WHEN CntRelief > 1 THEN 'MUL'
		 ELSE CASE MaxRelief WHEN 30 THEN 'ROR'
							 WHEN 27 THEN 'PRR'
							 WHEN 36 THEN 'LET'
							 WHEN 40 THEN 'SIR'
							 WHEN 41 THEN 'SIR'
							 WHEN 43 THEN 'ESH'
							 WHEN 24 THEN 'GHO'
							 ELSE 'OTH' END END AS ClaimCode
		FROM (SELECT [ID], MAX(ACQEVENT) AS MaxRelief , COUNT(ACQEVENT)  AS CntRelief
				FROM CGTAcq 
				 WHERE ACQRELIEF = 1 AND ACQPRICE != 0
				 GROUP BY [ID]) X) CGTA ON CGT.[ID] = CGTA.[ID]
				WHERE bNegligibleValueClaim = 1 OR 
						ISNULL(cERAmountClaimed,0) != 0 OR
						ISNULL(cDeferredERAmount,0) != 0 OR
						CGTA.ClaimCode IS NOT NULL
) C) P
PIVOT (MAX(ClaimCode) FOR Category IN([Quoted],[Unquoted],[Residential],[Other])) AS pvt) CGTClaims ON TF.CLIENTID = CGTClaims.CLIENTID AND TF.Year = CGTClaims.YEAR
		LEFT JOIN
	--net banks
	(SELECT lClientID, nYear, SUM(ISNULL(cNEtAmount,0)) AS NetBanks
		FROM NewInterest
		WHERE lTypeID IN (SELECT lTypeID FROM NewInterestTypeRef where bGrossFrom2017	= 0)
				AND lCategoryID NOT IN (30,40) --excludes net stocks and other
				AND bUnderwriting = 0
		GROUP BY lClientID, nYear) NB ON TF.CLIENTID = NB.lClientID AND TF.YEAR = NB.nYear LEFT JOIN
	--net UT interest
	(SELECT lClientid, nYear, SUM(ISNULL(UTP.cNetAmount,0)) AS NetUT
		FROM NewInterestUT UT INNER JOIN NewInterestUTPayments UTP ON UT.lUnitTrustId = UTP.lUnitTrustId
		WHERE UT.bInterestPaidGross = 0 
		GROUP BY lClientid, nYear) NUT ON TF.CLIENTID = NUT.lClientID AND TF.YEAR = NUT.nYear LEFT JOIN
	--Gross banks
	(SELECT lClientID, nYear, SUM(ISNULL(cGrossAmount,0)) AS GrossBanks
		FROM NewInterest
		WHERE lTypeID IN (SELECT lTypeID FROM NewInterestTypeRef where bGrossFrom2017	= 1)
				AND lCategoryID NOT IN (30,40) --excludes net stocks and other
				AND bUnderwriting = 0
		GROUP BY lClientID, nYear) GB ON TF.CLIENTID = GB.lClientID AND TF.YEAR = GB.nYear LEFT JOIN
	--Gross UT interest
	(SELECT lClientid, nYear, SUM(ISNULL(UTP.cGrossAmount,0)) AS GrossUT
		FROM NewInterestUT UT INNER JOIN NewInterestUTPayments UTP ON UT.lUnitTrustId = UTP.lUnitTrustId
		WHERE UT.bInterestPaidGross = 1 
		GROUP BY lClientid, nYear) GUT ON TF.CLIENTID = GUT.lClientid AND TF.Year = GUT.nYear LEFT JOIN
	--foreign banks
	(SELECT ClientID, year, SUM(ISNULL(GrossAmount,0)-ISNULL(TaxFreeAmount,0)) As ForeignInt
		FROM OtherForeignIncome
		WHERE [Type] = 'FRGBAOI' AND ISNULL(TaxDedUk,0) = 0 AND ISNULL(FrgnTaxDeducted,0)= 0 AND bUnderwriting = 0
		GROUP BY ClientID, year ) FB ON TF.CLIENTID = FB.CLIENTID AND TF.YEAR = FB.YEAR LEFT JOIN
	--foreign dividends
	(SELECT CLIENTID, YEAR, SUM(ISNULL(cDivTotalValue,0)) AS ForeignDiv
		FROM OtherForeignIncome
		WHERE [Type] = 'OFRGNDIV' AND ISNULL(TaxDedUk,0) = 0 AND ISNULL(FrgnTaxDeducted,0)= 0 AND bUnderwriting = 0
		GROUP BY CLIENTID, YEAR)   FD ON TF.CLIENTID = FD.CLIENTID AND TF.YEAR = FD.YEAR LEFT JOIN
	--UK dividends
	(SELECT lClientid, nYear, SUM(ISNULL(cGrossAmount,0)) AS UKDividends
FROM NewShare NS INNER JOIN NewDividend ND ON NS.lShareId = ND.lShareId
WHERE bInvestmentTrust = 0 AND lTypeId  IN(10,90)
GROUP BY lClientid, nYear) UD ON UD.lClientid = TF.CLIENTID AND UD.nYear = TF.YEAR LEFT JOIN
	--other dividends
	(SELECT lClientid, nYear, SUM(ISNULL(cGrossAmount,0)) AS OtherDividends
		FROM NewShare NS INNER JOIN NewDividend ND ON NS.lShareId = ND.lShareId
		WHERE bInvestmentTrust = 1 OR lTypeId IN (60,70)
		GROUP BY lClientid, nYear	) OD ON TF.CLIENTID = OD.lClientid AND  TF.YEAR = OD.nYear LEFT JOIN
	--ER relief
	(SELECT 	[CLIENTID],[YEAR],SUM(ISNULL([cERAmountClaimed],0)) AS EntrepreneurReliefPost2010 ,SUM(ISNULL([cDeferredERAmount],0)) AS EntrepreneurReliefPre2010
		FROM  [CGT]
		GROUP BY Year, CLIENTID
		HAVING SUM(ISNULL([cERAmountClaimed],0)) != 0 OR SUM(ISNULL([cDeferredERAmount],0)) != 0) AS ERel ON TF.ClientID = Erel.ClientID AND TF.YEAR = Erel.YEAR LEFT JOIN
	--CG estimate
	(SELECT ClientID, Year FROM 
		(  SELECT DISTINCT ClientID, Year
			  FROM CGT
			  WHERE Estimate = 1
			  UNION 
			  SELECT DISTINCT ClientID, Year
			  FROM CapitalGainsSummary
			  WHERE [bQuotedValuationEstimate] = 1 OR [bUnquotedValuationEstimate] = 1 OR [bPropertyValuationEstimate] = 1 
						OR [bOtherValuationEstimate] =1 OR [bResidentialValuationEstimate] = 1)X) AS Est ON TF.CLIENTID = Est.CLIENTID AND Est.YEAR = TF.Year

WHERE TF.YEAR = @TaxYear