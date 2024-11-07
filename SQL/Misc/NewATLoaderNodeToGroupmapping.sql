USE [ATLoaderProd]

SELECT dng.[Id]
      ,dng.[UserGroupId]
	  ,ug.GroupName
      ,dng.[AlphataxDatabaseNodeId]
	  ,dn.[Description]
      ,dng.[IsDeleted]
      ,dng.[IsReadOnly]
	  ,dn.ParentNodeId
  FROM [ATLoaderProd].[dbo].[DatabaseNodeGroup] AS dng
  INNER JOIN UserGroup AS ug ON dng.UserGroupId = ug.Id
  INNER JOIN DatabaseNode AS dn ON dng.AlphataxDatabaseNodeId = dn.Id