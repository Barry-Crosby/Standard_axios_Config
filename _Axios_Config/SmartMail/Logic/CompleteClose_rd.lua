--------------------------------------------------------------------------------------
-- CompleteClose.lua
-- Prepared for AGS SmartMail Quick Config (Version 3.0)
--
-- This script is not supported by Axios Systems. The script is provided as is and Axios Systems
-- accepts no responsibility or liability for the consequences of using this script.
--
----------------------------------------------------------------------------------------
-- Change log
-- Feb 15, 2012 - updated to use RulesDispatcher
--------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------
-- Include File With Common Global Variables, DB, Path and SMTP Information
--------------------------------------------------------------------------------------
dofile("dofiles\\SmartMailParms.lua")
BypassLoggingEnvironment = "y"
dofile(strRoot .. "Common\\BaseConfigEJB.lua") 
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
LOGGER:info(("Start of CompleteClose_rd.lua - ACT_TYPE_SC: " .. (ACT_TYPE_SC or "") .. ", EVENT_TYPE: " .. (EVENT_TYPE or "")) .. (EVENT_REF or "") 
	.. ", EVENT_STATUS: " .. (EVENT_STATUS or ""))

--------------------------------------------------------------------------------------
-- The rules and business logic associated with action that triggers this config
--------------------------------------------------------------------------------------
set_of_rules {
	{
		name = [[ "Auto Close Event" ]],
		data_generation = [[ { strPathToSql .. "\\get_standard_values_sql.lua" } ]],
		condition = [[
			EVENT_STATUS == 'o'
			or EVENT_STATUS == 'p'
		]],
		activities = {
			{ "new_action_ejb",
				eventId		= [[ EVENT_ID ]],
				remarks	 	= [[ "Auto close event"]],
				actionTypeId 	= [[ lookup{"ActionType", "CLOSURE"} ]],
				causeCategoryId = [[ lookup{"Category", "AUTO CLOSE"} ]],
				causeItemId = [[ lookup{"Item", "AUTO CLOSE"} ]],			
				actionedById = [[ lookup{"AssystUser", ACTIONING_USR_SC} ]],			   
				serviceTime = [[{duration = tonumber(100)}]],
				serviceCost = [[{double = tonumber(2)}]],
			}
		},
		"stop",
	},
}