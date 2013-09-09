-- debug_to_outlook = true
-- debug_to_file = "assign_email_file.txt"

--------------------------------------------------------------------------------------
-- Close_Decision.lua (version 3.0)
-- Prepared for AGS SmartMail Quick Config
--
-- This script is not supported by Axios Systems. The script is provided as is and Axios Systems
-- accepts no responsibility or liability for the consequences of using this script.
--
----------------------------------------------------------------------------------------
-- Change log
-- Jul 30, 2012 - New File
--------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------
-- Include File With Common Global Variables, DB, Path and SMTP Information
--------------------------------------------------------------------------------------
dofile("dofiles\\SmartMailParms.lua")
dofile("dofiles\\SmartMailRuleDispatcher.lua")
dofile("dofiles\\SmartMailRuleDispatcherDefaultControls.lua")
--------------------------------------------------------------------------------------
-- Define the Environment For This Config
--------------------------------------------------------------------------------------
environment {
	-- Parameters used across the config
	-- Parameters specific to a rule should be defined inside the rule.
	
	--[[
		To include values from custom form fields use the following syntax:
			["form field name"] = "template_variable"
		For example, 
			["RFC_Extended Description"] = "RFC_Extended_Desc",
		This would set the RFC_Extended_Desc variable to the value of the "RFC Extended Description" field
	--]]
	CUST_FIELD_LIST = {
	},
}

--------------------------------------------------------------------------------------
-- Log key data
--------------------------------------------------------------------------------------
LOGGER:info("Start of close_decision.lua: \nACT_TYPE_COUNT: " .. (ACT_TYPE_COUNT or "") .. ", \nEVENT: " .. (EVENT_TYPE or "").. (EVENT_REF or "")
	.. ", \nEVENT_TYPE_N: " .. (EVENT_TYPE_N_EXT or "none"))	

--------------------------------------------------------------------------------------
-- The rules and business logic associated with action that triggers this config
--------------------------------------------------------------------------------------
set_of_rules {
	{
		--------------------------------------------------------------------------------------
		-- Run SQL to get standard variables to be available to all subsequent rules
		--
		--		Values retrieved by get_decision_results:
		--      DECISION_ANSWER_VALUE
		--		DECISION_STAGE_SC
		--		DECISION_STAGE_N
		--		DECISION_ANSWER_PROCESS_SC
		--------------------------------------------------------------------------------------
		name = [[ "Init - standard SQL" ]],
		data_generation = [[ {( strPathToSql .. "\\get_standard_values_sql.lua" ), 
			( strPathToSql .. "\\linked_events_sql.lua"),
			( strPathToSql .. "\\auto_select_custom_fields.lua"),
			( strPathToSql .. "\\get_usr_manager_sql.lua" ),
			( strPathToSql .. "\\get_decision_results.lua") } ]],
		condition = [[
			true
		]],
		activities = {
			{"log", 
            [["Close_Decision init complete"]]
			},
		},
		"continue",
	},
	
	-- Send Manager Rejection notification email
	{
		name = [[ "Close Decision - Manager Reject " ]],
		condition = [[
			((DECISION_ANSWER_PROCESS_SC or "") == "Z-REJECTED")
			and (DECISION_STAGE_SC == "MANAGER APP")
		]],
		activities = {
			{ "email", 
				recipients_special = [[ { (affected_user()), (custom_target(strPathToSql .. "get_add_affected_users_sql.lua")) } ]],
				subject = [[ strEmailSubjectPrefix .. PAR_TICKET_TYPE_FOR_EMAIL .. " #$PAR_EVENT_TYPE_U$PAR_EVENT_REF" .. " rejected" ]],
				body = [[ strPathToTemplates .. "\\Rejected.html" ]],
			},
		},
		"stop",
	},
	
	-- Send Other Rejection notification email
	{
		name = [[ "Close Decision - Non-Manager Reject " ]],
		condition = [[
			((DECISION_ANSWER_PROCESS_SC or "") == "Z-REJECTED")
		]],
		activities = {
			{ "email", 
				recipients_special = [[ { (affected_user()), (custom_target(strPathToSql .. "get_add_affected_users_sql.lua")) } ]],
				cc_special = [[ { MANAGER_NAME, MANAGER_EMAIL }  ]], 
				subject = [[ strEmailSubjectPrefix .. PAR_TICKET_TYPE_FOR_EMAIL .. " #$PAR_EVENT_TYPE_U$PAR_EVENT_REF" .. " rejected" ]],
				body = [[ strPathToTemplates .. "\\Rejected.html" ]],
			},
		},
		"stop",
	},
	
	-- Send Cancel notification email
	{
		name = [[ "Close Decision - Cancel " ]],
		condition = [[
			((DECISION_ANSWER_PROCESS_SC or "") == "Z-CANCELLED")
		]],
		activities = {
			{ "email", 
				recipients_special = [[ { (affected_user()), (custom_target(strPathToSql .. "get_add_affected_users_sql.lua")) } ]],
				cc_special = [[ { MANAGER_NAME, MANAGER_EMAIL }  ]], 
				subject = [[ strEmailSubjectPrefix .. PAR_TICKET_TYPE_FOR_EMAIL .. " #$PAR_EVENT_TYPE_U$PAR_EVENT_REF" .. " cancelled" ]],
				body = [[ strPathToTemplates .. "\\Cancelled.html" ]],
			},
		},
		"stop",
	},
	
	-- Send Return notification email
	{
		name = [[ "Close Decision - Return " ]],
		condition = [[
			(string.find(upper((DECISION_ANSWER_VALUE or "")), "RETURN") or "") ~= ""
		]],
		activities = {
			{ "email", 
				recipients_special = [[ { (affected_user()), (custom_target(strPathToSql .. "get_add_affected_users_sql.lua")) } ]],
				cc_special = [[ { MANAGER_NAME, MANAGER_EMAIL }  ]], 
				subject = [[ strEmailSubjectPrefix .. PAR_TICKET_TYPE_FOR_EMAIL .. " #$PAR_EVENT_TYPE_U$PAR_EVENT_REF" .. " has been returned for more information" ]],
				body = [[ strPathToTemplates .. "\\Return.html" ]],
			},
		},
		"stop",
	},
	
	-- Any other decision that results in process change
	{
		name = [[ "Close Decision - Other " ]],
		condition = [[
			((DECISION_ANSWER_PROCESS_SC or "") ~= "")
		]],
		activities = {
			{ "email", 
				recipients_special = [[ { (affected_user()), (custom_target(strPathToSql .. "get_add_affected_users_sql.lua")) } ]],
				subject = [[ strEmailSubjectPrefix .. " $PAR_TICKET_TYPE_FOR_EMAIL #$PAR_EVENT_TYPE_U$PAR_EVENT_REF $DECISION_STAGE_N answer $DECISION_ANSWER_VALUE" ]],
				body = [[ strPathToTemplates .. "\\CloseDecision.html" ]],
			},
		},
		"stop",
	},
}