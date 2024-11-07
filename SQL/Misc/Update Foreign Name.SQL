/* ------------------------------------------------------------------------------------ */
/* REQUIRED: Inputs for Updating Client names in System Links.                          */
/* ------------------------------------------------------------------------------------ */

--Client Details Identifier
DECLARE @clientId INT = 0
--System Code
DECLARE @foreignCode NVARCHAR(100) = 'SYSTEM CODE'	
--New Name	
DECLARE @newForeignName NVARCHAR(255) = 'NEW NAME'
DECLARE @linkTypeId INT = 0  
/*
LINK TYPES
1 = SAP
2 = Digita
3 = Alphatax
4 = Atlas
5 = GTS
6 = IESClient
7 = SAPWorksite
8 = PartnerId
*/
/* ------------------------------------------------------------------------------- */

IF (EXISTS(SELECT * FROM Links WHERE ClientId = @clientId and ForeignCode = @foreignCode and LinkTypeId = @linkTypeId))
BEGIN
	UPDATE Links
	SET
		ForeignName = @newForeignName
	WHERE
		ClientId = @clientId and ForeignCode = @foreignCode and LinkTypeId = @linkTypeId
		
	PRINT 'Updated Client '+ CONVERT(NVARCHAR(100), @clientId) + ' Link Type ' + CONVERT(NVARCHAR(100),@linkTypeId) + '. New Foreign Name is ' + @newForeignName
END
ELSE
BEGIN
	PRINT 'No link type ' + CONVERT(NVARCHAR(100),@linkTypeId) + ' found for Client Id '+ CONVERT(NVARCHAR(100), @clientId) + ' with a Forein Code of ' + @foreignCode
END

