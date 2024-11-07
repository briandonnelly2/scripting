--Tax Compliance
USE [Sequence]

SELECT ta.fldName, uwf.*, ia.*, ai.* FROM UWF84292670fea44c8ab652ffefd6362396 uwf

INNER JOIN tblInstanceActivities ia ON ia.fldInstanceWfId = uwf.fldIWfId AND ia.fldTemplateActivityGuid = 'cb31d0e8-5e35-40a1-aa29-0a70f56ebe10'
INNER JOIN tblTemplateActivities ta ON ta.fldGuid = ia.fldTemplateActivityGuid AND ia.fldStatus = 2
INNER JOIN tblActionItems ai ON ai.fldIActId = ia.fldId

WHERE uwf.WorkItemYear = '2019' AND uwf.RejectionType = 'From 1st Review' --AND iw.fldCompletionDate IS NOT NULL

--UPDATE UWF84292670fea44c8ab652ffefd6362396
--SET OffshoreReviewerSequenceUserId = OffshorePreparerSequenceUserId, OffshoreReviewerName= OffshorePreparerName
--WHERE fldIWfId = 341184

--Partner's Workflow
--USE [SequencePA]

--SELECT ta.fldName, uwf.*, ia.*, ai.* FROM UWF582d08854a224847827770e6b77943e9 uwf

--INNER JOIN tblInstanceActivities ia ON ia.fldInstanceWfId = uwf.fldIWfId AND ia.fldTemplateActivityGuid = '1d5de46c-3e1f-48b4-a98d-c54d88aa8d6a'
--INNER JOIN tblTemplateActivities ta ON ta.fldGuid = ia.fldTemplateActivityGuid AND ia.fldStatus = 2
--INNER JOIN tblActionItems ai ON ai.fldIActId = ia.fldId

--WHERE uwf.WorkItemYear = '2019' AND uwf.RejectionType = 'From 1st Review'

--UPDATE UWF582d08854a224847827770e6b77943e9
--SET OffshorePreparerSequenceUserId = '3264', OffshorePreparerName = 'ukrcschandna'
--WHERE fldIWfId = 337414