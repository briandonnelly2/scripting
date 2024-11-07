USE [Sequence]

/**
	PURPOSE: Enter process ID to see details about this workflow as well as all child workflows and activities spawned from this process

	MAIN INPUTS:	@MainProcessID	- The sequence instance ID	-	This can be from engagement down to workitem and sub-workflows but must
																	be a sequence instance ID for a WORKFLOW not an activity
					@WorkItemID		- The workitem ID			-	Can be obtained from the management dashboard.

**/

DECLARE @MainProcessID INT = 9730517
DECLARE @WorkItemID INT = 286903

/** Returns the active main Workflow process for the instance given in @MainProcessID **/
SELECT   iw.fldId AS 'InstanceID'
		,'Workflow' AS 'InstanceType'
		,'Active' AS 'State'
		,'Parent' AS 'ProcessType'
		,'No' AS 'Rollback'
		,tw.fldName AS 'Workflow Description'
		,iw.fldSourceIWfId AS 'SrcInstID'
		,iw.fldCreationDate AS 'DateCreated'
		,iw.fldLastRedirectDate AS 'LastRedirected'
		,iw.fldNextRedirectDate AS 'NextRedirectDate'
		,iw.fldCompletionDate AS 'DateCompleted'
		,NULL AS 'RolledBackDate'
		,NULL AS 'RolledBackBy'

		FROM tblInstanceWorkflows AS iw
			INNER JOIN tblTemplateWorkflows AS tw ON tw.fldGuid = iw.fldTemplateWfGuid
		WHERE iw.fldId = @MainProcessID 

			UNION --Joins to next query...

/** Returns the active child Workflow processes for the instance given in @MainProcessID **/
SELECT   iw2.fldId AS 'InstanceID'
		,'Workflow' AS 'InstanceType'
		,'Active' AS 'State'
		,'Child' AS 'ProcessType'
		,'No' AS 'Rollback'
		,tw2.fldName AS 'Workflow Description'
		,iw2.fldSourceIWfId AS 'SrcInstID'
		,iw2.fldCreationDate AS 'DateCreated'
		,iw2.fldLastRedirectDate AS 'LastRedirected'
		,iw2.fldNextRedirectDate AS 'NextRedirectDate'
		,iw2.fldCompletionDate AS 'DateCompleted'
		,NULL AS 'RolledBackDate'
		,NULL AS 'RolledBackBy'

		FROM tblInstanceWorkflows AS iw2
			INNER JOIN tblTemplateWorkflows AS tw2 ON tw2.fldGuid = iw2.fldTemplateWfGuid
		WHERE iw2.fldSourceIWfId = @MainProcessID

			UNION --Joins to next query...

/** Returns the closed main Workflow process for the instance given in @MainProcessID **/
SELECT   iwc.fldId AS 'InstanceID'
		,'Workflow' AS 'InstanceType'
		,'Closed' AS 'State'
		,'Parent' AS 'ProcessType'
		,'No' AS 'Rollback'
		,tw3.fldName AS 'Workflow Description'
		,iwc.fldSourceIWfId AS 'SrcInstID'
		,iwc.fldCreationDate AS 'DateCreated'
		,iwc.fldLastRedirectDate AS 'LastRedirected'
		,iwc.fldNextRedirectDate AS 'NextRedirectDate'
		,iwc.fldCompletionDate AS 'DateCompleted'
		,NULL AS 'RolledBackDate'
		,NULL AS 'RolledBackBy'

		FROM tblInstanceWorkflowsClosed AS iwc
			INNER JOIN tblTemplateWorkflows AS tw3 ON tw3.fldGuid = iwc.fldTemplateWfGuid
		WHERE iwc.fldId = @MainProcessID 

			UNION --Joins to next query...

/** Returns the closed child Workflow processes for the instance given in @MainProcessID **/
SELECT   iwc2.fldId AS 'InstanceID'
		,'Workflow' AS 'InstanceType'
		,'Closed' AS 'State'
		,'Child' AS 'ProcessType'
		,'No' AS 'Rollback'
		,tw4.fldName AS 'Workflow Description'
		,iwc2.fldSourceIWfId AS 'SrcInstID'
		,iwc2.fldCreationDate AS 'DateCreated'
		,iwc2.fldLastRedirectDate AS 'LastRedirected'
		,iwc2.fldNextRedirectDate AS 'NextRedirectDate'
		,iwc2.fldCompletionDate AS 'DateCompleted'
		,NULL AS 'RolledBackDate'
		,NULL AS 'RolledBackBy'

		FROM tblInstanceWorkflowsClosed AS iwc2
			INNER JOIN tblTemplateWorkflows AS tw4 ON tw4.fldGuid = iwc2.fldTemplateWfGuid
		WHERE iwc2.fldSourceIWfId = @MainProcessID

			UNION --Joins to next query...

