/**
	Latest step in the review tool error: Enter the Workflow Instance ID for the whole process
	below and this will return any active review tool sessions for this process along with the 
	users name who opened this and a link to their review tool session.  Please send the link to 
	this user asking them to use it to close their review tool session properly in order to resolve
	any latest step errors.
**/

USE [sequence]

DECLARE @InstanceId INT = 9749979

SELECT	 DisplayName
		,ExternalId
		,RoleName
		,UserId
		,WorkSiteDocumentId
		,WorksiteDocumentVersionNumber
		,'http://taxworkflowportal.uk.kworld.kpmg.com:8102/Document/Review/' + SessionToken AS 'Link'
		,Submitted
		,ActiveReviewPoints
		,ClosedReviewPoints

FROM UACT9fb7f569f014441cb9d8b966ee165672

WHERE WorkItemInstanceId = @InstanceId
AND Submitted = 0