--------------------------------------------------------------------------------------
-- The following rules are not executed.  These are provided as examples of extended
-- SmartMail functionality that is available.
--------------------------------------------------------------------------------------
		
	{
		name = [[ "Extra email for high risk change" ]],

		To enable this rule the following needs to be included in the environment section
--
--	CUST_FIELD_LIST = {
--		["RISK VALUE"] = "RISK_VALUE",
--	},
--
		condition = [[
			(EVENT_TYPE == "c")
			and (string.upper((RISK_VALUE or "")) == "HIGH")
			and (tonumber(ACT_TYPE_COUNT) == 1)
		]],
		data_generation = [[ { (strPathToSql .. "\\Web_Cust_Fields_SQL.lua") } ]],
		activities = {
			{ "email", 
				recipients = [[ { "ChangeManager@Anycorp.com" } ]],
				subject = [[ "Change Manager warning - High Impact change logged: #$EVENT_TYPE_U$EVENT_REF" ]],
				body = [[ strPathToTemplates .. "\\change_alert.html" ]],
			},
		},
		"continue",
	}

--	Alternate notification on ticket open - send to people marked as SVD managers
	{
		name = [[ "Notify Queue Owner on Open" ]],
		condition = [[
			tonumber(ACT_TYPE_COUNT) == 1
		]],
		activities = {
			{ "email", 
				recipients_special = [[ { 
					custom_target(strPathToSql .. "\\get_svd_managers_sql.lua")
					} ]],
				subject = [[ "$EVENT_TYPE_N_EXT #$EVENT_TYPE_U$EVENT_REF has been opened and assigned to your queue" ]],
				body = [[ strPathToTemplates .. "\\assign_to_queue.html" ]],
			},
		},
		"continue",
	},
	