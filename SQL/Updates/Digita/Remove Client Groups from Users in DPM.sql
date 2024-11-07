/****** Script for SelectTopNRows command from SSMS  ******/
USE [PracticeManagementSecure1]

SELECT 
u.[Username]
	  ,cgu.UserID
  FROM [User] AS u
  LEFT JOIN [ClientGroupUser] AS cgu ON cgu.userID = u.UserID
  WHERE cgu.ClientGroupID = '177436B2-FA69-44AD-94E1-3719C27AE312'

  --returns 119 rows

  AND u.Username IN (
'UK\aakram',
'UK\agreer'
  )

  BEGIN TRAN

--  DELETE FROM [ClientGroupUser] 
--  WHERE UserID IN (
--'153E9981-66E3-480F-B19B-00FBD5040125',
--'4DDEFD0C-92CC-425E-81F7-0E057685811D'
--  )

--  AND ClientGroupID = '177436B2-FA69-44AD-94E1-3719C27AE312' --PA Offshore GUID

--  ROLLBACK
--  --COMMIT