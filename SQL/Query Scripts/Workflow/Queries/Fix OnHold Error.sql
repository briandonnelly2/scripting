-- This script is used for populating missing on hold type ids after receiving 'Helpdesk Error Putting Work Item On Hold' task

-- PCC Client        - TypeId 6
-- PCC Partnership   - TypeId 7

-- PA  Client        - TypeId 9
-- PA  Paternship   - TypeId 10

--------------------------------------------------------------------
-------------------- USER INPUT FIELDS -----------------------------  


DECLARE @TypeId				INT = 6
DECLARE @HelpdeskProcessId	INT = 5623110

--------------------------------------------------------------------
USE [Sequence]

BEGIN TRAN

UPDATE	UWF73cbe5a4529e4fe792880b39def644db
SET		OnHoldTypeId = @TypeId
WHERE	fldIWfId = @HelpdeskProcessId

SELECT	*
FROM	UWF73cbe5a4529e4fe792880b39def644db
WHERE	fldIWfId = @HelpdeskProcessId

COMMIT TRAN 