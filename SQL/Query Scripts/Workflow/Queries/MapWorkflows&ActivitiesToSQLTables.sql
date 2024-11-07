USE [Sequence]

--Enter workflow name to return associated UACT tables
DECLARE @WorkflowName nvarchar(MAX) = 'xxx'

DECLARE @Names TABLE(TableName nvarchar(MAX), WorkflowGuid uniqueidentifier, ActivityName nvarchar(4000)); 

DECLARE @Aliases TABLE(Alias nvarchar(MAX)); 


INSERT INTO @Names 

SELECT T.C.value('.', 'NVARCHAR(MAX)') AS Alias, fldTWfGuid, fldName 

FROM tblTemplateActivities 

CROSS APPLY tblTemplateActivities.fldProperties.nodes('declare namespace pnmsoft="http://pmnsoft.com/sequence/2008/03/metadata";(/pnmsoft:Properties/pnmsoft:DataModel/pnmsoft:DataSources/pnmsoft:LinqDataSourceDefinition/pnmsoft:Name)') T(c) 

ORDER BY fldGuid ASC 


INSERT INTO @Aliases 

SELECT T.C.value('.', 'NVARCHAR(MAX)') AS TableName 

FROM tblTemplateActivities 

CROSS APPLY tblTemplateActivities.fldProperties.nodes('declare namespace pnmsoft="http://pmnsoft.com/sequence/2008/03/metadata";(/pnmsoft:Properties/pnmsoft:DataModel/pnmsoft:DataSources/pnmsoft:LinqDataSourceDefinition/pnmsoft:TableName)') T(c) 

ORDER BY fldGuid ASC 


;WITH T1 AS (select TableName,WorkflowGuid,ActivityName,ROW_NUMBER()OVER(ORDER BY (SELECT 1))AS ID FROM @Names), 

T2 AS (select Alias,ROW_NUMBER()OVER(ORDER BY (SELECT 1))AS ID FROM @Aliases) 

SELECT TWFS.fldName WFSpace 

,TWF.fldName AS WorkflowName 

,T1.ActivityName 

,T1.TableName 

,T2.Alias AS PhysicalTableName 

FROM T1 FULL JOIN T2 ON(T1.ID=T2.ID) 

INNER JOIN tblTemplateWorkflows TWF ON T1.WorkflowGuid = TWF.fldGuid 

INNER JOIN tblTemplateWorkflowSpaces TWFS ON TWF.fldSpaceGuid = TWFS.fldGuid 

--WHERE TWF.fldName = @WorkflowName

ORDER BY TWFS.fldName 

,TWF.fldName 

,T1.ActivityName 

,T1.TableName 
