USE Sequence

select * from tblActionItems where fldSubject = '7761316 Paine, Claire Helen 60451197 - Engagement Letter Received #1535444'

update tblActionItems 
set fldcompletiondate = GetDate() 
where fldSubject = '7761316 Paine, Claire Helen 60451197 - Engagement Letter Received #1535444'