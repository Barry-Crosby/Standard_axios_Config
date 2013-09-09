--------------------------------------------------------------------------------------
-- Send-Email.lua
-- Prepared for AGS SmartMail Quick Config (Version 3.0)
--
-- This script is not supported by Axios Systems. The script is provided as is and Axios Systems
-- accepts no responsibility or liability for the consequences of using this script.
--
----------------------------------------------------------------------------------------
-- Change log
-- Feb 14 2012	Change ACTION_CONTACT_N to ACTION_CONTACT_USR_N to prevent nil error in subroutines.
-- Feb 15, 2012 - updated to use RulesDispatcher
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
LOGGER:info("Start of send-email.lua: \nACT_TYPE_SC: " .. (ACT_TYPE_SC or "") 
				.. ", \nEVENT_TYPE: " .. (EVENT_TYPE or "") 
				.. ", AFF_USR_EMAIL: " .. (AFF_USR_EMAIL or "") 
				.. ", \nREP_USR_EMAIL: " .. (REP_USR_EMAIL or "") 
				.. ", ACTIONING_USR_SC: " .. (ACTIONING_USR_SC or ""))

--------------------------------------------------------------------------------------
-- The rules and business logic associated with action that triggers this config
--------------------------------------------------------------------------------------
set_of_rules {
	--------------------------------------------------------------------------------------
	--   Ensure there's an email address to send to or stop
	--------------------------------------------------------------------------------------
	{
	name = [[ "Basic validation" ]],
		condition = [[
			((AFF_USR_EMAIL or "") == "")
			and ((REP_USR_EMAIL or "") == "")
			and ((ACTION_CONTACT_EMAIL_ADD or "") == "")
			and ((ACTIONING_USR_EMAIL or "") == "")
		]],
		data_generation = [[ { ( strPathToSql .. "\\get_standard_values_sql.lua" ), 
				( strPathToSql .. "\\get_action_contact_user_sql.lua" ) } ]],
		activities = {
			{"log", 
            [[Send-email failure – no email addresses available]]
			},
		},

		"stop",
	},

	{
		name = [[ "Init - standard processing to get event types" ]],
		condition = [[
			true
		]],
		------------------------------------------------------------------------
		-- Run general SQL
		------------------------------------------------------------------------
		data_generation = [[ { (strPathToSql .. "\\get_standard_values_sql.lua"),  (strPathToSql .. "\\get_language_sql.lua") } ]],
		activities = {
			{"log", 
            [["Init complete"]]
			},
		},
		"continue",
	},
	
	--------------------------------------------------------------------------------------
	--   Email has selected action user but they have no email so notify actioning user
	--------------------------------------------------------------------------------------
	{
	name = [[ "Action user has no email address" ]],
		condition = [[
			((ACTION_CONTACT_USR_N or "") ~= "")
			and ((ACTION_CONTACT_EMAIL_ADD or "") == "")
		]],	
		activities = {
			{ "email", 
				template_parameters = [[ { SEND_EMAIL_USR_N = ACTION_CONTACT_USR_N } ]],
				recipients_special = [[ actioning_user() ]],
				subject = [[ strEmailSubjectPrefix .. "No email address listed for $ACTION_CONTACT_USR_N re #$EVENT_TYPE_U$EVENT_REF" ]],
				body = [[ strPathToTemplates .. "\\Send_Email No Email User.html" ]],
			},
		},
		"stop",
	},
	
	--------------------------------------------------------------------------------------
	{
	name = [[ "Send to user selected on action" ]],
		condition = [[
			(ACTION_CONTACT_EMAIL_ADD or "") ~= ""
		]],	
		activities = {
			{ "email",  
				template_parameters = [[ { SEND_EMAIL_USR_N = ACTION_CONTACT_USR_N } ]],
				recipients_special = [[ {ACTION_CONTACT_USR_N, ACTION_CONTACT_EMAIL_ADD} ]],
				subject = [[ strEmailSubjectPrefix .. TICKET_TYPE_FOR_EMAIL .. " #$EVENT_TYPE_U$EVENT_REF update" ]],
				body = [[ strPathToTemplates .. "\\Send_Email.html" ]],
			},
		},
		"stop",
	},
	
	
	--------------------------------------------------------------------------------------
	{
	name = [[ "Send to affected and/or reporting user" ]],
		condition = [[
			((AFF_USR_N or "") ~= "")
		]],	
		
		activities = {
			{ "email", 
				recipients_special = [[ {(affected_user()), (reporting_user())}]],
				subject = [[ strEmailSubjectPrefix .. TICKET_TYPE_FOR_EMAIL .. " #$EVENT_TYPE_U$EVENT_REF update" ]],
				body = [[ strPathToTemplates .. "\\Send_Email.html" ]],
			},
		},
		"stop",
	},
}
--------------------------------------------------------------------------------------
--   End of File
--------------------------------------------------------------------------------------