--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
-- Knowledge_Candidate.lua
--------------------------------------------------------------------------------------
-- Prepared for AGS SmartMail Quick Config (Version 3.0)
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
LOGGER:info("Start of Knowledge_Candidate.lua: \nEVENT_TYPE: " .. (EVENT_TYPE or "") .. EVENT_REF)

set_of_rules {
	
	{
	name = [[ "Validate Knowledge Manager Email" ]],
		data_generation = [[ { strPathToSql .. "\\get_standard_values_sql.lua" } ]],
		condition = [[
			(strKnowledgeOwnEmail or "") == ""
		]],
		activities = {
			{"log", 
            [["Knowledge Canadidate email bypassed - strKnowledgeOwnEmail parameter not set"]]
			},
		},
		"stop",
	},	
	
	{
	name = [[ "Notify Knowledge Manager of Knowledge Candidate" ]],
		condition = [[
			true
		]],
		activities = {
			{ "email", 
				recipients = [[ strKnowledgeOwnEmail ]],
				subject = [[ strEmailSubjectPrefix .. "Knowledge Candidate flagged on " .. EVENT_TYPE_U .. EVENT_REF ]],
				body = [[ strPathToTemplates .. "\\Knowledge_Candidate.html" ]]
			}
		},
		"stop",
	},	
}

--------------------------------------------------------------------------------------
--   End of File
--------------------------------------------------------------------------------------