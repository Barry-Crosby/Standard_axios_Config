--  This file contains a sample approach for handling First Call Resolution.
--	This can merged into a standard Action Processor rules file if needed


--
--	Re-use callback remarks as first call resolve
--
function  check_first_call_resolve(EVENT_ID_PARM)

	local SQL = [[ 
		SELECT callback_reqd "FIRST_CALL_RESOLVE"
		FROM incident 
		WHERE    
			incident.incident_id = ]] .. EVENT_ID_PARM
	
	local Result, err = ASSYSTEJB:sql(SQL)
	if err then
		LOGGER:error("Error in check_first_call_resolve: " .. (err or "??") .. "/nSQL:" .. SQL)
		return false
	elseif Result.FIRST_CALL_RESOLVE == nil then
		return false
	elseif Result.FIRST_CALL_RESOLVE[1] == "y" then
		return true
	else
		return false
	end
end

set_of_rules = {

{ 
	[[ Auto Close on First Call Resolve]],  
	[[ ACT_TYPE_SC == "ASSIGN"
		and check_first_call_resolve(EVENT_ID)]], 
	{ ACT_TYPE_SC = "CLOSURE", 
		CAUSE_ITEM_SC = "FCR",
		CAUSE_SC = "FCR",
		SERVICE_TIME = 1,
		ACT_DESC = [[ Automatic closure of ticket on First Call Resolve. ]] },
	"stop" 
},


}