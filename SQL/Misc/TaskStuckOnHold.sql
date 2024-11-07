use [TaxWFPortalData]

--(workitemid from the details tab)
select * from onhold.WorkItem where OnHoldWorkItemId=281747 --1

--Use the value in the ID column for the next query as workitemid
select * from onhold.WorkItemType where workitemid=41125 --2

--Use the value in the ID column for the next query as workitemtypeid 
select * from onhold.WorkItemTypeInstance where workitemtypeid=48368 --3

--use the value in the id column for the next query as WorkItemTypeInstanceId
select * from onhold.WorkItemTypeInstanceNote where WorkItemTypeInstanceId=58291 --4

--Sequence on hold table
select * from [Sequence].[dbo].[UWF73cbe5a4529e4fe792880b39def644db] where WorkItemId = 281747  AND fldIWfId = 11929002 --5

Begin transaction 

Delete from onhold.WorkItemTypeInstanceNote where WorkItemTypeInstanceId=58291 --4
Delete from onhold.WorkItemTypeInstance where workitemtypeid=48368 --3
Delete from onhold.WorkItemType where workitemid=41125 --2
Delete from onhold.WorkItem where OnHoldWorkItemId=281747 --1
Delete from [Sequence].[dbo].[UWF73cbe5a4529e4fe792880b39def644db] where WorkItemId = 281747 AND fldIWfId = 11929002 --5

rollback transaction 
--commit