--  This file contains a sample approach for automating start and stop clock
--  This includes SQL to validate the current clock state before taking these actions
--	This can merged into a standard Action Processor rules file if needed


function  check_clock_stopped(EVENT_ID_PARM)

	local SQL = [[ 
		SELECT "DATE_CLOCK_STOPPED" = CASE
			WHEN u_date1 is null THEN '0'
			ELSE '1'
			END
		FROM inc_data
		WHERE    
			incident_id = ]] .. EVENT_ID_PARM
	
	local Result, err = ASSYSTEJB:sql(SQL)
	if err then
		LOGGER:error("Error in check_clock_stopped: " .. (err or "??") .. "/nSQL:" .. SQL)
	elseif Result.DATE_CLOCK_STOPPED[1] == "0" then
		LOGGER:debug("Clock NOT stopped for id: " .. stringify(EVENT_ID_PARM) .. " Result:" .. stringify(Result.DATE_CLOCK_STOPPED[1]))
		return false
	else
		LOGGER:debug("Clock stopped for id: " .. stringify(EVENT_ID_PARM) .. " Result:" .. stringify(Result.DATE_CLOCK_STOPPED[1]))
		return true
	end
end

set_of_rules = {
	
	{ 
		[[ Suspend Tickets Logged in NET and assigned to Support ]], 
		[[ ACT_TYPE_SC == "ASSIGN" 
			and ACT_TYPE_COUNT == 1
			and ACT_ASS_SVD_SC == "SUPPORT CENTER"
			and check_clock_stopped(EVENT_ID) ~= true ]], 
		{ ACT_TYPE_SC = "SCSUSPEND", 
			SERVICE_TIME = 1,
			ACT_DESC = [[ Automatic stop clock for ticket logged in assystNET and assigned to Support ]] },
		"continue"  
	},
			
	{ 
		[[ Restart clock on tickets Logged in NET and assigned to Support if assigned out of support ]], 
		[[ ACT_TYPE_SC == "ASSIGN" 
			and ACT_TYPE_COUNT == 2
			and ASS_SVD_SC ~= "SUPPORT CENTER"
			and check_clock_stopped(EVENT_ID) ]], 
		{ ACT_TYPE_SC = "SCASSIGN", 
			SERVICE_TIME = 1,
			ACT_DESC = [[ Automatic restart of clock for ticket logged in assystNET and assigned out of Support ]] },
		"continue"  
	},

}
