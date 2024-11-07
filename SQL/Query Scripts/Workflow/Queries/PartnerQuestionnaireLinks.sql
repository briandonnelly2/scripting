--This script returns a list of KPMG partners and their associated, unique questionnaire link
--Input Required - Relevant Tax Year
--To be run on SequencePA database
USE [SequencePA]

DECLARE @TaxYear int = 2019

select 
       v.PrimaryClientName as [Partner Name], 'http://pataxworkflowportal:8080/_layouts/runTime.aspx?messageInstanceId='+ CONVERT(VARCHAR(100), ai.fldId)+'&WfTemplateActivityId=6385b2ac-9733-41f5-b0e5-15458b3f1641' as Link
from
       tblActionItems ai
join
       tblInstanceActivities ia on ai.fldIActId = ia.fldId and ia.fldTemplateActivityGuid = '805db862-5e2e-426b-ade3-e08ef1c7047c'
join
       uwf2827d7eac4f84a5884c19128f4dd4914 v on ia.fldInstanceWfId = v.fldIWfId and v.TaxYear = @TaxYear
ORDER BY
       v.PrimaryClientName
