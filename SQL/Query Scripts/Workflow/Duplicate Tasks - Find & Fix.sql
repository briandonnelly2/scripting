USE [Sequence]

--Enter the main process ID to see all activities for the process
DECLARE @MainProcessID INT = 9683241

SELECT ia.[fldId]
      ,ia.[fldTemplateActivityGuid]
      ,ia.[fldInstanceWfId]
      ,ia.[fldSourceActId]
      ,case ia.[fldStatus]
			when 0 then 'Created'
			when 2 then 'Pending'
			when 3 then 'Executed'
			when 4 then 'Redirected'
			when 5 then 'Completed'
			when 6 then 'Deleted'
			when 7 then 'Rolled Back'
			else 'n/a'
			end AS [Status]
	  ,ta.[fldName]
	  ,ta.[fldAlias]
      ,ia.[fldCreationDate]
      ,ia.[fldLastUpdateDate]
      ,ia.[fldCompletionDate]
      ,ia.[fldRedirectFlag]
  FROM tblInstanceActivities AS ia

  INNER JOIN tblTemplateActivities AS ta ON ia.[fldTemplateActivityGuid] = ta.[fldGuid]

  WHERE ia.[fldInstanceWfId] = @MainProcessID
  AND ia.fldCompletionDate IS NULL
  AND ia.fldStatus = 2
  --AND ia.fldId = 330077814

  ORDER BY ia.[fldCreationDate]

  /* ------------------------------------------------------------------------------- */
/* REQUIRED:																	   */
/* ActivityId, ActivityGuid (Of the activity you want to remove)																	   */
/* Pull back all the split processes with active duplicate activites		       */
/* ------------------------------------------------------------------------------- */

DECLARE @ActivityInstanceID INT = 330133509
DELETE FROM tblActionItems WHERE fldIActId = @ActivityInstanceID
DECLARE @ActivityGuid varchar(50) = '4691B39C-A29E-4801-874E-15D056FBDFB3'
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