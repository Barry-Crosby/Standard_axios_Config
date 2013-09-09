--------------------------------------------------------------------------------------
-- Include File With Common Global Variables, DB, Path and SMTP Information
--------------------------------------------------------------------------------------
dofile("dofiles\\SmartMailParms.lua")


attachments {
	selected_attachments_header = "ATTACHMENTS SENT",
	existing_attachments_prefix = "S",
	temporary_attachments_prefix = "D",
	note_for_non_assyst_attachments = "not part of assyst",
}


--------------------------------------------------------------------------------------
-- Include File For Rule Dispatcher
--------------------------------------------------------------------------------------
dofile("dofiles\\SmartMailRuleDispatcher.lua")

--------------------------------------------------------------------------------------
-- RulesDispatcherControls
--------------------------------------------------------------------------------------
controls {
    test_mode_on = controls_default_test_mode_on,
    debug_to_outlook = controls_default_debug_to_outlook,
    use_import_processor = controls_default_use_import_processor,
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

bSendAttachments = true
--------------------------------------------------------------------------------------
-- The rules and business logic associated with action that triggers this config
--------------------------------------------------------------------------------------
set_of_rules {
	{

		name = [[ "Notify Users of Open" ]],
		data_generation = [[ { strPathToSql .. "\\get_standard_values_sql.lua" } ]],
		condition = [[
			(EVENT_TYPE == "i" or EVENT_TYPE == "c")
		]],
		activities = {
			{ "email", 
				recipients_special = [[ {(affected_user()), (reporting_user())}]],
				subject = [[ strEmailSubjectPrefix .. "IS Request $EVENT_TYPE_U$EVENT_REF has been opened" ]],
				body = [[ strPathToTemplates .. "\\assign_Open.html" ]],
				
			},
		},
		"continue",
	},
	{
		name = [[ "Send with attachments" ]],
		condition = [[
			bSendAttachments
		]],
		activities = {
			{ "email", 
				recipients_special = [[ {(affected_user()), (reporting_user())}]],
				subject = [[ strEmailSubjectPrefix .. "IS Request $EVENT_TYPE_U$EVENT_REF has attachments" ]],
				body = [[ strPathToTemplates .. "\\assign_Open.html" ]],
				add_attachments_from_action = true,
			},
		},
		"continue",
	},
}


email {
	sender = "servicedesk@anycorp.com",
	recipients = { "test@anycorp.com"},
	header = {
        from    = "Service Desk <servicedesk@anycorp.com>", 
		subject = "$strEmailSubjectPrefixUpdate with attachments for $EVENT_REF",
	},
	body = "attachments.html",
	add_attachments_from_action = true,
}	