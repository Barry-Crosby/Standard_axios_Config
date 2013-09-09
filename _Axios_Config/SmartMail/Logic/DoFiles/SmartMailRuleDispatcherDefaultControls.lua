--------------------------------------------------------------------------------------
-- SmartMailRuleDispatcherDefaultControls.lua
-- Prepared for AGS SmartMail Quick Config (Version 4.0)
--
-- This script is not supported by Axios Systems. The script is provided as is and Axios Systems
-- accepts no responsibility or liability for the consequences of using this script.
--
----------------------------------------------------------------------------------------
-- Change log
-- Apr 30, 2012	- New file
--------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------
-- RulesDispatcherControls
--------------------------------------------------------------------------------------
controls {
    test_mode_on = controls_default_test_mode_on,
    debug_to_outlook = controls_default_debug_to_outlook,
    use_import_processor = controls_default_use_import_processor,
	
	email_test_filter = {
		ON = controls_email_test_filter_on,
		allowed = controls_email_test_filter_allowed,
		otherwise = controls_email_test_filter_otherwise
	},

	admin_email = {
		ON		= controls_admin_email_on, 
		name		= controls_admin_email_name, 
		email		= controls_admin_email_email_address,
		template	= strPathToTemplates .. "\\rule_dispatcher_error.txt"
	}
}
