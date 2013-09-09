--------------------------------------------------------------------------------------
-- Notify_Imp_Users_rd.lua
-- Prepared for AGS SmartMail Quick Config (Version 3.0)
--
-- This script is not supported by Axios Systems. The script is provided as is and Axios Systems
-- accepts no responsibility or liability for the consequences of using this script.
--
----------------------------------------------------------------------------------------
-- Change log
-- Feb 27 2012	New File
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
LOGGER:info("Start of Notify_Imp_Users_rd.lua: \nACT_TYPE_SC: " .. (ACT_TYPE_SC or "") 
				.. ", \nEVENT_TYPE: " .. (EVENT_TYPE or "") 
				.. ", EVENT_REF: " .. (EVENT_REF or "") )

ITEM_USR_WHERE_SQL = "  usr_item_association_reasn.association_reason_sc NOT like('NON%') and "

set_of_rules {
	{
	name = [[ "Notify Impacted Users" ]],
		data_generation = [[ { strPathToSql .. "\\get_standard_values_sql.lua" } ]],
		condition = [[
			true
		]],
		activities = {
			{ "email", 
				recipients_special = [[ { 
					affected_user(), 
					reporting_user(), 
					additional_affected_users(), 
					custom_target(strPathToSql .. "\\notify_item_users_sql.lua")
					} ]],
				subject = [[ strEmailSubjectPrefix .. "Notification regarding " .. TICKET_TYPE_FOR_EMAIL .. " #$EVENT_TYPE_U$EVENT_REF for $ITEM_N" ]],
				body = [[ strPathToTemplates .. "\\inform_impacted_users.html" ]],
			},
		},
		"stop",
	},
}
--------------------------------------------------------------------------------------
--   End of File
--------------------------------------------------------------------------------------