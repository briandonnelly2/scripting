USE [PracticeManagementCoE]
/****** 

	This script will check to see what the CanViewAllClients flag is in the above DPM database
	for a particular user that you enter in the @Username variable below.  You must keep the 
	UK\ prefix before the username as this is how it is stored in the DPM database table.

	If a record is found, it is diplayed with the username and the CanViewAllClients flag.
	0 means user cannot view all clients, 1 means they can.  If you wish to change the flag
	enter what you wish to enter it in the @CanViewAllClients variable below.  

	Uncomment out the rest of the script,noting that COMMIT should still be commented out and run again.
	If the output appears as you would like it to be, uncomment COMMIT and comment out ROLLBACK to commit
	the change to the database.

******/

DECLARE @Username NVARCHAR(256) = 'UK\jmoore8' --Enter the username you want check/update
DECLARE @CanViewAllClients BIT = 1 --Enter the value you wish to be set for CanViewAllClients

--BEGIN TRAN

--UPDATE [User]

--SET CanViewAllClients = @CanViewAllClients

--WHERE Username = @Username

SELECT [Username],[CanViewAllClients] FROM [User] WHERE Username = @Username

--ROLLBACK
----COMMIT