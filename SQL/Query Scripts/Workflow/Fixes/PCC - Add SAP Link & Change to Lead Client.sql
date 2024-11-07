/**
	This script is used when we are asked to add a SAP link to a PCC client in workflow.

**/

USE [TaxWFPortalData]

SET NOEXEC OFF

/** INPUTS **/
--Workflow Client ID
DECLARE @WFClientID INT = 61896
DECLARE @MSDCode NVARCHAR(100) = '60647762'
DECLARE @ClientName NVARCHAR(100)

SET @ClientName = (SELECT ClientName FROM Clients WHERE ClientId = @WFClientID)


BEGIN TRAN
INSERT INTO Links (LinkTypeId, ForeignId, ClientId, IsPrimaryLink, ForeignName, ForeignCode)
VALUES (1, @MSDCode, @WFClientID, 1, @ClientName, @MSDCode)

UPDATE Links
SET IsPrimaryLink = 0
WHERE ClientId = @WFClientID AND LinkTypeId = 2

SELECT * FROM Links WHERE ClientId = @WFClientID
ROLLBACK
--COMMIT