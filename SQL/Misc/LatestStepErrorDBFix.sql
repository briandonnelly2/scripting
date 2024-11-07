use [TaxWFReviewToolDataPA]
select *
from Document d 
inner join documentversion dv on dv.documentid = d.id
inner join ReviewStep rs on rs.DocumentVersionId = dv.id
where d.id = '338880525'


--declare @ReviewStepId int
--set @ReviewStepId = 2079
--declare @SubmittedDate datetime
--set @SubmittedDate = GETDATE()
--declare @SubmittedBy nvarchar(20)
--set @SubmittedBy = 'helpdesk'

--update reviewstep set IsSubmitted = 1, SubmittedBy = @SubmittedBy, SubmittedTimeStamp = @SubmittedDate
--where id = @ReviewStepId

--/****** Script for SelectTopNRows command from SSMS  ******/
--SELECT TOP (1000) [Id]
--      ,[StepNumber]
--      ,[DocumentVersionId]
--      ,[IsSubmitted]
--      ,[RoleId]
--      ,[CreatedTimeStamp]
--      ,[SubmittedBy]
--      ,[SubmittedTimeStamp]
--      ,[RoleLevelId]
--  FROM [TaxWFReviewToolDataPA].[dbo].[ReviewStep]
--  WHERE Id = 2157