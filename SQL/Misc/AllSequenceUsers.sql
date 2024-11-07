USE [Sequence]

SELECT [fldEmployeeId]
      ,[fldEmpName]
      ,[fldEmpLastName]
      ,[fldEmpUseName]
      ,[fldEmail]
      ,[fldGroup]
      ,[fldId]
      ,[fldGlobalAdmin]
      ,[fldDeveloper]
      ,[fldActive]
      ,[fldIsFromAD]
      ,[whenChanged]
      ,[employeeID]
      ,[extensionAttribute13]
  FROM tblEmployees
  WHERE fldGlobalAdmin = 1
  ORDER BY fldGlobalAdmin DESC, fldActive DESC