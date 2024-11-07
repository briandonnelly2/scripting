/* ------------------------------------------------------------------------------- */
/* REQUIRED:																	   */
/* ActivityId, ActivityGuid (Of the activity you want to remove)																	   */
/* Pull back all the split processes with active duplicate activites		       */
/* ------------------------------------------------------------------------------- */

DECLARE @ActivityInstanceID INT = 0
DECLARE @ActivityGuid varchar(50) = ''
/* ------------------------------------------------------------------------------- */

USE [Sequence]

DECLARE @Count int =(
						SELECT COUNT(*) 
						FROM tblInstanceActivities 
						WHERE fldid = @ActivityInstanceID 
						AND fldTemplateActivityGuid = @ActivityGuid 
						AND fldCompletionDate IS NULL 
					)
IF @Count = 1

	BEGIN
		DELETE FROM tblActionItems WHERE fldIActId = @ActivityInstanceID
		
		PRINT 'All action items for activity id. ' + CONVERT(NVARCHAR(10), @ActivityInstanceID) +' have now been deleted.'
		
		UPDATE tblInstanceActivities 
		SET fldCompletionDate = GETDATE(),
			fldStatus = 5,
			fldRedirectFlag = 0
		WHERE fldid = @ActivityInstanceID
		
		PRINT 'The completion date, activity status and redirect flag has now been updated for activity id. ' + CONVERT(NVARCHAR(10), @ActivityInstanceID) +'.'
		
	END
	ELSE IF @Count > 1
		BEGIN
			PRINT 'Script Aborted: More than one acitvity found. Check inputs.'
		END
	ELSE
		BEGIN
			PRINT 'Script Aborted: No activities found. Check inputs.'
		END
