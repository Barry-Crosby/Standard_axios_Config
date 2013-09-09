---
---	Example of doing thing differently based on event source
---

function check_event_source(EVENT_ID_PARM)
local SQL = [[
		select receive_type "EVENT_SOURCE"
		from inc_data
		where incident_id = ]] .. EVENT_ID_PARM
	local Result, err = ASSYSTEJB:sql(SQL)
	if err then
		LOGGER:error("Error in check_event_source: " .. (err or "??") .. "/nSQL:" .. SQL)
	elseif Result.EVENT_SOURCE == nil then
		return '0'
	elseif Result.EVENT_SOURCE[1] == "n" then
		return 'assystNet'
	else
		return 'p'
	end

end

set_of_rules = {

	{ 
		[[ Auto Close on First Call Resolve]],  
		[[ ACT_TYPE_SC == "ASSIGN"
			and check_first_call_resolve(EVENT_ID)
			and check_event_source(EVENT_ID) ~= "assystNet"]], 
		{ ACT_TYPE_SC = "CLOSURE", 
			CAUSE_ITEM_SC = "FCR",
			CAUSE_SC = "FCR",
			SERVICE_TIME = 1,
			ACT_DESC = [[ Automatic closure of ticket on First Call Resolve. ]] },
		"stop" 
	},
	
}
