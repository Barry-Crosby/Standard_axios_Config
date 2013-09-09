--------------------------------------------------------------------------------------
-- Send_page.lua
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
-- Feb 27 2012	New File
--------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------
-- Include File With Common Global Variables, DB, Path and SMTP Information
--------------------------------------------------------------------------------------
dofile ("dofiles\\SmartMailParms.lua")
--------------------------------------------------------------------------------------
-- Log key data
--------------------------------------------------------------------------------------
LOGGER:info("Start of Send_page.lua: \nEVENT: " .. (EVENT_TYPE or "") .. (EVENT_REF or "") )

			--------------------------------------------------------------------------------------
-- Include File For Rule Dispatcher
--------------------------------------------------------------------------------------
dofile("dofiles\\SmartMailRuleDispatcher.lua")

--------------------------------------------------------------------------------------
-- Define the Controls For This Config
--------------------------------------------------------------------------------------
controls {
    test_mode_on = false,
    debug_to_outlook = true,
    use_import_processor = false,
}


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

strSubject = "Page for " .. EVENT_TYPE_N_EXT .. "#" .. EVENT_REF .. " - " .. ACT_DESC
strBody = strPathToTemplates .. "\page.txt"
set_of_rules {

	--------------------------------------------------------------------------------------
	{
	name = [[ "Send to user selected on action" ]],
		condition = [[
			((ACTION_CONTACT_USR_N or "") ~= "")
			and ((ACTION_CONTACT_EMAIL_ADD or "") ~= "")
		]],	
		data_generation = [[ { strPathToSql .. "\\get_action_contact_user_sql.lua" } ]],
		
		activities = {
			{ "email",  
				recipients_special = [[ {ACTION_CONTACT_USR_N, ACTION_CONTACT_EMAIL_ADD} ]],
				subject = [[ strEmailSubjectPrefix .. strSubject ]],
				body = [[ strBody ]]
			},
		},
		"stop",
	},
	
	
	{
	name = [[ "Send note to assignee if there is one with an email address" ]],
		condition = [[
			((ASS_USR_EMAIL or "") ~= "")					-- team has an email address
		]],
		activities = {
			{ "email", 
				recipients_special = [[ assigned_user() ]],
				subject = [[ strEmailSubjectPrefix .. strSubject ]],
				body = [[ strBody ]]
			}
		},
		"stop",
	},
	
	
	{
	name = [[ "Send note to assignee if there is one with an email address" ]],
		condition = [[
			((ASS_USR_EMAIL or "") ~= "")					-- team has an email address
		]],
		activities = {
			{ "email", 
				recipients_special = [[ assigned_user() ]],
				subject = [[ strEmailSubjectPrefix .. strSubject ]],
				body = [[ strBody ]]
			}
		},
		"stop",
	},
	
	{
	name = [[ "Send note to assigned team" ]],
		condition = [[
			true
		]],
		activities = {
			{ "email", 
				recipients_special = [[ assigned_svd() ]],
				subject = [[ strEmailSubjectPrefix .. strSubject ]],
				body = [[ strBody ]]
			}
		},
		"stop",
	},
}
