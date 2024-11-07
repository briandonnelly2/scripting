USE [TaxWFPortalData]

DECLARE @UserId INT
DECLARE @TaxYear INT

--UserID is the user who would be running the report in workflow
SET @UserId = ''
SET @TaxYear = ''


;with xmlnamespaces ('http://www.w3.org/2003/05/soap-envelope' as s,
'http://kpmg.com/uk/ttg/workflow/' as x,
'http://www.w3.org/2001/XMLSchema-instance' as i,
'http://kpmg.com/uk/ttg/workflow/reportdata/' as d6p1),
SentToClient
AS
(
       select max(d.SentToClient) SentToClient, d.workItemId
       from
       (
              select fldResponse.value('(//s:Envelope/s:Body/x:UpdateReportDataItemPropertiesResponse/x:UpdateReportDataItemPropertiesResult/x:Result/x:ReportDataItem/d6p1:DateSentToClient/text())[1]', 'datetime') SentToClient
              ,fldResponse.value('(//s:Envelope/s:Body/x:UpdateReportDataItemPropertiesResponse/x:UpdateReportDataItemPropertiesResult/x:Result/x:WorkItemId/text())[1]', 'int') WorkItemId
              from [Sequence].[dbo].uact77b41eac30fb4acc84f031304ab6a942
       ) d
       group by 
       d.workItemId 
),
WCF
AS
(
       SELECT
              d.fldResponse.value('(//s:Envelope/s:Body/x:AddReportDataItemResponse/x:AddReportDataItemResult/x:Result/x:ReportDataItem/d6p1:AssigneeNiNumber/text())[1]', 'nvarchar(max)') AssigneeNiNumber,
              d.fldResponse.value('(//s:Envelope/s:Body/x:AddReportDataItemResponse/x:AddReportDataItemResult/x:Result/x:ReportDataItem/d6p1:AssigneeUtr/text())[1]', 'nvarchar(max)') AssigneeUtr,
              d.fldResponse.value('(//s:Envelope/s:Body/x:AddReportDataItemResponse/x:AddReportDataItemResult/x:Result/x:ReportDataItem/d6p1:TaxReturnType/text())[1]', 'nvarchar(max)') TaxReturnType,
              d.fldResponse.value('(//s:Envelope/s:Body/x:AddReportDataItemResponse/x:AddReportDataItemResult/x:Result/x:ReportDataItem/d6p1:ReviewerName/text())[1]', 'nvarchar(max)') ReviewerName,
              d.fldResponse.value('(//s:Envelope/s:Body/x:AddReportDataItemResponse/x:AddReportDataItemResult/x:Result/x:ReportDataItem/d6p1:FTCAmendmentForPriorYear/text())[1]', 'bit') FTCAmendmentForPriorYear,
              d.fldResponse.value('(//s:Envelope/s:Body/x:AddReportDataItemResponse/x:AddReportDataItemResult/x:Result/x:ReportDataItem/d6p1:FTCAmendmentForCurrentYear/text())[1]', 'bit') FTCAmendmentForCurrentYear,
              d.fldResponse.value('(//s:Envelope/s:Body/x:AddReportDataItemResponse/x:AddReportDataItemResult/x:Result/x:ReportDataItem/d6p1:RemittanceVsArisingCompCalc/text())[1]', 'bit') RemittanceVsArisingCompCalc,
              d.fldResponse.value('(//s:Envelope/s:Body/x:AddReportDataItemResponse/x:AddReportDataItemResult/x:Result/x:ReportDataItem/d6p1:ResidentSevenOrNineYears/text())[1]', 'bit') ResidentSevenOrNineYears,
              d.fldResponse.value('(//s:Envelope/s:Body/x:AddReportDataItemResponse/x:AddReportDataItemResult/x:Result/x:ReportDataItem/d6p1:MixedFundAnalysisCalc/text())[1]', 'bit') MixedFundAnalysisCalc,
              d.fldResponse.value('(//s:Envelope/s:Body/x:AddReportDataItemResponse/x:AddReportDataItemResult/x:Result/x:ReportDataItem/d6p1:PersonalAllowanceReductionCalc/text())[1]', 'bit') PersonalAllowanceReductionCalc,
              d.fldResponse.value('(//s:Envelope/s:Body/x:AddReportDataItemResponse/x:AddReportDataItemResult/x:Result/x:ReportDataItem/d6p1:PensionAACalculation/text())[1]', 'bit') PensionAACalculation,
              d.fldResponse.value('(//s:Envelope/s:Body/x:AddReportDataItemResponse/x:AddReportDataItemResult/x:Result/x:ReportDataItem/d6p1:SubstantialPersonalIncomeAnalysis/text())[1]', 'bit') SubstantialPersonalIncomeAnalysis,
              d.fldResponse.value('(//s:Envelope/s:Body/x:AddReportDataItemResponse/x:AddReportDataItemResult/x:Result/x:ReportDataItem/d6p1:SubstantialPersonalIncomeDescription/text())[1]', 'nvarchar(max)') SubstantialPersonalIncomeDescription,
              d.fldResponse.value('(//s:Envelope/s:Body/x:AddReportDataItemResponse/x:AddReportDataItemResult/x:Result/x:ReportDataItem/d6p1:OtherCommentsRegardingComplexity/text())[1]', 'nvarchar(max)') OtherCommentsRegardingComplexity,
              d.fldResponse.value('(//s:Envelope/s:Body/x:AddReportDataItemResponse/x:AddReportDataItemResult/x:Result/x:ReportDataItem/d6p1:CurrentYearTaxpayerPoA/text())[1]', 'decimal(20,2)') CurrentYearTaxpayerPoA,
              d.fldResponse.value('(//s:Envelope/s:Body/x:AddReportDataItemResponse/x:AddReportDataItemResult/x:Result/x:ReportDataItem/d6p1:CurrentYearEmployerPoA/text())[1]', 'decimal(20,2)') CurrentYearEmployerPoA,
              d.fldResponse.value('(//s:Envelope/s:Body/x:AddReportDataItemResponse/x:AddReportDataItemResult/x:Result/x:ReportDataItem/d6p1:NextYearJanTaxpayerPoA/text())[1]', 'decimal(20,2)') NextYearJanTaxpayerPoA,
              d.fldResponse.value('(//s:Envelope/s:Body/x:AddReportDataItemResponse/x:AddReportDataItemResult/x:Result/x:ReportDataItem/d6p1:NextYearJanEmployerPoA/text())[1]', 'decimal(20,2)') NextYearJanEmployerPoA,
              d.fldResponse.value('(//s:Envelope/s:Body/x:AddReportDataItemResponse/x:AddReportDataItemResult/x:Result/x:ReportDataItem/d6p1:NextYearJulTaxpayerPoA/text())[1]', 'decimal(20,2)') NextYearJulTaxpayerPoA,
              d.fldResponse.value('(//s:Envelope/s:Body/x:AddReportDataItemResponse/x:AddReportDataItemResult/x:Result/x:ReportDataItem/d6p1:NextYearJulEmployerPoA/text())[1]', 'decimal(20,2)') NextYearJulEmployerPoA,
              d.fldResponse.value('(//s:Envelope/s:Body/x:AddReportDataItemResponse/x:AddReportDataItemResult/x:Result/x:ReportDataItem/d6p1:BalanceDueJanTaxpayer/text())[1]', 'decimal(20,2)') BalanceDueJanTaxpayer,
              d.fldResponse.value('(//s:Envelope/s:Body/x:AddReportDataItemResponse/x:AddReportDataItemResult/x:Result/x:ReportDataItem/d6p1:BalanceDueJanEmployer/text())[1]', 'decimal(20,2)') BalanceDueJanEmployer,
              d.fldResponse.value('(//s:Envelope/s:Body/x:AddReportDataItemResponse/x:AddReportDataItemResult/x:Result/x:ReportDataItem/d6p1:Total/text())[1]', 'decimal(20,2)') Total,
              d.fldResponse.value('(//s:Envelope/s:Body/x:AddReportDataItemResponse/x:AddReportDataItemResult/x:Result/x:ReportDataItem/d6p1:EmployerToHmrc/text())[1]', 'decimal(20,2)') EmployerToHmrc,
              d.fldResponse.value('(//s:Envelope/s:Body/x:AddReportDataItemResponse/x:AddReportDataItemResult/x:Result/x:ReportDataItem/d6p1:EmployerToTaxpayer/text())[1]', 'decimal(20,2)') EmployerToTaxpayer,
              d.fldResponse.value('(//s:Envelope/s:Body/x:AddReportDataItemResponse/x:AddReportDataItemResult/x:Result/x:ReportDataItem/d6p1:TaxpayerToHmrc/text())[1]', 'decimal(20,2)') TaxpayerToHmrc,
              d.fldResponse.value('(//s:Envelope/s:Body/x:AddReportDataItemResponse/x:AddReportDataItemResult/x:Result/x:ReportDataItem/d6p1:TaxpayerToEmployer/text())[1]', 'decimal(20,2)') TaxpayerToEmployer,     
              d.fldResponse.value('(//s:Envelope/s:Body/x:AddReportDataItemResponse/x:AddReportDataItemResult/x:Result/x:ReportDataItem/d6p1:TaxReturnPosition/text())[1]', 'nvarchar(max)') TaxReturnPosition,
              d.fldResponse.value('(//s:Envelope/s:Body/x:AddReportDataItemResponse/x:AddReportDataItemResult/x:Result/x:ReportDataItem/d6p1:TaxReturnPositionReason/text())[1]', 'nvarchar(max)') TaxReturnPositionReason,
              d.fldResponse.value('(//s:Envelope/s:Body/x:AddReportDataItemResponse/x:AddReportDataItemResult/x:Result/x:ReportDataItem/d6p1:TeqPosition/text())[1]', 'nvarchar(max)') TeqPosition,
              d.fldResponse.value('(//s:Envelope/s:Body/x:AddReportDataItemResponse/x:AddReportDataItemResult/x:Result/x:ReportDataItem/d6p1:TeqPositionReason/text())[1]', 'nvarchar(max)') TeqPositionReason,
              d.fldResponse.value('(//s:Envelope/s:Body/x:AddReportDataItemResponse/x:AddReportDataItemResult/x:Result/x:UpdatedOn/text())[1]', 'datetime') SubmittedDate,
              d.fldResponse.value('(//s:Envelope/s:Body/x:AddReportDataItemResponse/x:AddReportDataItemResult/x:Result/x:WorkItemId/text())[1]', 'int') WorkItemId,
              d.fldResponse.value('(//s:Envelope/s:Body/x:AddReportDataItemResponse/x:AddReportDataItemResult/x:ResultCode/text())[1]', 'nvarchar(max)') ResultCode,
              d.fldResponse.value('(//s:Envelope/s:Body/x:AddReportDataItemResponse/x:AddReportDataItemResult/x:Result/x:DataItemUpdated/text())[1]', 'nvarchar(max)') DataItemUpdated
       FROM [Sequence].[dbo].UACT70bc247bcfc64ee1904e2e585a737e98 d WITH (NOLOCK)
),

