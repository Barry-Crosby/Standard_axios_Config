--   Syntax
--   if a command is to be executed when the conditions are met, then you need the following syntax
--   within an entry
--   {  [[nameOfRule]], [[condition]], [[command]], "continue|stop" }
--   "continue|stop" is what the processor should do with the rules mentioned below if the current 
--    condition is met. For example 
--   { [[rule1]], [[ ACT_TYPE_SC == "SUPP-ASSIGN" and ACTIONING_USR_SC == "JOSEPH" ]], 
-- 		[[\SmartMail\send_email.exe -config config.conf ACT_REG_ID=$ACT_REG_ID]], "continue" },

--   If a new action is to be created when the conditions are met, then you need the following syntax
--   {  [[nameOfRule]], [[condition]], { parametersForAction }, "continue|stop" } 
--   For example 
--   { [[rule2]], [[ ACT_TYPE_SC == 'ASSIGN' and ACTIONING_USR_SC == "CHRIS" and itemAName == 'TESTING' ]],  
--           { ACT_TYPE_SC='PENDING-CLOSURE' }, "stop" },

--   Note: 
--   When a new action is to be created, then the ACT_TYPE_SC is mandatory, unless the LOCATION_SC is a parameter
----------------------------------------------------------------------------------------
-- Change log
-- Jul 30, 2012 - Add Decision Close Rule
-- Jul 31, 2012 - Add Complete Rule
--------------------------------------------------------------------------------------

function  check_closed(EVENT_ID_PARM)

	local SQL = [[ 
		SELECT inc_status "STATUS"
		FROM incident 
		WHERE    
			incident.incident_id = ]] .. EVENT_ID_PARM
	
	local Result, err = ASSYSTEJB:sql(SQL)
	if err then
		LOGGER:error("Error in check_closed: " .. (err or "??") .. "/nSQL:" .. SQL)
	elseif Result.STATUS == nil then
		return false
	elseif Result.STATUS[1] == "c" then
		return true
	else
		return false
	end
end

