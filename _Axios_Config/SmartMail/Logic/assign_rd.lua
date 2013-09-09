-- debug_to_outlook = true
-- debug_to_file = "assign_email_file.txt"

--------------------------------------------------------------------------------------
-- ASSIGN.lua (version 3.0)
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
LOGGER:info("Start of assign_rd.lua: \nACT_TYPE_COUNT: " .. (ACT_TYPE_COUNT or "") .. ", \nEVENT: " .. (EVENT_TYPE or "").. (EVENT_REF or "")
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
		data_generation = [[ {( strPathToSql .. "\\get_standard_values_sql.lua" ), ( strPathToSql .. "\\linked_events_sql.lua")} ]],
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
	
	{
		name = [[ "Notify Users of Open-FR" ]],
		condition = [[
			(tonumber(ACT_TYPE_COUNT) == 1)
			and (EVENT_TYPE == "i" or EVENT_TYPE == "c")
			and ((FRENCH or "") == "y")
		]],
		activities = {
			{ "email", 
				recipients_special = [[ {(affected_user()), (reporting_user())}]],
				subject = [[ strEmailSubjectPrefix .. TICKET_TYPE_FOR_EMAIL .. " #$EVENT_TYPE_U$EVENT_REF has been opened" ]],
				body = [[ strPathToTemplates .. "\\assign_open_fake_fr.html" ]],
			},
		},
		"continue",
	},
	
	{
		name = [[ "Notify Users of Open" ]],
		condition = [[
			(tonumber(ACT_TYPE_COUNT) == 1)
			and (EVENT_TYPE == "i" or EVENT_TYPE == "c")
			and ((FRENCH or "") ~= "y")
		]],
		activities = {
			{ "email", 
				recipients_special = [[ {(affected_user()), (reporting_user())}]],
				subject = [[ strEmailSubjectPrefix .. TICKET_TYPE_FOR_EMAIL .. " #$EVENT_TYPE_U$EVENT_REF has been opened" ]],
				body = [[ strPathToTemplates .. "\\assign_Open.html" ]],				
			},
		},
		"continue",
	},
		
	{
		name = [[ "Notify assigned user" ]],
		condition = [[
			((ASS_USR_SC  or "") ~= "")									-- Is assigned to an assyst user
			and (ASS_USR_SC ~= ACTIONING_USR_SC)						-- Who isn't the actioning user
			and ((ASS_USR_EMAIL or "") ~= "")							-- Finally, the assigned user has a non-blank email address.
		]],
		data_generation = [[ { (strPathToSql .. "\\auto_select_custom_fields.lua") } ]],
		activities = {
			{ "email", 
				template_parameters = [[ { ASSIGNED_TO_TEXT = "you" } ]],
				recipients_special = [[ assigned_user() ]],
				subject = [[ strEmailSubjectPrefix .. TICKET_TYPE_FOR_EMAIL .. " #$EVENT_TYPE_U$EVENT_REF has been assigned to you" ]],
				body = [[ strPathToTemplates .. "\\assign_to.html" ]],
			},
		},
		"continue",
	},
	
	{
		name = [[ "Notify assigned team if assigned user has no email" ]],
		condition = [[
			((ASS_USR_SC  or "") ~= "")									-- Is assigned to an assyst user
			and (ASS_USR_SC ~= ACTIONING_USR_SC)						-- Who isn't the actioning user
			and ((ASS_USR_EMAIL or "") == "")							-- Finally, the assigned user has a blank email address.
		]],
		data_generation = [[ { (strPathToSql .. "\\auto_select_custom_fields.lua") } ]],
		activities = {
			{ "email",			 
				template_parameters = [[ { ASSIGNED_TO_TEXT = ASS_USR_N} ]],
				recipients_special = [[ { ASS_SVD_N, ASS_SVD_EMAIL } ]],
				subject = [[ strEmailSubjectPrefix .. TICKET_TYPE_FOR_EMAIL .. " #$EVENT_TYPE_U$EVENT_REF has been assigned to $ASS_USR_N" ]],
				body = [[ strPathToTemplates .. "\\assign_to.html" ]]
			}
		},
		"continue",
	},
	
	{
		name = [[ "Notify assigned (but not actioning) SVD" ]],
		condition = [[
			((ASS_USR_EMAIL or "") == "")						-- no assyst user email
			and (ASS_SVD_SC ~= ACTIONING_SVD_SC)				-- assigned to a different team
			and ((ASS_SVD_EMAIL or "") ~= "")					-- team has an email address
		]],
		data_generation = [[ { (strPathToSql .. "\\auto_select_custom_fields.lua") } ]],
		activities = {
			{ "email", 
				template_parameters = [[ { ASSIGNED_TO_TEXT = "your Service Department"} ]],
				recipients_special = [[ { ASS_SVD_N, ASS_SVD_EMAIL } ]],
				subject = [[ strEmailSubjectPrefix .. TICKET_TYPE_FOR_EMAIL .. " #$EVENT_TYPE_U$EVENT_REF has been assigned to $ASS_SVD_N" ]],
				body = [[ strPathToTemplates .. "\\assign_to.html" ]]
			}
		},
		"continue",
	}
	
}