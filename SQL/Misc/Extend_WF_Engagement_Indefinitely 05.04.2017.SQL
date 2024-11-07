	USE TaxWFPortalData
	
	/****************************************/
	/*            USER INPUTS               */
	/****************************************/
	DECLARE @OpportunityId INT =		70040431
	DECLARE @ServiceLine NVARCHAR(3) = 'PCC'
	DECLARE @ExpectedYears INT =		6
	DECLARE @FirstTaxYear INT =			2016
	/****************************************/

	DECLARE @SeqEngInstanceId INT
	DECLARE @EngagementInstances INT
	DECLARE @TotalYearsRequested INT
	DECLARE @RemainingYears INT
	DECLARE @PeriodsCreated INT
	DECLARE @SeqFirstTaxYear INT

IF(@OpportunityId IS NULL)
	BEGIN
		PRINT 'Opportunity ID cannot be NULL'
	END
ELSE
	BEGIN
		IF(@ServiceLine = 'GMS')
			BEGIN
				SET @SeqEngInstanceId = (SELECT SequenceInstanceId FROM Engagements WHERE OpportunityId = @OpportunityId AND BusinessServiceLineId = 3)
				SET @EngagementInstances = (SELECT COUNT(*) FROM [Sequence].[dbo].tblInstanceWorkflows WHERE fldCompletionDate IS NULL AND fldId = @SeqEngInstanceId)
				SET @TotalYearsRequested = (SELECT LengthValue FROM [Sequence].[dbo].[UACT4fa794a5131f4051a1085abaf6303419] WHERE fldiwfid = @SeqEngInstanceId)
				SET @RemainingYears = (SELECT EngagementYearsRemaining FROM [Sequence].[dbo].[UWFc290eda2ea4a4d10aae393cd9755d309] WHERE OpportunityId = @OpportunityId AND ServiceLineId = 3 AND fldIWfId = @SeqEngInstanceId)
				SET @PeriodsCreated = (SELECT Count(*) FROM [Sequence].[dbo].[tblInstanceActivities] WHERE fldInstanceWfId = @SeqEngInstanceId AND fldTemplateActivityGuid = 'bbd0d9f2-53ba-4e1c-ae70-c0a1cc8d30d8')
				SET @SeqFirstTaxYear = (SELECT FirstTaxYear FROM [Sequence].[dbo].[UACT4fa794a5131f4051a1085abaf6303419] WHERE fldiwfid = @SeqEngInstanceId)
			END
		ELSE IF(@ServiceLine = 'PCC')
			BEGIN 
				SET @SeqEngInstanceId = (SELECT SequenceInstanceId FROM Engagements WHERE OpportunityId = @OpportunityId AND BusinessServiceLineId = 2)
				SET @EngagementInstances = (SELECT COUNT(*) FROM [Sequence].[dbo].tblInstanceWorkflows WHERE fldCompletionDate IS NULL AND fldId = @SeqEngInstanceId)
				SET @TotalYearsRequested = (SELECT LengthValue FROM [Sequence].[dbo].[UACT30482307f98f43e0be104b62bf553f45] WHERE fldiwfid = @SeqEngInstanceId)
				SET @RemainingYears = (SELECT EngagementYearsRemaining FROM [Sequence].[dbo].[UWF4a5eadb0cd0b419db25fff8b1ffe931d] WHERE OpportunityId = @OpportunityId AND ServiceLineId = 2 AND fldIWfId = @SeqEngInstanceId)
				SET @PeriodsCreated = (SELECT Count(*) FROM [Sequence].[dbo].[tblInstanceActivities] WHERE fldInstanceWfId = @SeqEngInstanceId AND fldTemplateActivityGuid = 'c9b9647d-2f78-45a2-a4d9-7de6b95905c8')
				SET @SeqFirstTaxYear = (SELECT FirstTaxYear FROM [Sequence].[dbo].[UACT30482307f98f43e0be104b62bf553f45] WHERE fldiwfid = @SeqEngInstanceId)
			END
		ELSE IF(@ServiceLine = 'CTC')
			BEGIN 
				SET @SeqEngInstanceId = (SELECT SequenceInstanceId FROM Engagements WHERE OpportunityId = @OpportunityId AND BusinessServiceLineId = 1)
				SET @EngagementInstances = (SELECT COUNT(*) FROM [Sequence].[dbo].tblInstanceWorkflows WHERE fldCompletionDate IS NULL AND fldId = @SeqEngInstanceId)
				SET @TotalYearsRequested = (SELECT LengthValue FROM [Sequence].[dbo].[UACT553322df03b543fe88e7db070837feb7] WHERE fldiwfid = @SeqEngInstanceId)
				SET @RemainingYears = (SELECT LengthOfEngagement FROM [Sequence].[dbo].[UWF2f79e39050924fa081fdff52b919bdef] WHERE OpportunityId = @OpportunityId AND ServiceLineId = 1 AND fldIWfId = @SeqEngInstanceId)
				SET @PeriodsCreated = (SELECT Count(*) FROM [Sequence].[dbo].[tblInstanceActivities] WHERE fldInstanceWfId = @SeqEngInstanceId AND fldTemplateActivityGuid = '2a592bce-6580-469c-b426-dcea71626688')
				SET @SeqFirstTaxYear = DATEPART(yyyy,(SELECT YearEndDate FROM [Sequence].[dbo].[UACT553322df03b543fe88e7db070837feb7] WHERE fldiwfid = @SeqEngInstanceId))
			END

		IF (@ExpectedYears < 1)
			BEGIN
				PRINT 'The length of an engagement must be greater than 0'
			END	
		ELSE IF(@SeqEngInstanceId IS NULL)
			BEGIN
				PRINT 'Engagement with opportunity ID '+CONVERT(NVARCHAR(10),@OpportunityId)+' and service line "'+@ServiceLine+'" not found.'
			END	
		ELSE IF(@EngagementInstances = 0)
			BEGIN
				PRINT 'Engagement process (' +CONVERT(NVARCHAR(50),@SeqEngInstanceId)+ ') already completed.'
			END
		ELSE IF(@FirstTaxYear <> @SeqFirstTaxYear)
			BEGIN
				PRINT 'First tax year provided ('+CONVERT(NVARCHAR(15),@FirstTaxYear)+') does not match the first tax year on this engagement.'
			END
		ELSE IF (@ExpectedYears = @TotalYearsRequested)
			BEGIN
				PRINT 'NO CHANGES MADE...  The engagement is configured with the correct number of periods.'
			END
		ELSE IF (@ExpectedYears = (@RemainingYears+@PeriodsCreated))
			BEGIN
				PRINT 'NO CHANGES MADE...  The number of years remaining are as expected'
			END
		ELSE IF ((@ExpectedYears - @PeriodsCreated)<0)
			BEGIN 
				PRINT 'NO CHANGES MADE...  More periods have been started than you are requesting.'
			END
		ELSE 
			BEGIN
				IF(@ServiceLine = 'GMS')
					BEGIN
						UPDATE [Sequence].[dbo].[UACT4fa794a5131f4051a1085abaf6303419] 
						SET LengthValue = @ExpectedYears
						WHERE fldiwfid = @SeqEngInstanceId
						PRINT 'Engagement Length Updated.'
						UPDATE [Sequence].[dbo].[UWFc290eda2ea4a4d10aae393cd9755d309] 
						SET EngagementYearsRemaining = (@ExpectedYears - @PeriodsCreated)
						WHERE OpportunityId = @OpportunityId AND ServiceLineId = 3 AND fldIWfId = @SeqEngInstanceId
						PRINT CONVERT(NVARCHAR(2),(@ExpectedYears - @PeriodsCreated))+' year(s) remaining on the engagement.'
					END
				ELSE IF(@ServiceLine = 'PCC')
					BEGIN
						UPDATE [Sequence].[dbo].[UACT30482307f98f43e0be104b62bf553f45] 
						SET LengthValue = @ExpectedYears
						WHERE fldiwfid = @SeqEngInstanceId
						PRINT 'Engagement Length Updated.'
						UPDATE [Sequence].[dbo].[UWF4a5eadb0cd0b419db25fff8b1ffe931d] 
						SET EngagementYearsRemaining = (@ExpectedYears - @PeriodsCreated)
						WHERE OpportunityId = @OpportunityId AND ServiceLineId = 2 AND fldIWfId = @SeqEngInstanceId
						PRINT CONVERT(NVARCHAR(2),(@ExpectedYears - @PeriodsCreated))+' years remaining on the engagement.'
					END
				ELSE IF(@ServiceLine = 'CTC')
					BEGIN
						UPDATE [Sequence].[dbo].[UACT553322df03b543fe88e7db070837feb7] 
						SET LengthValue = @ExpectedYears
						WHERE fldiwfid = @SeqEngInstanceId
						PRINT 'Engagement Length Updated.'
						UPDATE [Sequence].[dbo].[UWF2f79e39050924fa081fdff52b919bdef] 
						SET LengthOfEngagement = (@ExpectedYears - @PeriodsCreated)
						WHERE OpportunityId = @OpportunityId AND ServiceLineId = 1 AND fldIWfId = @SeqEngInstanceId
						PRINT CONVERT(NVARCHAR(2),(@ExpectedYears - @PeriodsCreated))+' years remaining on the engagement.'
					END
				ELSE
					BEGIN
						PRINT 'ERROR... Upadate not configured.'
					END

				DECLARE @instruction NVARCHAR(255) = ''
				SELECT @instruction =
				CASE 
					WHEN 
						(@RemainingYears > (@ExpectedYears - @PeriodsCreated) AND (@ExpectedYears - @PeriodsCreated) =0)
					THEN 
						'Debug the '+@ServiceLine+' Engagement process (' +CONVERT(NVARCHAR(50),@SeqEngInstanceId)+ ') and rollback to the last instance of the "Decrement Year Count" activity and click continue.'			
					WHEN 
						(@RemainingYears < (@ExpectedYears - @PeriodsCreated) AND @RemainingYears = 0)
					THEN 
						'Debug the '+@ServiceLine+' Engagement process (' +CONVERT(NVARCHAR(50),@SeqEngInstanceId)+ ') and rollback to the last instance of the "Decrement Year Count" activity and click continue.'
					ELSE
						'None.'
				END

				PRINT 'NEXT STEPS... ' + @instruction
			END
		END