Data 
AS
(
       SELECT
              d.AssigneeNiNumber,
              d.AssigneeUtr,
              d.TaxReturnType,
              d.ReviewerName,
              d.FTCAmendmentForPriorYear,
              d.FTCAmendmentForCurrentYear,
              d.RemittanceVsArisingCompCalc,
              d.ResidentSevenOrNineYears,
              d.MixedFundAnalysisCalc,
              d.PersonalAllowanceReductionCalc,
              d.PensionAACalculation,
              d.SubstantialPersonalIncomeAnalysis,
              d.SubstantialPersonalIncomeDescription,
              d.OtherCommentsRegardingComplexity,
              d.CurrentYearTaxpayerPoA,
              d.CurrentYearEmployerPoA,
              d.NextYearJanTaxpayerPoA,
              d.NextYearJanEmployerPoA,
              d.NextYearJulTaxpayerPoA,
              d.NextYearJulEmployerPoA,
              d.BalanceDueJanTaxpayer,
              d.BalanceDueJanEmployer,
              d.Total,
              d.EmployerToHmrc,
              d.EmployerToTaxpayer,
              d.TaxpayerToHmrc,
              d.TaxpayerToEmployer,      
              d.TaxReturnPosition,
              d.TaxReturnPositionReason,
              d.TeqPosition,
              d.TeqPositionReason,
              d.SubmittedDate,
              d.WorkItemId,
              stc.SentToClient
       FROM wcf d
       LEFT JOIN SentToClient stc on d.WorkItemId = stc.WorkItemId
       WHERE 
              d.ResultCode= 'Successful'
       AND
              d.DataItemUpdated = 'true'

),

