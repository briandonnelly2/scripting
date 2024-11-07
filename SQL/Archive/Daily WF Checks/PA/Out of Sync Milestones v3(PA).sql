/** 
	This script will find workitems with out of sync milestones and display these first
	If any are found, turn @UpdateCompletedWorkItems to '1' and @UpdateCompletedWorkItems to '1'
	Completed work items are updated as well as active Work items this way. 
	Change both back to 0 and rerun to ensure these are clear.
**/

USE[TaxWFPortalDataPA]

DECLARE @UpdateCompletedWorkItems bit = 1
DECLARE @PerformUpdate bit = 0

/* A table variable used to temporarily store the work items to be updated */
DECLARE @WorkItemsWithIncorrectMilestones TABLE(WorkItemId int, ChangedOn datetime, WorkItemMilestoneTypeId int, ChangedByUserId int)

PRINT ''
PRINT 'Identifying work items with incorrect milestones...'
;with lastmilestone as
(
	select wimc.workitemid, sub.changedon, wimc.WorkItemMilestoneTypeId, wimc.ChangedByUserId
	from workitemmilestonechange wimc
	inner join 
		(
			select wimc.workitemid, MAX(changedon) as ChangedOn 
			from workitemmilestonechange wimc
			join workitems wi on wimc.WorkItemId = wi.WorkItemId
			join WorkItemTypeMilestoneType wtmt on wi.WorkItemTypeId = wtmt.WorkItemTypeId and wimc.WorkItemMilestoneTypeId = wtmt.WorkItemMilestoneTypeId
			where
				wtmt.CanBeActiveMilestone = 1
			and
				wi.WorkItemStateId = 1 OR (@UpdateCompletedWorkItems = 1 AND wi.WorkItemStateId = 2)
			group by wimc.workitemid
		) sub 
	on sub.workitemid = wimc.WorkItemId and sub.changedon = wimc.ChangedOn
),
incorrectmilestones as (
	select lm.*
	from WorkItems wi
	join lastmilestone lm on lm.WorkItemId = wi.WorkItemId
	where wi.WorkItemMilestoneTypeId <> lm.WorkItemMilestoneTypeId
)
INSERT INTO @WorkItemsWithIncorrectMilestones(WorkItemId, ChangedOn, WorkItemMilestoneTypeId, ChangedByUserId)
SELECT im.WorkItemId, im.ChangedOn, im.WorkItemMilestoneTypeId, im.ChangedByUserId FROM incorrectmilestones im

SET NOCOUNT ON;

/* Show the work items that will be updated by this change */
select wid.WorkItemStateName StateName, wid.WorkItemMilestoneTypeName OldMilestoneName, COALESCE(wtmt.OverriddenName, mt.Name) NewMilestoneName, wid.*
from WorkItemDetail wid
join @WorkItemsWithIncorrectMilestones im ON im.WorkItemId = wid.WorkItemId
join WorkItemTypeMilestoneType wtmt ON wtmt.WorkItemMilestoneTypeId = im.WorkItemMilestoneTypeId AND wtmt.WorkItemTypeId = wid.WorkItemTypeId
join WorkItemMilestoneType mt ON mt.Id = im.WorkItemMilestoneTypeId
where wid.WorkItemMilestoneTypeId <> im.WorkItemMilestoneTypeId 

SET NOCOUNT OFF;

IF (@PerformUpdate = 1)
BEGIN
	PRINT ''
	PRINT 'Updating work items with correct milestones...'
	/* Perform the update */
	UPDATE 
		wi
	SET
       wi.WorkItemMilestoneTypeId = im.WorkItemMilestoneTypeId,
       wi.WorkItemMilestoneChangeDate = im.changedon,
       wi.WorkItemMilestoneChangedByUserId = im.ChangedByUserId
	FROM
       workitems wi 
	JOIN
       @WorkItemsWithIncorrectMilestones im on wi.WorkItemId = im.WorkItemId
END