SELECT * 
FROM [dbo].[MergedDocument] m0
INNER JOIN [dbo].[DocumentSet] d1 ON d1.Id = m0.DocumentSetId
WHERE d1.ReviewSessionId = '' -- place your review session ID inbetween the commas