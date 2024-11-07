




--USE [PracticeManagement_TaxAid]
--GO
--EXEC AddUserToClientGroup @username = 'UK\rullah1', @groupname = 'Assistants'
--EXEC AddUserToClientGroup @username = 'UK\rullah1', @groupname = 'Managers'
--EXEC AddUserToClientGroup @username = 'UK\rullah1', @groupname = 'Partners'
--EXEC AddUserToClientGroup @username = 'UK\rullah1', @groupname = 'Seniors'
--EXEC AddUserToClientGroup @username = 'UK\rullah1', @groupname = 'Trainees'




--select U.username, CG.name
--From ClientGroup CG
--Inner join ClientGroupUser CGU on CG.ClientGroupID = CGU.ClientGroupID
--Inner join [User] U on CGU.userid = U.userid
--where u.username = 'UK\rullah1'
--Order by username
