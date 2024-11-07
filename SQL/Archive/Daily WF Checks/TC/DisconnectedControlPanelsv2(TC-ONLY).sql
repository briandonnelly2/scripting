/**
	Finds client period conmtrol panels that are out of sync and automatically fixes these.
**/

USE [Sequence]

DECLARE @RowCount int

SELECT @RowCount = COUNT(ia.fldId)

	FROM (
		SELECT ia.fldInstanceWfId, MAX(ia.fldId) fldId
            
			FROM tblInstanceActivities ia
    
			WHERE ia.fldTemplateActivityGuid = '51753b32-4eb7-44f9-b991-c1d0934a7604' --Client Period Control Panel
            
			GROUP BY ia.fldInstanceWfId
	) AS ia

	INNER JOIN tblInstanceWorkflowsDataPropagation v ON ia.fldInstanceWfId = v.fldIWfId

	WHERE ISNULL(v.ControlPanelInstanceId, 0) <> ia.fldId

    PRINT CONVERT(NVARCHAR(255), @RowCount) + ' control panels are out of sync.'


DECLARE @controlpanelId int, @IwfId int
DECLARE cp_cursor CURSOR FOR 

SELECT ia.fldId, ia.fldInstanceWfId
	FROM (
		SELECT ia.fldInstanceWfId, MAX(ia.fldId) fldId
            
			FROM tblInstanceActivities ia
            
			WHERE ia.fldTemplateActivityGuid = '51753b32-4eb7-44f9-b991-c1d0934a7604' --Client Period Control Panel
            
			GROUP BY ia.fldInstanceWfId
      ) AS ia
	
	INNER JOIN tblInstanceWorkflowsDataPropagation v on ia.fldInstanceWfId = v.fldIWfId

	WHERE ISNULL(v.ControlPanelInstanceId, 0) <> ia.fldId

	OPEN cp_cursor

	FETCH NEXT FROM cp_cursor
	
	INTO @controlpanelId, @IwfId

	WHILE @@FETCH_STATUS = 0
		BEGIN
			UPDATE tblInstanceWorkflowsDataPropagation 
			SET ControlPanelInstanceId = @controlpanelId WHERE fldiwfid = @IwfId
			
			UPDATE UWFfa14bc632fcd462ab88bff03a3757948 
			SET controlpanelinstanceid = @controlpanelid 
			WHERE fldiwfid = @iwfid
			
			PRINT 'Control panel reconnected for ' + CONVERT (NVARCHAR(100),@iwfid)

			FETCH NEXT FROM cp_cursor 
    
			INTO @controlpanelId, @IwfId
		END 

	CLOSE cp_cursor;

	DEALLOCATE cp_cursor;
