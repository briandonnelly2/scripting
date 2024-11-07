USE [Sequence]

SELECT 
    
  sum(  p.rows ) as NumberOfCases 
FROM 
    sys.tables t
INNER JOIN      
    sys.indexes i ON t.OBJECT_ID = i.object_id
INNER JOIN 
    sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id

WHERE 
  (  t.NAME   LIKE 'USL%Cases'  and t.NAME not like '%allocatedCases') or t.NAME  = 'tblSolutionCases'  or t.NAME  = 'tblSolutionCasesClosed'  
    
select sum(c) as NumberOfInstances from (
select count (*)as c from tblInstanceWorkflows 
union
select count(*) as c from tblInstanceWorkflowsClosed
) t


SELECT

CAST(ROUND((SUM(a.total_pages) / 128.00), 2) AS NUMERIC(36, 2)) AS MB_Without_Attachments
FROM sys.tables t
INNER JOIN sys.indexes i ON t.OBJECT_ID = i.object_id
INNER JOIN sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
where t.Name not like '%tbltemplate%'  and t.Name not like '%attachment%'


SELECT

CAST(ROUND((SUM(a.total_pages) / 128.00), 2) AS NUMERIC(36, 2)) AS MB_Attachments
FROM sys.tables t
INNER JOIN sys.indexes i ON t.OBJECT_ID = i.object_id
INNER JOIN sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
where t.Name  like '%attachment%'