ActiveUserClients as
(
    select distinct cagc.ClientId 
    from UserClientAccessGroups ucag
    inner join ClientAccessGroupClients cagc on cagc.ClientAccessGroupId = ucag.ClientAccessGroupId
    where ucag.UserId = @UserId
)


SELECT 
       d.WorkItemId,
       cl.ForeignName ClientName,
       cl.ForeignCode ClientAtlasID,
       wl.ForeignCode AssigneeGTSID,
       wl.ForeignName AssigneeName,
       d.AssigneeNiNumber,
       d.AssigneeUtr,
       p.TaxYearId TaxYear,
       d.TaxReturnType,
       w.WorkItemMilestoneGroupTypeName ParentMilestone,
       w.WorkItemMilestoneTypeName SubMilestone,
       d.SentToClient DateSentToClient,
       d.ReviewerName,
       d.FTCAmendmentForPriorYear,
       d.FTCAmendmentForCurrentYear,
       d.RemittanceVsArisingCompCalc,
       d.ResidentSevenOrNineYears,
       d.MixedFundAnalysisCalc,
       d.PersonalAllowanceReductionCalc,
       d.PensionAACalculation,
       d.SubstantialPersonalIncomeAnalysis,
       d.SubstantialPersonalIncomeDescription,
       d.OtherCommentsRegardingComplexity,
       d.CurrentYearTaxpayerPoA,
       d.CurrentYearEmployerPoA,
       d.NextYearJanTaxpayerPoA,
       d.NextYearJanEmployerPoA,
       d.NextYearJulTaxpayerPoA,
       d.NextYearJulEmployerPoA,
       d.BalanceDueJanTaxpayer,
       d.BalanceDueJanEmployer,
       d.Total,
       d.EmployerToHmrc,
       d.EmployerToTaxpayer,
       d.TaxpayerToHmrc,
       d.TaxpayerToEmployer,      
       d.TaxReturnPosition,
       d.TaxReturnPositionReason,
       d.TeqPosition,
       d.TeqPositionReason,
       d.SubmittedDate
FROM 
       Data d 
       JOIN WorkItemDetail w on d.WorkItemId = w.WorkItemId
       JOIN ClientPeriods cp on w.ClientPeriodId = cp.ClientPeriodId
       JOIN Periods p on cp.PeriodId = p.PeriodId AND p.TaxYearId = @TaxYear
       JOIN Links wl on w.WorkItemClientId = wl.ClientId and wl.LinkTypeId = 5
       JOIN Links cl on cp.ClientId = cl.ClientId and cl.LinkTypeId = 6
JOIN 
       ActiveUserClients auc on auc.ClientId = wl.ClientId
