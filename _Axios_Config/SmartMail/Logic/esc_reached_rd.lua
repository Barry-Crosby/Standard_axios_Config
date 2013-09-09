--debug_to_outlook = true

--------------------------------------------------------------------------------------
-- Esc_Reached.lua
-- Prepared for AGS SmartMail Quick Config (Version 3.0)
--
-- This script is not supported by Axios Systems. The script is provided as is and Axios Systems
-- accepts no responsibility or liability for the consequences of using this script.
--
----------------------------------------------------------------------------------------
-- Change log
-- Feb 27 2012	Send Escalation Emails to escalation users
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
LOGGER:info("Start of Esc_Reached.lua: \nACT_TYPE_SC: " .. (ACT_TYPE_SC or "") 
				.. ", \nEVENT_TYPE: " .. (EVENT_TYPE or "") 
				.. ", EVENT_REF: " .. (EVENT_REF or "") 
				.. ", \nAFF_USR_EMAIL: " .. (AFF_USR_EMAIL or "") 
				.. ", \nREP_USR_EMAIL: " .. (REP_USR_EMAIL or "") 
				.. ", \nACTIONING_USR_SC: " .. (ACTIONING_USR_SC or ""))

set_of_rules {
	{
	name = [[ "Send Escalation Emails BASED ON SLA" ]],
		condition = [[
			true
		]],
		------------------------------
		-- NOTE:  bEscManager and bEscAssignee are set by get_esc_users_special_sql.lua
		------------------------------
		data_generation = [[ { (strPathToSql .. "\\get_standard_values_sql.lua"), (strPathToSql .. "\\get_esc_users_special_sql.lua") } ]],
		activities = {
			{ "email", 
				recipients_special = [[ custom_target(strPathToSql .. "\\get_esc_users_sql.lua") ]],
				subject = [[ strEmailSubjectPrefix .. "Escalation level $ESC_LEVEL reached for " .. TICKET_TYPE_FOR_EMAIL .. " #$EVENT_TYPE_U$EVENT_REF" ]],
				body = [[ strPathToTemplates .. "\\Esc_Reached.html" ]],
			},
		},

		"continue",
	},
	{
	name = [[ "Send Escalation To SVD Manager" ]],
		condition = [[
			bEscManager
		]],
		activities = {
			{ "email", 
				recipients_special = [[ { 
					custom_target(strPathToSql .. "\\get_svd_managers_sql.lua")
					} ]]
				subject = [[ strEmailSubjectPrefix .. "Escalation level $ESC_LEVEL reached for " .. TICKET_TYPE_FOR_EMAIL .. " #$EVENT_TYPE_U$EVENT_REF (manager notification)" ]],
				body = [[ strPathToTemplates .. "\\Esc_Reached.html" ]],
			},
		},

		"continue",
	},
	{
	name = [[ "Send Escalation To assignee" ]],
		condition = [[
			bEscAssignee
			and  ((ASS_USR_EMAIL or "") ~= "")
		]],
		activities = {
			{ "email", 
				recipients_special = [[ assigned_user() ]],
				subject = [[ strEmailSubjectPrefix .. "Escalation level $ESC_LEVEL reached for " .. TICKET_TYPE_FOR_EMAIL .. " #$EVENT_TYPE_U$EVENT_REF (assignee notification)" ]],
				body = [[ strPathToTemplates .. "\\Esc_Reached.html" ]],
			},
		},

		"continue",
	},
	{
	name = [[ "Send Escalation To assigned team" ]],
		condition = [[
			bEscAssignee
			and ((ASS_USR_EMAIL or "") == "")
		]],
		activities = {
			{ "email", 
				recipients_special = [[ { ASS_SVD_N, ASS_SVD_EMAIL } ]],
				subject = [[ strEmailSubjectPrefix .. "Escalation level $ESC_LEVEL reached for " .. TICKET_TYPE_FOR_EMAIL .. " #$EVENT_TYPE_U$EVENT_REF" ]],
				body = [[ strPathToTemplates .. "\\Esc_Reached.html" ]],
			},
		},

		"continue",
	},
}
--------------------------------------------------------------------------------------
--   End of File
--------------------------------------------------------------------------------------