/** Returns the active rolled back main Workflow process for the instance given in @MainProcessID **/
SELECT   iwrb.fldId AS 'InstanceID'
		,'Workflow' AS 'InstanceType'
		,'Active' AS 'State'
		,'Parent' AS 'ProcessType'
		,'Yes' AS 'Rollback'
		,tw5.fldName AS 'Workflow Description'
		,iwrb.fldSourceIWfId AS 'SrcInstID'
		,iwrb.fldCreationDate AS 'DateCreated'
		,iwrb.fldLastRedirectDate AS 'LastRedirected'
		,NULL AS 'NextRedirectDate'
		,iwrb.fldCompletionDate AS 'DateCompleted'
		,iwrb.fldRollbackDate AS 'RolledBackDate'
		,iwrb.fldRollbackBy AS 'RolledBackBy'

		FROM tblInstanceWorkflowsRollback AS iwrb  
			INNER JOIN tblTemplateWorkflows AS tw5 ON tw5.fldGuid = iwrb.fldTemplateWfGuid
		WHERE iwrb.fldId = @MainProcessID

			UNION --Joins to next query...

/** Returns the acive rolled back child Workflow process for the instance given in @MainProcessID **/
SELECT   iwrb2.fldId AS 'InstanceID'
		,'Workflow' AS 'InstanceType'
		,'Active' AS 'State'
		,'Child' AS 'ProcessType'
		,'Yes' AS 'Rollback'
		,tw6.fldName AS 'Workflow Description'
		,iwrb2.fldSourceIWfId AS 'SrcInstID'
		,iwrb2.fldCreationDate AS 'DateCreated'
		,iwrb2.fldLastRedirectDate AS 'LastRedirected'
		,NULL AS 'NextRedirectDate'
		,iwrb2.fldCompletionDate AS 'DateCompleted'
		,iwrb2.fldRollbackDate AS 'RolledBackDate'
		,iwrb2.fldRollbackBy AS 'RolledBackBy'

		FROM tblInstanceWorkflowsRollback AS iwrb2  
			INNER JOIN tblTemplateWorkflows AS tw6 ON tw6.fldGuid = iwrb2.fldTemplateWfGuid
		WHERE iwrb2.fldSourceIWfId = @MainProcessID

			UNION --Joins to next query...

/** Returns the rolled back main Workflow process for the instance given in @MainProcessID **/
SELECT   iwrbc.fldId AS 'InstanceID'
		,'Workflow' AS 'InstanceType'
		,'Closed' AS 'State'
		,'Parent' AS 'ProcessType'
		,'Yes' AS 'Rollback'
		,tw7.fldName AS 'Workflow Description'
		,iwrbc.fldSourceIWfId AS 'SrcInstID'
		,iwrbc.fldCreationDate AS 'DateCreated'
		,iwrbc.fldLastRedirectDate AS 'LastRedirected'
		,NULL AS 'NextRedirectDate'
		,iwrbc.fldCompletionDate AS 'DateCompleted' 
		,iwrbc.fldRollbackDate AS 'RolledBackDate'
		,iwrbc.fldRollbackBy AS 'RolledBackBy'
		
		FROM tblInstanceWorkflowsRollbackClosed AS iwrbc
			INNER JOIN tblTemplateWorkflows AS tw7 ON tw7.fldGuid = iwrbc.fldTemplateWfGuid
		WHERE iwrbc.fldId = @MainProcessID

			UNION --Joins to next query...

/** Returns the rolled back main Workflow process for the instance given in @MainProcessID **/
SELECT   iwrbc.fldId AS 'InstanceID'
		,'Workflow' AS 'InstanceType'
		,'Closed' AS 'State'
		,'Child' AS 'ProcessType'
		,'Yes' AS 'Rollback'
		,tw8.fldName AS 'Workflow Description'
		,iwrbc.fldSourceIWfId AS 'SrcInstID'
		,iwrbc.fldCreationDate AS 'DateCreated'
		,iwrbc.fldLastRedirectDate AS 'LastRedirected'
		,NULL AS 'NextRedirectDate'
		,iwrbc.fldCompletionDate AS 'DateCompleted' 
		,iwrbc.fldRollbackDate AS 'RolledBackDate'
		,iwrbc.fldRollbackBy AS 'RolledBackBy'
		
		FROM tblInstanceWorkflowsRollbackClosed AS iwrbc
			INNER JOIN tblTemplateWorkflows AS tw8 ON tw8.fldGuid = iwrbc.fldTemplateWfGuid
		WHERE iwrbc.fldSourceIWfId = @MainProcessID
