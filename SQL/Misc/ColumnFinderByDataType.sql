SELECT
OBJECT_NAME(c.OBJECT_ID) TableName
,c.name AS ColumnName
,SCHEMA_NAME(t.schema_id) AS SchemaName
,t.name AS TypeName
,t.is_user_defined
,t.is_assembly_type
,c.max_length
,c.PRECISION
,c.scale
FROM sys.columns AS c
JOIN sys.types AS t ON c.user_type_id=t.user_type_id
where t.name = 'bit' --change this to the type you're looking for
and c.name like '%foreign%'
ORDER BY c.name;

--use TaxywinCOE
--go

--select top 5 * from OtherForeignIncome
--where CLIENTID=121652884