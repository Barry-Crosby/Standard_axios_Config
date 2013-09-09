-- debug_to_outlook = true
-- debug_to_file = "assign_email_file.txt"

--------------------------------------------------------------------------------------
-- authorize.lua (version 3.0)
-- Prepared for AGS SmartMail Quick Config
--
-- This script is not supported by Axios Systems. The script is provided as is and Axios Systems
-- accepts no responsibility or liability for the consequences of using this script.
--
----------------------------------------------------------------------------------------
-- Change log
-- Feb 15, 2012 - updated to use RulesDispatcher
-- Jul 09, 2012 - include SQL to get custom field values for assign logic
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
LOGGER:info("Start of authorize.lua: \nACT_TYPE_COUNT: " .. (ACT_TYPE_COUNT or "") .. ", \nEVENT: " .. (EVENT_TYPE or "").. (EVENT_REF or "")
	.. ", \nEVENT_TYPE_N: " .. (EVENT_TYPE_N_EXT or "none")
	.. ", \nAFF_USR_EMAIL: " .. (AFF_USR_EMAIL or "none") 
	.. ", \nREP_USR_EMAIL: " .. (REP_USR_EMAIL or "none") 
	.. "\nASS_USR_SC: " .. (ASS_USR_SC or "none") 
	.. ", \nACTIONING_USR_SC: " .. (ACTIONING_USR_SC or "none") 
	.. ", \nASS_USR_EMAIL: " .. (ASS_USR_EMAIL or "none") 
	.. "\nASS_SVD_SC: " .. (ASS_SVD_SC or "none") 
	.. ", \nACTIONING_SVD_SC: " .. (ACTIONING_SVD_SC or "none") 
	.. ", \nASS_SVD_EMAIL: " .. (ASS_SVD_EMAIL or "none"))	

--------------------------------------------------------------------------------------
-- The rules and business logic associated with action that triggers this config
--------------------------------------------------------------------------------------
set_of_rules {
	{
		--------------------------------------------------------------------------------------
		-- Run SQL to get standard variables to be available to all subsequent rules
		-- Note:
		--		These queries are going to be implementation specific 
		--		Ideally AP would have a way of retrieving this type of data once at the start of 
		--		it's action cycle
		--------------------------------------------------------------------------------------
		name = [[ "Init - standard SQL" ]],
		data_generation = [[ {( strPathToSql .. "\\get_standard_values_sql.lua" ), 
			( strPathToSql .. "\\linked_events_sql.lua"),
			( strPathToSql .. "\\auto_select_custom_fields.lua"),
			( strPathToSql .. "\\get_approval_settings.lua") } ]],
		condition = [[
			true
		]],
		activities = {
			{"log", 
            [["Assign init complete"]]
			},
		},
		"continue",
	},
	
	
	-- Send an email to users to authorize the request.  The email can have an email reply and/or assystNET link
	{
		name = [[ "Task-Authorize - send user authorization email" ]],
		condition = [[
			((ASS_USR_EMAIL or "") ~= "")
		]],
		data_generation = [[ { (strPathToSql .. "\\get_task_type_sql.lua") } ]],
		activities = {
			{ "email", 
				recipients_special = [[ assigned_user() ]],
				subject = [[ strEmailSubjectPrefix .. "Notification " .. TICKET_TYPE_FOR_EMAIL .. " #$EVENT_TYPE_U$EVENT_REF" ]],
				body = [[ strPathToTemplates .. "\\authorize.html" ]],
			},
		},
		"stop",
	},
	
	-- Send an email to SVD to authorize the request.  The email can have an email reply and/or assystNET link
	{
		name = [[ "Task-Authorize - send authorization email" ]],
		condition = [[
			((ASS_SVD_EMAIL or "") == "")
		]],
		activities = {
			{ "email", 
				recipients_special = [[ { ASS_SVD_N, ASS_SVD_EMAIL } ]],
				subject = [[ strEmailSubjectPrefix .. "Notification " .. TICKET_TYPE_FOR_EMAIL .. " #$EVENT_TYPE_U$EVENT_REF" ]],
				body = [[ strPathToTemplates .. "\\authorize.html" ]],
			},
		},
		"stop",
	},
}