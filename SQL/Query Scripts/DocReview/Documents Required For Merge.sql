SELECT * 
FROM [dbo].[Document] d0
INNER JOIN [dbo].[DocumentSet] d1 ON d1.Id = d0.DocumentSetId
WHERE d1.ReviewSessionId = '' -- place your review session ID inbetween the commas