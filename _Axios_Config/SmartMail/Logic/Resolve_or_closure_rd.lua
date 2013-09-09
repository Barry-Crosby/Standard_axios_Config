--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
-- Resolve_or_closure.lua
--------------------------------------------------------------------------------------
-- Prepared for AGS SmartMail Quick Config (Version 3.0)
--
-- This script is not supported by Axios Systems. The script is provided as is and Axios Systems
-- accepts no responsibility or liability for the consequences of using this script.
--
----------------------------------------------------------------------------------------
-- Change log
-- Sep  9 2009	Added logic for different facilities emails
-- Sep 10 2009	Corrected to send resolve emails when required
-- Feb 25 2010  Removed EVENT_TYPE_U calculation. It is included in SmartMailFunctions.lua
-- Feb 14 2012  Added define of cc_name, cc_email variables to avoid potential nil error
-- Feb 15 2012  updated to use RulesDispatcher
-- Aug 01 2012  Added check to ensure we have email addresses to send to

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
LOGGER:info(("Start of Resolve_or_closure.lua \n, EVENT_TYPE: " .. (EVENT_TYPE or "") .. (EVENT_REF or "")) 
	.. "\nAFF_USR_EMAIL: " .. (AFF_USR_EMAIL or "") .. ", \nREP_USR_EMAIL: " 
	.. (REP_USR_EMAIL or "") .. ", \nCAUSE_CATEGORY_SC: " .. (CAUSE_CATEGORY_SC or ""))

--------------------------------------------------------------------------------------
-- The rules and business logic associated with action that triggers this config
--------------------------------------------------------------------------------------
set_of_rules {
	{
		name = [[ "Skip if already resolved" ]],
			condition = [[
				((ACT_TYPE_SC == "CLOSURE") 
				and (has_action_taken("RESOLVED") == true))
			]],
			activities = { },
			"stop",
	},
	
	{
		name = [[ "Skip if no email addresses" ]],
			condition = [[
				(((REP_USR_EMAIL or "") == "")
				and ((AFF_USR_EMAIL or "") == ""))
			]],
			activities = { },
			"stop",
	},
	
	{
		--------------------------------------------------------------------------------------
		-- Run SQL to get standard variables to be available to all subsequent rules
		--------------------------------------------------------------------------------------
		name = [[ "Init - standard SQL" ]],
		data_generation = [[ {( strPathToSql .. "\\get_standard_values_sql.lua" ), 
			( strPathToSql .. "\\get_parent_check_sql.lua" )} ]],
		condition = [[
			true
		]],
		activities = {
			{"log", 
            [["Resolve or closure init complete"]]
			},
		},
		"continue",
	},
	
	{
		name = [[ "Skip if parent" ]],
			condition = [[
				EVENT_IS_PARENT
			]],
			activities = { },
			"stop",
	},
	
	{
		name = [[ "Register a service request resolution survey" ]],
			data_generation = [[ { strPathToSql .. "\\get_standard_values_sql.lua" } ]],
			condition = [[
				bIncludeSurvey
					and	(EVENT_TYPE == "i" or EVENT_TYPE == "c")
					and (MAJOR_CATEGORY_SC == strRequestMajorCategorySC)
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
		name = [[ "Register an incident resolution survey" ]],
			condition = [[
				bIncludeSurvey
					and	(EVENT_TYPE == "i" or EVENT_TYPE == "c")
					and (MAJOR_CATEGORY_SC ~= strRequestMajorCategorySC)
			]],
				
			activities = {
				{ "survey_request",
					SURVEY_DEF_SC = [["INCIDENT RESOLUTION SURVEY"]]
				},
				{ "log",
					[["Survey incident link EMAIL_SURVEY_URL_EN: " .. EMAIL_SURVEY_URL_EN]]
				},
			},
			"continue",
	},
	{
		name = [[ "Notify Users of Closure" ]],			
			condition = [[
				ACT_TYPE_SC == "CLOSURE"
			]],

			activities = {
				{ "email", 
					recipients_special = [[ {(affected_user()), (reporting_user())}]],
					subject = [[ strEmailSubjectPrefix .. TICKET_TYPE_FOR_EMAIL .. " $EVENT_TYPE_U$EVENT_REF has been closed" ]],
					body = [[ strPathToTemplates .. "\\closure.html" ]]
				},
			},
			"stop",
	},
	{
		name = [[ "Notify Users of Resolve" ]],			
			condition = [[
				ACT_TYPE_SC ~= "CLOSURE"
			]],
			activities = {
				{ "email", 
					recipients_special = [[ {(affected_user()), (reporting_user())}]],
					subject = [[ strEmailSubjectPrefix .. TICKET_TYPE_FOR_EMAIL .. " $EVENT_TYPE_U$EVENT_REF has been resolved" ]],
					body = [[ strPathToTemplates .. "\\resolved.html" ]]
				},
			},
			"continue",
	},
} -- end of rules

--------------------------------------------------------------------------------------
--   End of File
--------------------------------------------------------------------------------------