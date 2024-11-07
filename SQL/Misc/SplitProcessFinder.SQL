select  top 10 fldTemplateActivityGuid,fldInstanceWfId, COUNT(*) from tblInstanceActivities 
where fldCompletionDate is null
AND fldTemplateActivityGuid in
								(
								SELECT top 2000 fldGuid
								FROM tblTemplateActivities
								WHERE fldType IN (select distinct(fldGuid) from tblActivityTypes where fldType LIKE '%Task%')
								 )
group by fldTemplateActivityGuid, fldInstanceWfId
having COUNT(*) > 1
