--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
-- Complete.lua
--------------------------------------------------------------------------------------
-- Prepared for AGS SmartMail Quick Config
--
-- This script is not supported by Axios Systems. The script is provided as is and Axios Systems
-- accepts no responsibility or liability for the consequences of using this script.
--
----------------------------------------------------------------------------------------
-- Change log
-- Jul 31, 2012 - new file

--------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------
-- Include File With Common Global Variables, DB, Path and SMTP Information
--------------------------------------------------------------------------------------
dofile ("dofiles\\SmartMailParms.lua")

--------------------------------------------------------------------------------------
-- Include File For Rule Dispatcher
--------------------------------------------------------------------------------------
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
LOGGER:info(("Start of Complete.lua \n, EVENT_TYPE: " .. (EVENT_TYPE or "") .. (EVENT_REF or "")) 
	.. "\nAFF_USR_EMAIL: " .. (AFF_USR_EMAIL or "") .. ", \nREP_USR_EMAIL: " 
	.. (REP_USR_EMAIL or "") )

--------------------------------------------------------------------------------------
-- The rules and business logic associated with action that triggers this config
--------------------------------------------------------------------------------------
set_of_rules {
	{
		--------------------------------------------------------------------------------------
		-- Run SQL to get standard variables to be available to all subsequent rules
		--------------------------------------------------------------------------------------
		name = [[ "Init - standard SQL" ]],
		data_generation = [[ {( strPathToSql .. "\\get_standard_values_sql.lua" ) } ]],
		condition = [[
			true
		]],
		activities = {
			{"log", 
            [["Complete init complete"]]
			},
		},
		"continue",
	},
	
	{
		name = [[ "Register a service request resolution survey" ]],
			condition = [[
				bIncludeSurvey
				]],
			activities = {
				{ "survey_request",
					SURVEY_DEF_SC = [["REQUEST FULFILLMENT SURVEY"]]
				},		
				{ "log",
					[["Survey request link EMAIL_SURVEY_URL_EN $EMAIL_SURVEY_URL_EN"]]
				},
			},
			"continue",
	},	
	{
		name = [[ "Notify Users of Completion" ]],			
			condition = [[
				true
			]],

			activities = {
				{ "email", 
					recipients_special = [[ {(affected_user()), (reporting_user())}]],
					subject = [[ strEmailSubjectPrefix .. TICKET_TYPE_FOR_EMAIL .. " $EVENT_TYPE_U$EVENT_REF has been completed" ]],
					body = [[ strPathToTemplates .. "\\Complete.html" ]]
				},
			},
			"stop",
	},
} -- end of rules

--------------------------------------------------------------------------------------
--   End of File
--------------------------------------------------------------------------------------