set_of_rules = {

{ 
	-- Extend this rule to include any other completion/empty stages
	[[ Complete Closure of Parent Event]],  
	[[ ACT_TYPE_SC == "COMPLETE"
		and not check_closed(EVENT_ID)]], 
	{ ACT_TYPE_SC = "CLOSURE", 
		CAUSE_ITEM_SC = "CLOSE REQUEST", 
		CAUSE_SC = "REQ COMPLETED",
		SERVICE_TIME = 1,
		ACT_DESC = [[ Automatic closure of parent event after last stage of workflow. ]] },
	"continue" 
},

{ 
	[[ Complete Process Notification ]],  
	[[ ACT_TYPE_SC == "COMPLETE" ]], 
	[["\_AxiosSoftware\assyst Smart Mail 1.5\send_email.exe"  -v -config "\_Axios_Config\SmartMail\Logic\Complete.lua" ACT_REG_ID=$ACT_REG_ID ]], 
	"stop" 
},

{ 
	[[ Email selected user or affected/reporting users]],  
	[[ ACT_TYPE_SC == "EMAIL CUSTOMER" ]], 
	[["\_AxiosSoftware\assyst Smart Mail 1.5\send_email.exe" -v -config "\_Axios_Config\SmartMail\Logic\send_email_rd.lua" ACT_REG_ID=$ACT_REG_ID  ]], 
	"stop" 
},

{ 
	[[ Notify Impacted Users]],  
	[[ ACT_TYPE_SC == "NOTIFY IMP USER" ]], 
	[["\_AxiosSoftware\assyst Smart Mail 1.5\send_email.exe" -v -config "\_Axios_Config\SmartMail\Logic\notify_imp_users_rd.lua" ACT_REG_ID=$ACT_REG_ID ]], 
	"continue" 
},

{ 
	[[ Notify Stake Holders ]],  
	[[ ACT_TYPE_SC == "NOTIFY STAKE" ]], 
	[["\_AxiosSoftware\assyst Smart Mail 1.5\send_email.exe"  -v -config "\_Axios_Config\SmartMail\Logic\notify_stakeholders_rd.lua" ACT_REG_ID=$ACT_REG_ID ]], 
	"continue" 
},

{ 
	[[ Reopen Requested - Notify Assignees]],  
	[[ ACT_TYPE_SC == "MBR REOPEN REQ" ]], 
	[["\_AxiosSoftware\assyst Smart Mail 1.5\send_email.exe"  -v -config "\_Axios_Config\SmartMail\Logic\reopen_req_rd.lua" ACT_REG_ID=$ACT_REG_ID ]], 
	"continue" 
},

{ 
	-- Future:  add condition check on actioned by Service Desk or assigned team
	[[ Inform assignees when info added ]],  
	[[ ACT_TYPE_SC == "ADD INFO" ]], 
	[["\_AxiosSoftware\assyst Smart Mail 1.5\send_email.exe"  -v -config "\_Axios_Config\SmartMail\Logic\add_info_rd.lua" ACT_REG_ID=$ACT_REG_ID ]], 
	"continue" 
},

{ 
	[[ Inform assignees of follow up request ]],  
	[[ ACT_TYPE_SC == "FOLLOW UP" ]], 
	[["\_AxiosSoftware\assyst Smart Mail 1.5\send_email.exe"  -v -config "\_Axios_Config\SmartMail\Logic\chase_up_rd.lua" ACT_REG_ID=$ACT_REG_ID ]], 
	"continue" 
},

{ 
	[[ Close Decision Tasks ]],  
	[[ ACT_TYPE_SC == "CLOSURE"
		and EVENT_TYPE == "d" ]], 
	[["\_AxiosSoftware\assyst Smart Mail 1.5\send_email.exe"  -v -config "\_Axios_Config\SmartMail\Logic\close_decision.lua" ACT_REG_ID=$ACT_REG_ID ]], 
	"stop" 
},

{ 
	[[ Assign Decision Tasks ]],  
	[[ ACT_TYPE_SC == "ASSIGN"
		and EVENT_TYPE == "d" ]], 
	[["\_AxiosSoftware\assyst Smart Mail 1.5\send_email.exe"  -v -config "\_Axios_Config\SmartMail\Logic\decision.lua" ACT_REG_ID=$ACT_REG_ID ]], 
	"stop" 
},

{ 
	[[ Assign Authorize Tasks ]],  
	[[ ACT_TYPE_SC == "ASSIGN"
		and EVENT_TYPE == "a" ]], 
	[["\_AxiosSoftware\assyst Smart Mail 1.5\send_email.exe"  -v -config "\_Axios_Config\SmartMail\Logic\authorize.lua" ACT_REG_ID=$ACT_REG_ID ]], 
	"stop" 
},

{ 
	[[ Assign and Open Emails]],  
	[[ ACT_TYPE_SC == "ASSIGN" ]], 
	[["\_AxiosSoftware\assyst Smart Mail 1.5\send_email.exe"  -v -config "\_Axios_Config\SmartMail\Logic\ASSIGN_rd.lua" ACT_REG_ID=$ACT_REG_ID ]], 
	"continue" 
},

{ 
	[[ Auto Assign Problems to Problem Management ]],
	[[ ACT_TYPE_SC == "ASSIGN"
		and (tonumber(ACT_TYPE_COUNT) == 1)
		and (EVENT_TYPE == "p")
		and (ASS_SVD_SC ~= "PROBLEM MGMT")
		and not check_closed(EVENT_ID) 
	]],
	{ ACT_TYPE_SC = "ASSIGN", 
		ACT_ASS_SVD_SC = "PROBLEM MGMT",
		SERVICE_TIME = 1,
		ACT_DESC = [[ Auto assign problems to problem management SVD]]  },
	"continue",
},

{ 
	-- This handles authorizations done via ACLI or assyst Web which don't close the task
	[[ Complete Closure of Authorized/Not Authorized]],  
	[[ ACT_TYPE_SC == "AUTHORIZED" 
		or ACT_TYPE_SC == "NOT AUTHORIZED" ]], 
	[["\_AxiosSoftware\assyst Smart Mail 1.5\send_email.exe"  -v -config "\_Axios_Config\SmartMail\Logic\CompleteClose_rd.lua" ACT_REG_ID=$ACT_REG_ID ]], 
	"stop" 
},

{ 
	[[ Resolution or Closure]],  
	[[ (ACT_TYPE_SC == "CLOSURE" 
			or ACT_TYPE_SC == "PENDING-CLOSURE")
		and (EVENT_TYPE == "i" 
			or EVENT_TYPE == "c"
			or EVENT_TYPE == "s")
		]], 
	[["\_AxiosSoftware\assyst Smart Mail 1.5\send_email.exe"  -v -config "\_Axios_Config\SmartMail\Logic\Resolve_or_closure_rd.lua" ACT_REG_ID=$ACT_REG_ID ]], 
	"continue" 
},

{ 
	[[ Reviewed Knowledge Candidate ]],  
	[[ ACT_TYPE_SC == "KNOWLEDGE APP" 
		or ACT_TYPE_SC == "KNOWLEDGE REJ"
		or ACT_TYPE_SC == "KNOWLEDGE DUP" ]], 
	{ ACT_TYPE_ORIG_SC = "KNOWLEDGE CAND", 
		ACT_TYPE_SC = "KNOWLEDGE CANDX" },
	"stop" 
},

{ 
	[[ Reviewed Problem Candidates ]], 
	[[ ACT_TYPE_SC == "PROB CONFIRMED" 
		or ACT_TYPE_SC == "PROB EXISTING" 
		or ACT_TYPE_SC == "PROB REJECTED" ]], 
	{ ACT_TYPE_ORIG_SC = "PROB CANDIDATE", 
		ACT_TYPE_SC = "PROB CANDIDATEX" },
	"stop" 
},

------------------------------------------------------------------------------------------------------
--  Send escalation level emails.   Delete rules that are higher than in use
------------------------------------------------------------------------------------------------------
{ 
	[[ Escalation Level 1 Reached ]],  
	[[ ACT_TYPE_SC == "ESC1 REACHED" ]], 
	[["\_AxiosSoftware\assyst Smart Mail 1.5\send_email.exe" -v -config "\_Axios_Config\SmartMail\Logic\esc_reached_rd.lua" ACT_REG_ID=$ACT_REG_ID ESC_LEVEL=1 ]], 
	"stop" 
},
{ 
	[[ Escalation Level 2 Reached ]],  
	[[ ACT_TYPE_SC == "ESC2 REACHED" ]], 
	[["\_AxiosSoftware\assyst Smart Mail 1.5\send_email.exe" -v -config "\_Axios_Config\SmartMail\Logic\esc_reached_rd.lua" ACT_REG_ID=$ACT_REG_ID ESC_LEVEL=2 ]], 
	"stop" 
},
{ 
	[[ Escalation Level 3 Reached ]],  
	[[ ACT_TYPE_SC == "ESC3 REACHED" ]], 
	[["\_AxiosSoftware\assyst Smart Mail 1.5\send_email.exe" -v -config "\_Axios_Config\SmartMail\Logic\esc_reached_rd.lua" ACT_REG_ID=$ACT_REG_ID ESC_LEVEL=3 ]], 
	"stop" 
},
{ 
	[[ Escalation Level 4 Reached ]],  
	[[ ACT_TYPE_SC == "ESC4 REACHED" ]], 
	[["\_AxiosSoftware\assyst Smart Mail 1.5\send_email.exe" -v -config "\_Axios_Config\SmartMail\Logic\esc_reached_rd.lua" ACT_REG_ID=$ACT_REG_ID ESC_LEVEL=4 ]], 
	"stop" 
},
{ 
	[[ Escalation Level 5 Reached ]],  
	[[ ACT_TYPE_SC == "ESC5 REACHED" ]], 
	[["\_AxiosSoftware\assyst Smart Mail 1.5\send_email.exe" -v -config "\_Axios_Config\SmartMail\Logic\esc_reached_rd.lua" ACT_REG_ID=$ACT_REG_ID ESC_LEVEL=5 ]], 
	"stop" 
},
{ 
	[[ Escalation Level 6 Reached ]],  
	[[ ACT_TYPE_SC == "ESC6 REACHED" ]], 
	[["\_AxiosSoftware\assyst Smart Mail 1.5\send_email.exe" -v -config "\_Axios_Config\SmartMail\Logic\esc_reached_rd.lua" ACT_REG_ID=$ACT_REG_ID ESC_LEVEL=6 ]], 
	"stop" 
},
{ 
	[[ Escalation Level 7 Reached ]],  
	[[ ACT_TYPE_SC == "ESC7 REACHED" ]], 
	[["\_AxiosSoftware\assyst Smart Mail 1.5\send_email.exe" -v -config "\_Axios_Config\SmartMail\Logic\esc_reached_rd.lua" ACT_REG_ID=$ACT_REG_ID ESC_LEVEL=7 ]], 
	"stop" 
},
{ 
	[[ Escalation Level 8 Reached ]],  
	[[ ACT_TYPE_SC == "ESC8 REACHED" ]], 
	[["\_AxiosSoftware\assyst Smart Mail 1.5\send_email.exe" -v -config "\_Axios_Config\SmartMail\Logic\esc_reached_rd.lua" ACT_REG_ID=$ACT_REG_ID ESC_LEVEL=8 ]], 
	"stop" 
},
{ 
	[[ Escalation Level 9 Reached ]],  
	[[ ACT_TYPE_SC == "ESC9 REACHED" ]], 
	[["\_AxiosSoftware\assyst Smart Mail 1.5\send_email.exe" -v -config "\_Axios_Config\SmartMail\Logic\esc_reached_rd.lua" ACT_REG_ID=$ACT_REG_ID ESC_LEVEL=9 ]], 
	"stop" 
},
{ 
	[[ Escalation Level 10 Reached ]],  
	[[ ACT_TYPE_SC == "ESC10 REACHED" ]], 
	[["\_AxiosSoftware\assyst Smart Mail 1.5\send_email.exe" -v -config "\_Axios_Config\SmartMail\Logic\esc_reached_rd.lua" ACT_REG_ID=$ACT_REG_ID ESC_LEVEL=10 ]], 
	"stop" 
},

}