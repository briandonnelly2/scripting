/**
	This script will return any tasks that are with inactive users in workflow.
	These have a service line attached to them and we need to find out what should
	be done with them by sending these on an excel spreadsheet to the respective processing teams.
	These will usually either be assigned to someone else or cancelled.
	Send any that are GMS to UK-FM GMS Processing Team
	Send any that are PCC to UK-FM PCC Centre of Excellence Processing Team
	Send any that are transfer pricing to Dhanak, Mitesh <Mitesh.Dhanak@kpmg.co.uk>
	You can cancel workitems from workitem admin using the workitem ID or parent workitme id
	Tasks that need to be reassigned may require more work.
**/

USE [Sequence]

SELECT	 e.fldEmpName
		,e.fldEmpLastName
		,e.fldEmpUseName	
		,wi.ClientID
		,CASE wi.BusinessServiceLineID
			WHEN 1 THEN 'CTC'
			WHEN 2 THEN 'PCC'
			WHEN 3 THEN 'GMS'
			WHEN 4 THEN 'Partnership'
			WHEN 5 THEN 'Transfer Pricing'
			ELSE 'n/a'
			END AS ServiceLine
		,ai.fldSubject 
		,v.WorkItemId 
		,wi.ParentWorkItemId 
		,wi.sequenceInstanceID 
		,iw.fldSourceIWfId

		FROM tblActionItems ai

		INNER JOIN tblEmployees e ON ai.fldToId = e.fldEmployeeId AND e.fldActive = 0
		INNER JOIN tblInstanceActivities ia ON ai.fldIActId = ia.fldId
		INNER JOIN tblInstanceWorkflows iw ON ia.fldInstanceWfId = iw.fldid AND iw.fldstatus NOT IN(7) AND iw.fldCompletionDate IS NULL
		INNER JOIN tblInstanceWorkflowsDataPropagation v ON ia.fldInstanceWfId = v.fldIWfId
		LEFT JOIN TaxWFPortalData.dbo.WorkItems wi ON v.WorkItemId = wi.WorkItemId 	

		WHERE ia.fldID IN (
			SELECT Id
			
			FROM (
				SELECT ai.fldIActId Id, SUM(CONVERT(INT,e.fldActive)) s , Count(e.fldEmployeeId) c
				
				FROM tblActionItems ai 
			
				INNER JOIN tblEmployees e on e.fldEmployeeId = ai.fldToId
			
				WHERE ai.fldIActId IS NOT NULL
			
				GROUP BY ai.fldIActId
			
				HAVING (SUM(CONVERT(INT,e.fldActive)) = Count(e.fldEmployeeId))
				OR (SUM(CONVERT(INT,e.fldActive)) = 0)
		) AS d
	) 
	AND ia.fldCompletionDate IS NULL
	AND fldMessageType = 2
	AND	iw.fldtemplatewfguid NOT IN 
		('CE3443E9-774B-40D9-9883-6314DF215423',
		'8808A673-921F-48F7-8E9A-8ABC1235CA10',
		'41F6BD2A-8C7A-418A-88B5-158B63431E24',
		'CA5D3915-0099-442C-B821-09286A66A808',
		'0C81A766-9FF8-4383-B29C-2F4A2CF190FC',
		'0900F710-494E-4B55-9923-7B70AB1592CB',
		'377E23BB-D56B-495F-8960-5B6728150607',
		'6D356B46-2115-4F32-AA2E-292938054170',
		'898E8C5F-0ED8-46E0-A0F3-9CD1D3E8B704',
		'A412A0C5-9EE5-4710-BAE1-15047A77C8DE',
		'F8C5645C-9643-499E-9D4F-0888F0FBD1C6',
		'82726CE1-4765-4320-816C-5E68B3365AA8',
		'73037547-11AA-456B-9B09-C3B918F928B8',
		'9269F421-257F-4EDA-A1F5-91EDA537591E',
		'29ECDA92-A74A-4EE3-A97B-CD490CC6F126',
		'17BC9AEF-9812-406E-980D-C16F2B875204',
		'2E37BDEE-C08A-4E34-9719-4A9DDAC5A72E',
		'BD9A5532-A7E4-4A4B-9339-FE65298F06D2',
		'7C2AADF1-1506-46B1-BD98-AFDDB5DECF3D',
		'6E17AE48-AD83-4671-A512-F5851845F1FE',
		'86F98D0D-E84C-4901-A01A-88B9DD737264',
		'817BD2F6-4D12-4D44-8AAF-2ACA2D93135C',
		'343811B1-965C-48D5-8DA2-078B628552B3',
		'03489C5C-61FD-4A66-AA86-2EF557CDC4C2',
		'2F79E390-5092-4FA0-81FD-FF52B919BDEF',
		'9A3C12AA-02AC-444E-A3EA-19833E4D6AE7',
		'262ADAAE-A3DD-4E90-A0B5-F7C3491475CD',
		'1E57A65B-8DD5-4592-AEBD-A0FA3B15E764',
		'EDBDA8BE-F20F-48EE-973F-F0B18B026B32',
		'EFFA7486-CD75-45F8-9618-D56C76F48811',
		'D016DE67-141A-4084-A7EF-64118C82FBE4',
		'7D99AA4F-1A9E-43B8-B809-FD4608F36B55',
		'DFC7BAA7-C054-4278-A22C-A94983C0D551',
		'01CB9C47-5499-4F27-AE5E-47DFC91A7297',
		'F89D55C1-A644-4E7B-833C-C94953995B4A',
		'7D7F3EE3-7B9A-41DA-B5FE-30F9A364006A',
		'A62FF878-2CB8-419D-80FD-332A45079476')	
	AND ia.fldTemplateActivityGuid NOT IN
		('5D14FA26-8773-49CC-ADB9-5978503C2C53',
		'9D615479-9531-43AB-B84F-3050D5210819',
		'A52484A3-3B73-4A14-A010-5FAE799437EB',
		'36689262-0F2A-40BC-A80F-9AB170DB7190', 
		'F5250DF7-C8C6-4526-B662-3F945ECB5C61',
		'58E68AAD-3B6C-4455-B83B-C72B5C563B61')
	AND v.workitemid NOT IN ( 0 )
	AND ISNULL(wi.workitemstateid,1) = 1 AND wi.BusinessServiceLineID != 1

	ORDER BY ServiceLine,fldEmpLastName, fldEmpName