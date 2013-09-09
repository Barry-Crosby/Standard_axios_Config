--------------------------------------------------------------------------------------
-- Chase_up.lua
-- Prepared for AGS SmartMail Quick Config (Version 3.0)
--
--	Send an email to the assigned user/team when a "chase up" action is taken.
--	The Chase Up action has been renamed to Status Request.
--
--
-- This script is not supported by Axios Systems. The script is provided as is and Axios Systems
-- accepts no responsibility or liability for the consequences of using this script.
--
--------------------------------------------------------------------------------------
-- Change log
-- Feb 27 2012	Updated for Rules Dispatcher
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
LOGGER:info("Start of chase-up.lua: \nEVENT: " .. (EVENT_TYPE or "") .. (EVENT_REF or "") 
			.. ", \ASS_USR_SC: " .. (ASS_USR_SC or "") 
			.. ", \nACTIONING_USR_SC: " .. (ACTIONING_USR_SC or "")
			.. ", \ASS_SVD_SC: " .. (ASS_SVD_SC or "") 
			.. ", \ACTIONING_SVD_SC: " .. (ACTIONING_SVD_SC or ""))

set_of_rules {
	{
	name = [[ "Bypass if actioned by Service Desk or assigned team" ]],
		data_generation = [[ { strPathToSql .. "\\get_standard_values_sql.lua" } ]],
		condition = [[
			((ACTIONING_SVD_SC or "") == strServiceDeskSVD)
			or ((ACTIONING_SVD_SC or "") == ASS_SVD_SC)
		]],
		activities = {
			{"log", 
            [["Follow up Email bypassed - actioned by Service Desk or assigned team"]]
			},
		},
		"stop",
	},
	
	{
	name = [[ "Send note to assignee if action not taken by Service Desk or assigned team" ]],
		condition = [[
			((ASS_USR_EMAIL or "") ~= "")					-- team has an email address
		]],
		activities = {
			{ "email", 
				recipients_special = [[ assigned_user() ]],
				subject = [[ strEmailSubjectPrefix .. "Status Request for " .. TICKET_TYPE_FOR_EMAIL .. " #$EVENT_TYPE_U$EVENT_REF" ]],
				body = [[ strPathToTemplates .. "\\chase_up.html" ]]
			}
		},
		"stop",
	},
	
	{
	name = [[ "Send note to assigned team" ]],
		condition = [[[[
			((ASS_SVD_EMAIL or "") ~= "")					-- team has an email address
		]],
		activities = {
			{ "email", 
				recipients_special = [[ { ASS_SVD_N, ASS_SVD_EMAIL } ]],
				subject = [[ strEmailSubjectPrefix .. "Status Request for " .. TICKET_TYPE_FOR_EMAIL .. " #$EVENT_TYPE_U$EVENT_REF" ]],
				body = [[ strPathToTemplates .. "\\chase_up.html" ]]
			}
		},
		"stop",
	},
}
