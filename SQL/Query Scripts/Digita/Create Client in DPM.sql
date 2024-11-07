/**
DPM Client Access GUID's
--------------------------
IESHOPSOff		= '15FAACCB-EDBC-4C36-9B7A-9EBA2703D4EA'
IESHOPSUK		= '89F6A1AC-C31E-40A6-A4AB-936572ADAF55'

PCCOffshore		= 'F9DD3D47-5E95-439F-B8F6-CEE2CBE1267B'
PCCUK			= '7238B024-0AF3-44BA-85B5-7BDE668F1B36'
Restricted		= '68FF4486-5C46-456D-9A29-0F11180FCBEC'
SBAUK			= '8919E018-70C5-418D-8BCD-03621741332E'
**/

DECLARE @IESOffshore NVARCHAR(100)				= '14AC79DF-25FE-4212-9223-681104FA4179'
DECLARE @IESUK NVARCHAR(100)						= '132C0767-1997-4D45-9994-9DEF49B3DA8E'

DECLARE @AgentDPMUserID NVARCHAR(100)				= 'UK\briandonnelly2'

DECLARE @DPMAccessGroupGUID NVARCHAR(100)			= ( 
														CASE @ClientAccessGroupId
														WHEN 3 THEN CAST(@IESUK AS INT)
														WHEN 4 THEN CAST(@IESOffshore AS INT)
														ELSE 0 END 
													  )
--Create client in DPM
INSERT INTO DigitaTax.PracticeManagementCoE.dbo.BillableEntity (BillableEntityID, DateModified, IsProspect, IsProfessionalContact, LastModifiedBy, FileAs, ClientCode, AllServices)
VALUES(NEWID(), GETDATE(), 0, 0, @AgentDPMUserID, @ClientName, @AtlasID, 0)

--Add client access groups in DPM
INSERT INTO DigitaTax.PracticeManagementCoE.dbo.ClientGroupBillableEntity (ClientGroupID, BillableEntityID)
VALUES (@IESOffshore, @BillableEntityID)