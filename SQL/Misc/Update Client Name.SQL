/* ------------------------------------------------------------------------------------ */
/* REQUIRED: Inputs for Updating Client names in Client admin and Management Dashboard. */
/* ------------------------------------------------------------------------------------ */
--Portal Client ID
DECLARE @clientId INT = 0
DECLARE @oldClientName NVARCHAR(255) = 'OLD'
DECLARE @newClientName NVARCHAR(255) = 'New'


/* ------------------------------------------------------------------------------------ */

IF (EXISTS(SELECT * FROM Clients WHERE ClientId = @clientId and ClientName = @oldClientName))
BEGIN
	UPDATE Clients
	SET
		ClientName = @newClientName
	WHERE
		ClientId = @clientId and ClientName = @oldClientName
		
	PRINT 'Updated Client '+ CONVERT(NVARCHAR(100), @clientId) + '. New Client Name is ' + @newClientName
END
ELSE
BEGIN
	PRINT 'No client found for Id '+ CONVERT(NVARCHAR(100), @clientId) + ' with a Client Name of ' + @oldClientName
END

