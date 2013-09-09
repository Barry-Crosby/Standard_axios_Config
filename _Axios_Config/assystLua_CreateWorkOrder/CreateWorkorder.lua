--This script can be used to log a new event from an action taken and link this new event to the call the action was taken against
--It expects the following arguments to be passed : event_id, item_sc, act_reg_id, action_description
--Written by Michail Mavromatis and Menno van Hoogstraten
--@@language lua
--------------------------------------------------------------------------------------
-- Change log
-- 06/28/2012	Initial version of file
-- 07/10/2012   Adjusted for FB Config conventions
--------------------------------------------------------------------------------------

LOGGER:info("...... Starting " .. strUtilityName .. " ...... Database: " .. strassystDBName)
LOGGER:debug("Parms: arg[1]: " .. stringify(arg[1]) .. " arg[1]: " .. stringify(arg[2]) .. " arg[3]: " .. stringify(arg[3]))

--Original event id is the first argument
EVENT_ID = arg[1]

--Lookup the id of the item based on the second argument
local myitem, err  = ASSYSTEJB:lookup_id("Item", arg[2])
if err then 
	LOGGER:error("Error encountered looking up item: " .. err)
	return
end


--Lookup the required values based on the act_reg_id which is the third argument
local action_fields, err = ASSYSTEJB:get("Action",arg[3],{"actioningServDeptId", "actionedBy.shortCode" ,"actionedById" , "dateActioned", "modifyId", "actionType.shortCode"}, false )
if err then 
	LOGGER:error("Error encountered looking up values: " .. err)
	return
end

mysvdid = action_fields["actioningServDeptId"]
myassyst_usr_sc = action_fields["actionedBy.shortCode"]
myrequireddate = action_fields["dateActioned"]
myassyst_usr_id = action_fields["actionedById"]
mymodifyuser = action_fields["modifyId"]
myactionsc = action_fields["actionType.shortCode"]



--myformatteddate=left(myrequireddate,len(myrequireddate)-1)
myformatteddate=date(myrequireddate)
bias=myformatteddate:getbias() --The bias is time zone offset plus the daylight savings if in effect
bias=bias*-1 

myformatteddate = myformatteddate:addminutes(bias)

local assign_to_user = false

if left(myassyst_usr_sc,3) ~= "SVD" then
	assign_to_user = true
end

local myaffecteduser, err  = ASSYSTEJB:lookup_id("ContactUser", mymodifyuser)
if err then 
	LOGGER:error("Error encountered looking up user: " .. err)
	return
end

LOGGER:debug("affected userid:" .. myaffecteduser)

--Lookup the id of the cateogry that the linked calls should get
local mycategory, err  = ASSYSTEJB:lookup_id("Category", linked_call_category)
if err then 
	LOGGER:error("Error encountered looking up category: " .. err)
	return
end
LOGGER:debug("category_id:" .. mycategory)

--if myactionsc = 'XYZ' then 

if assign_to_user then
	-- Create the new event with assigned user
	ref, err = ASSYSTEJB:new_event{
		   importProfile = "WORKORDER",
		   eventType = 4, -- Always a Change.
		   itemAId = myitem,
		   categoryId = mycategory,
		   affectedUserId = myaffecteduser,
		   assignedUserId = myassyst_usr_id,
		   assignedServDeptId = mysvdid,
		   requiredByDate = myformatteddate,
		   shortDescription = "Workorder " ..arg[2],
		   remarks = arg[4],
		}   

else 
	-- Create the new event assign to svd
	ref, err = ASSYSTEJB:new_event{
		   importProfile = "WORKORDER",
		   eventType = 4, -- Always a Change.
		   itemAId = myitem,
		   categoryId = mycategory,
		   affectedUserId = myaffecteduser,
		   assignedServDeptId = mysvdid,
		   requiredByDate = myformatteddate,
		   remarks = arg[4],
		   shortDescription = "Workorder " ..arg[2],
		}   
end
	
if err then 
	LOGGER:error("Error encountered when creating new event: " .. err)
	return
end	   
	   

--Get the id of the link reason
local myreasonid, err  = ASSYSTEJB:lookup_id("LinkReason", link_reason_sc)
if err then 
	LOGGER:error("Error encountered looking up link reason: " .. err)
	return
end

--Check to see if event already has link groups
local ejb_result, err = ASSYSTEJB:get( "Event", EVENT_ID, {"linkedEventGroups"}, false )

if err then 
	LOGGER:error("Error encountered looking for link groups: " .. err)
	return
end

local group_exists = false

-- ejb_result has the following form
--[[
	{ object = "Event",
		["id"] = 10000006,
		["shortCode"] = NULL,
		{ object = "linkedEventGroups",
			{ object = "LinkedEventGroup",
				["id"] = 46,
			},
			{ object = "LinkedEventGroup",
				["id"] = 48,
			},
		},
	}
	
	so we need to retrieve the linked event groups out of there.

	we now that the query will have only one array in its results 
--]]
event_linked_groups = type(ejb_result) == "table" 
						and type(ejb_result[1])  == "table" and ejb_result[1] or nil
						
--Check to see if one of the existing link groups has the same link reason as the one we want to use
if event_linked_groups and type(event_linked_groups) == "table" then
	for _, object_lg in pairs(event_linked_groups) do 
		local id = object_lg.id or nil
		if id then
			local returned_values, err  = ASSYSTEJB:get("LinkedEventGroup", id,  {"linkReasonId"}, false)
			if err then 
				LOGGER:error("Error encountered: " .. err)
				return
			elseif returned_values["linkReasonId"] == myreasonid then 
				new_group_id = id
				group_exists = true
			end
		end
	end

end

LOGGER:debug("Group exists? " .. stringify(group_exists) )

if group_exists then 
	-- link the new event here
	
	local ok, err = ASSYSTEJB:new_linked_event( {linkedEventGroupId= new_group_id, linkedEventId=tonumber(ref)})
		if err then 
			LOGGER:error("Error encountered while linking new event: " .. err)
		end
	
else
	-- create the new group and link here
	--Create the new link group
	new_group_id , err = ASSYSTEJB:new_linked_event_group({linkReasonId=myreasonid} )
	if err then 
		LOGGER:error("Error encountered: " .. err)
	else
		--Put the original call in the link group
		local ok, err = ASSYSTEJB:new_linked_event( {linkedEventGroupId= new_group_id, linkedEventId=tonumber(EVENT_ID)})
		if err then 
			LOGGER:error("Error encountered when creating new link group: " .. err)
		end
		--Put the new call in the link group
		local ok, err = ASSYSTEJB:new_linked_event( {linkedEventGroupId= new_group_id, linkedEventId=tonumber(ref)})
		if err then 
			LOGGER:error("Error encountered while linking new event: " .. err)
		end
	end
end

LOGGER:info("......" .. strUtilityName .. " Complete......")