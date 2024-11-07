  USE [TaxWFReviewToolData]
  GO
    
  SELECT UserId, U.Name, RL.Name,  SessionToken, ExternalId, ReviewStepId, D.DocumentId, D.WorkSiteVersionNumber, R.CreatedTimeStamp, RS.SubmittedBy, RS.SubmittedTimeStamp
  
  FROM [dbo].[ReviewSession] R
  
  INNER JOIN [dbo].[ReviewStep] RS ON R.ReviewStepId = RS.Id
  INNER JOIN [dbo].[User] U ON U.Id = R.UserId
  INNER JOIN [dbo].[DocumentVersion] D ON D.Id = RS.DocumentVersionId
  INNER JOIN [dbo].[Role] RL ON RL.Id = RS.RoleId
  
  WHERE ExternalId IN () --Enter External ID that appears on other review tool script
  
  ORDER BY R.CreatedTimeStamp Desc