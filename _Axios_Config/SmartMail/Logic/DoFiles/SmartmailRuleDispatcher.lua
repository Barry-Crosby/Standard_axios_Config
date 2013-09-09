--@+leo-ver=5-thin
--@+node:eoin.20111114141409.1277: * @thin SmartmailRuleDispatcher.lua
--@@c
--@@language lua
--@+others
--@+node:eoin.20111114141409.1268: ** root
--@+node:eoin.20120112113540.1328: *3* COMPILE TIME
--@+node:eoin.20120112113540.1321: *4* Dispatcher local global variables
--@@c

--[[
	============= SECTION: Dispatcher local global variables ===============
--]]
--@+node:eoin.20111114141409.1269: *5* Array to store datagen files already run
--@@c

--[[
	This records the names/paths of the data generation files that are run as the rules progress.
	Use this to prevent a re-run of the same file by several different rules. It's an efficiency thing (breaking the premature optimisation rule, perhaps).
--]]
local ruleset_datagen_files = {}
--@+node:eoin.20120111111758.1312: *5* Define list of activity types
--@@c

local available_activity_types = {
	"email", 
	"log", 
	"script", 
	"new_action", 
	"update_event",
	"new_action_ejb", 
	"update_event_ejb", 
	"conditional_group", 
	"survey_request",
}
--@+node:eoin.20120316145643.1324: *5* Define list of standard email targets
--@@c
--@@language lua

local standard_targets = {
	"affected_user",
	"reporting_user",
	"logging_user",
	"assigned_user",
	"actioning_user",
	"actioning_supplier",
	"additional_affected_users"
}
--@+node:eoin.20111114141409.1273: *4* Definition of coalesce and coalesce_recall functions
--@@c

--[[
	========= SECTION: Define the coalesce function =================
--]]

-- Building and returning the closure used to find first non-null/nil argument and storing its index.
-- Subsequent calls to the same closure return the stored index
function setup_coalesce()
	local index = nil
	return function(args, recall)
		-- Prequisite for doing anything: args must be a non-nil 
		if not args then return nil end

		-- Must be operating on array
		if type(args) ~= "table" then return nil end

		-- Testing the recall flag
		if recall then
			-- Retrieve stored result
		else
			-- This is a direct invocation of coalesce. Reset the index.
			index = nil
		end

		if index and (index > 0) then
			-- First call to coalesce got a non-nil entry and recorded its position
			-- Return the corresponding argument in supplied array (subsequent call to coalesce)
			return args[index] 
		elseif index and (index == 0) then
			-- First call to coalesce had found no non-nil entries.
			-- No basis for selecting entry for subsequent calls. Return nil
			return nil
		end

		-- Index is nil. Fresh call to coalesce
		for i = 1, table.getn(args) do
			if args[i] then
				index = i 
				break
			end
		end
		if index then 
			return args[index] 
		else
			-- None of the entries in the first call to coalesce were non-nil
			index = 0
		end
	end
end

function coalesce_recall(args)
	return coalesce(args, true)
end

-- Create the coalesce function 
coalesce = setup_coalesce()
--@+node:eoin.20120314155021.1319: *4* Email address filter and replace
--@@c
--@@language lua

--[[
	============= SECTION: Email address filter and replace ============

	Use of this function is controlled by the email_test_filter control variable
--]]

function apply_email_test_filter(email)
	if email_test_filter and email_test_filter.ON then
		if not element(lower(email), email_test_filter.allowed) and (email ~= email_test_filter.otherwise) then
			-- Replace with the default email address
			return email_test_filter.otherwise
		end
	end
	-- No replacement occurred. Just return the input email address
	return email
end
--@+node:eoin.20120314125129.1317: *4* Email address validation and formatting
--@@c

--[[
	============= SECTION: Email address validation and formatting ===============
--]]

function is_valid_email(email)
	if email and (email ~= NULL) and (trim(email) ~= "") then	
		return email
	else
		return nil
	end
end

function is_email_address(input)
	local email_pattern = "[A-Za-z0-9%.%%%+%-]+@[A-Za-z0-9%.%%%+%-]+%.%w%w%w?%w?"
	if input 
		and (input ~= NULL) 
		and (type(input) == "string") 
		and (string.match(trim(input), email_pattern)) then

		return true
	else
		return false
	end
end

function is_name_email_pair(recipients_data)
	if type(recipients_data) == "table" 
		and table.getn(recipients_data) == 2
		and type(recipients_data[1]) == "string"
		and type(recipients_data[2]) == "string" then

		if is_email_address(recipients_data[1]) and (not is_email_address(recipients_data[2])) then
			return true
		elseif is_email_address(recipients_data[2]) and (not is_email_address(recipients_data[1])) then
			return true
		elseif is_email_address(recipients_data[1]) and is_email_address(recipients_data[2]) then
			return false
		else
			return false
		end
	else
		return false
	end
end

function format_email_string(name, email)
	return [["]] .. name .. [[" <]] .. apply_email_test_filter(email) .. [[>]] 
end

function formatted_email(name, email)
	return { elist = {apply_email_test_filter(email)}, estring = format_email_string(name, email) }
end

function format_name_email_pair(recipients_data)
	if is_email_address(recipients_data[1]) and (not is_email_address(recipients_data[2])) then
		return formatted_email(recipients_data[2], recipients_data[1])
	elseif is_email_address(recipients_data[2]) and (not is_email_address(recipients_data[1])) then
		return formatted_email(recipients_data[1], recipients_data[2])
	end
end



--@+node:eoin.20111114141409.1276: *4* Email list assembly
--@@c

--[[
	============= SECTION: Email address list assembly ===============
--]]
--@+node:eoin.20120316145643.1323: *5* Using SQL queries
--@@c
--@@language lua

function formatted_list_from_result_set(rs_email)
	local elist = {}
	local estring = ""
	local have_at_least_one_entry = false

	if rs_email then
		for i = 1, rs_email.n do
			if is_valid_email(rs_email.EMAIL[i]) then
				have_at_least_one_entry = true
				table.insert(elist, rs_email.EMAIL[i])
				if i == 1 then
					estring = estring .. format_email_string(rs_email.NAME[i], rs_email.EMAIL[i])
				else
					estring = estring .. ", " ..  format_email_string(rs_email.NAME[i], rs_email.EMAIL[i])
				end
			end
		end
	end

	if have_at_least_one_entry then
		return { ["elist"] = elist, ["estring"] = estring}
	else
		return nil
	end
end

function formatted_email_list_from_query(query_email)
	local rs_email, err = ASSYST:multi_row_sql(query_email)

	if rs_email then
		return formatted_list_from_result_set(rs_email)
	else
		return nil, err
	end
end
--@+node:eoin.20120316145643.1320: *5* Standard targets
--@@c
--@@language lua

function build_email_list_and_string(target, sql)
	--[[
		The list is a table of email addresses that is the 'recipients' parameter in the Smartmail email function
		The string is the formatted header.to parameter in the Smartmail email function. 

		So, if we have 2 people Bob Admin and Fred Director at bobnfred.com
		List - { "bob@bobnfred.com", "fred@bobnfred.com" }
		String = "Bob Admin" <bob@bobnfred.com>, "Fred Director" <fred@bobnfred.com>
	--]]

	if target == "affected_user" then
		return (is_valid_email(AFF_USR_EMAIL) and formatted_email(AFF_USR_N, AFF_USR_EMAIL)) or nil
	elseif target == "reporting_user" then
		return (is_valid_email(REP_USR_EMAIL) and formatted_email(REP_USR_N, REP_USR_EMAIL)) or nil
	elseif target == "assigned_user" then
		return (is_valid_email(ASS_USR_EMAIL) and formatted_email(ASS_USR_N, ASS_USR_EMAIL)) or nil
	elseif target == "logging_user" then
		return (is_valid_email(LOG_USR_EMAIL) and formatted_email(LOG_USR_N, LOG_USR_EMAIL)) or nil
	elseif target == "actioning_user" then
		return (is_valid_email(ACTIONING_USR_EMAIL) and formatted_email(ACTIONING_USR_N, ACTIONING_USR_EMAIL)) or nil
	elseif target == "actioning_supplier" then
		return (is_valid_email(ACTIONING_SUPP_EMAIL) and formatted_email(ACTIONING_SUPP_N, ACTIONING_SUPP_EMAIL)) or 
			(is_valid_email(ACTION_SUPP_EMAIL2) and formatted_email(ACTIONING_SUPP_N, ACTION_SUPP_EMAIL2)) or nil
	elseif target == "additional_affected_users" then
		return formatted_email_list_from_query(sql)
	else
		-- Catches coding error but not a config script error where somebody specifies an undefined function, e.g. aff_user()
		-- TODO: That function would be just be nil and would never be run. Possible to add more safety here?
		error("Unknown email target '" .. target .. "'. Available targets are '" .. table.concat(standard_targets, "', ") .. "'", 3)
	end
end

function email_list_closure(target_in, sql_in)
	local target = target_in
	local sql = sql_in
	local email_list_and_string = nil
	local built_email_list = false
	return function()
		if not built_email_list then
			LOGGER:debug("Retrieving " .. target .. " email details.")
			email_list_and_string, err = build_email_list_and_string(target, sql)
			built_email_list = true
			if (not email_list_and_string) and (not err) then
				LOGGER:info("Rule Dispatcher email target '" .. target_in .. "'. There is no assyst email address data associated with this target.")
			elseif (not email_list_and_string) and err then
				error("Failure building standard email target '" .. target_in .. "'. Error message: " .. (err or "?"))
			end
		end
		-- Note, this variable is a table with 2 elements: elist (a table of email addresses) and estring (a string of SMTP header-formatted email addresses)
		return email_list_and_string or nil	
	end	
end

-- Standard targets. These are built when the dispatcher in loaded/compiled.
affected_user = email_list_closure("affected_user")
reporting_user = email_list_closure("reporting_user")
logging_user = email_list_closure("logging_user")
assigned_user = email_list_closure("assigned_user")
actioning_user = email_list_closure("actioning_user")
actioning_supplier = email_list_closure("actioning_supplier")

additional_affected_users = email_list_closure(
"additional_affected_users", 		
[[
SELECT     
usr.usr_n "NAME", 
usr.email_add "EMAIL"
FROM 
inc_usr 
INNER JOIN usr ON inc_usr.usr_id = usr.usr_id LEFT OUTER JOIN
assyst_usr ON usr.usr_sc = assyst_usr.assyst_usr_sc
WHERE inc_usr.incident_id = ]] .. EVENT_ID
)
--@+node:eoin.20120316145643.1325: *5* Custom targets
--@@c
--@@language lua

-- Custom targets are built when dispatcher is being run
function custom_target(sqlfile)

	-- This is being executed within a dostring. Therefore it can only report errors by throwing them. 

	-- Set custom target name and email arrays to nil, i.e. wipe clean existing results
	_G["TARGET_NAME"] = nil
	_G["TARGET_EMAIL"] = nil

	local dofile_func, err = loadfile(sqlfile)
	if not dofile_func then
		error("Custom email target sql file'" .. sqlfile .. "' is not valid lua code. " .. (err or ""))
	end
	local ok, err = pcall(dofile_func)
	if not ok then
		error("Custom email target sql file '" .. sqlfile .. "' crashed. " .. (err or ""))
	end

	--[[ 
		Nil TARGET_NAME and TARGET_EMAIL could mean that no results were returned. 
		Don't fail the custom target in this case. 
		Instead, do a TEXT search on the sql string (read from file)
		If 'TARGET_NAME' and 'TARGET_EMAIL' are not found then register an error.
	--]]
	if (not TARGET_NAME) and (not TARGET_EMAIL) then
		local fhandle = assert(io.open(sqlfile, "r"))
		local sqlstring = assert(fhandle:read("*all"))
		fhandle:close()
		if (not sqlstring:find("TARGET_EMAIL")) or (not sqlstring:find("TARGET_NAME")) then
			error("Custom email target SQL '" .. sqlfile .. 
				"' does not the contain TARGET_EMAIL and TARGET_NAME result columns. Please check the SQL.")			
		end
	end
	if TARGET_NAME and (not TARGET_EMAIL) then
		-- Error: we've got a TARGET_NAME result but no TARGET_EMAIL
		error("Custom email target SQL '" .. sqlfile .. 
				"' does not contain the TARGET_EMAIL result column. Please check the SQL.")
	end
	if TARGET_EMAIL and (not TARGET_NAME) then
		-- Error: we've got TARGET_EMAIL result but no TARGET_NAME
		error("Custom email target SQL '" .. sqlfile .. 
				"' does not contain the TARGET_NAME result column. Please check the SQL.")
	end

	if TARGET_NAME then
		if type(TARGET_NAME) == "table" then
			-- Data was generated using multi_row_sql call
			-- COPY (don't point to) data in a db result set structure.
			-- This allows more than one custom target to be specified in an email recipients_special parameter.
			local rs_email = {}
			rs_email.n = TARGET_NAME.n
			rs_email.EMAIL = {}
			rs_email.NAME = {}
			for i=1, TARGET_NAME.n do
				table.insert(rs_email.EMAIL, TARGET_EMAIL[i])
				table.insert(rs_email.NAME, TARGET_NAME[i])
			end

			return formatted_list_from_result_set(rs_email)
		else
			-- Data was generated using sql call. TARGET_NAME is a string.
			return formatted_email(TARGET_NAME, TARGET_EMAIL)
		end
	else
		return nil
	end
end
--@+node:eoin.20120112113540.1319: *4* Activity modifier functions
--@@c

--[[
	============= SECTION: Activity modifier functions ===============
--]]
--@+node:eoin.20111114145357.1301: *5* Define activity disable function
--@@c

function disable(...)
	-- This function is run at config COMPILE time
	-- It returns a function that will be executed when the rules are being stepped through. 
	return function()
		return "disabled"
	end
end
--@+node:eoin.20120112113540.1327: *5* Dealing with conditional activities
--@@c

--@+node:eoin.20120112113540.1317: *6* Define RULE_CONDITIONAL_ACTIVITIES table
--@@c

-- Used in conditional_group_wrapper activity.
-- This must be initialised at the start of every rule.
local RULE_CONDITIONAL_ACTIVITIES = {}
--@+node:eoin.20120112113540.1323: *6* Define CONFIG_ACTIVITY_LABELS table
--@@c

-- Used to store labels detected on conditional activities in currently executing configuration
CONFIG_ACTIVITY_LABELS = {}
--@+node:eoin.20120112113540.1324: *6* Construct conditional label functions on the fly
--@@c

--[[
	Build a constructor that is able to handle the follow pattern

	conditional.label { "email",
		email_params
	}

	Need to trap the key (which models the label) of the conditional
	If key is undefined then
		- create a function
		- store label name in the function
		- store the activity table in the function
		- assign function to the key
	If key is defined then
		- report an error. Labels must be unique in a configuration file.
--]]

conditional_mt = {}
conditional = {}

conditional_mt.__index = function (t,key)
	if CONFIG_ACTIVITY_LABELS[key] then
		error("Conditional label '" .. key .. "' has already been defined. Labels must be unique in a configuration file.", 2)
	else
		-- Record appearance of a label in the config
		CONFIG_ACTIVITY_LABELS[key] = true

		return function(activity_table) 
			return function()
				local label = key 

				if RULE_CONDITIONAL_ACTIVITIES[label] then
					-- This activity should be run
					return "conditional", activity_table
				else
					-- Activity is not switched on
					return "conditional", nil
				end
			end
		end
	end
end

setmetatable(conditional, conditional_mt)
--@+node:eoin.20120112113540.1329: *3* RUNTIME
--@+node:eoin.20111122124139.1308: *4* Define dostring function
--@@c
--@@language lua
-- Define dostring function
function dostring(chunk)
	if type(chunk) ~= "string" then
		return nil, "The parameter has already been evaluated. Are the [[ ]] missing?"
	end

	local func, err = loadstring([[return ]] .. chunk)
	if not func then
		-- Yes, removing 'return' from the chunk error message is a hack
		return nil, "a Lua syntax error was found between the [[ and ]].\n\t\t\t\t" .. string.gsub(err, "return", "")
	end

	-- Propogate rule environment
	setfenv(func, getfenv(1))

	local ok, result_or_err = pcall(func)
	if not ok then
		return nil, "an error occurred when evaluating the specification between [[ and ]].\n\t\t\t\t" .. result_or_err
	end

	return result_or_err
end
--@+node:eoin.20120112113540.1322: *4* Activity modifier controlling function

function check_activity_modifier(activity, log_msg_header, log_msg_header_error, error_level)
	--[[
		This operates on the FUNCTION returned by an activity modifier function.
		Modifier functions _must_ return: 
			flagname, activity_table
		flagname is a string and must not be nil 
		activity_table may be nil
	--]]

	if type(activity) == "function" then
		-- The activity has a modifier.

		local flag, activity_table = activity()

		if flag and (flag == "disabled") then
			LOGGER:info(log_msg_header .. " has been marked as disabled. Skipping...")
			return nil
		elseif flag and (flag == "conditional") then
			if activity_table then
				-- Return the activity table
				LOGGER:info(log_msg_header .. " is conditional and IS enabled. Proceeding..")
				return activity_table
			else
				LOGGER:info(log_msg_header .. " is conditional is NOT enabled. Skipping...")
				return nil
			end
		elseif (not flag) then
			error(log_msg_header_error .. " Bug in Smartmail dispatcher code. The activity modifier is not returning a flag. Contact Axios Service Desk.", error_level)
		else
			error(log_msg_header_error .. " Unknown modifier flag has been placed in front of activity details.", error_level)
		end
	else
		-- The activity does not have a modifier. 
		-- Return it unchanged. 
		return activity
	end
end
--@+node:eoin.20120314125129.1318: *4* Email admin on error
--@@c
--@@language lua


function email_admin(message)
	_G["RD_ERROR_MESSAGE"] = message

	if EMAIL_ADMIN_ON_ERROR then
		email {
			sender     = strServiceDeskEmail,
			recipients = admin_email.email,
			header     = {
				from    = "$strServiceDeskName <$strServiceDeskEmail>",
				to      = (format_name_email_pair({admin_email.name, admin_email.email})).estring,
				subject = "Rule Dispatcher - error during rule validation or execution",
			},
			body       = admin_email.template
		}
	end
end
--@+node:eoin.20120321115117.1337: *3* CONFIG FILE SECTION FUNCTIONS
--@+node:eoin.20111122122413.1313: *4* Run the config "controls", "environment" and "set_of_rules" sections
--@@c
--@@language lua

--[[
	================== SECTION: The "public" functions, i.e. those available to the config ==================
--]]

function controls(args)
	--[[
		Parameters that control how the dispatcher runs are placed here. 
		There is a limited, defined set of such parameters.

		This makes them distinct from the "environment" section below which can have any number of user-defined variables. 

		For safety, the checks on global uniqueness of the controls are still applied. 
	--]]

	if type(args) ~= "table" then
		error("SmartmailRuleDispatcher: the inputs to the controls section must be contained in a key-value table")
	end

	-- By default, test_mode_on is false
	_G.TEST_MODE_ON = false

	-- By default, use_import_processor is false
	_G.USE_IMPORT_PROCESSOR = false

	-- By default, the admin is NOT emailed on error.
	_G.EMAIL_ADMIN_ON_ERROR = false

	-- The available set of controls
	local available_controls = { 
		"test_mode_on", 
		"use_import_processor", 
		"debug_to_outlook", 
		"admin_email", 
		"email_test_filter"
	}
	for k, v in pairs(args) do
		if not element(k, available_controls) then
			error("Unexpected control parameter '" .. k .. "'. The available controls are: " .. table.concat(available_controls, ", ") .. ".")
		end
	end	

	for k, v in pairs(args) do
		-- TODO: Damn my inconsistency.
		if _G[string.upper(k)] then
			error("SmartmailRuleDispatcher control parameter '" .. k .. "' will overwrite an already existing global variable of the same name. This is not permitted.")
		end
		if _G[k] then
			error("SmartmailRuleDispatcher control parameter '" .. k .. "' will overwrite an already existing global variable of the same name. This is not permitted.")
		end

		if k == "test_mode_on" then
			if type(v) ~= "boolean" then
				error("Incorrect test_mode value. Boolean (true|false) expected.")
			end

			if v == true then
				_G.TEST_MODE_ON = true
			end
		end

		if k == "use_import_processor" then
			if type(v) ~= "boolean" then
				error("Incorrect use_import_processor value. Boolean (true|false) expected.")
			end

			if v == true then
				_G.USE_IMPORT_PROCESSOR = true
			end
		end

		if k == "admin_email" then
			if v.ON then
				_G.EMAIL_ADMIN_ON_ERROR = true
				if not v.name then
					error("Rule dispatcher administrator 'name' parameter missing. Please check the configuration file.")
				end
				if not v.email then
					error("Rule dispatcher administrator 'email' parameter missing. Please check the configuration file.")
				end
				if not v.template then
					error("Rule dispatcher administrator 'template' parameter missing. Please check the configuration file.")
				end

				if not is_valid_email(v.email) then
					error("Invalid admin email address information supplied. Please check the configuration file.")
				end
			else
				_G.EMAIL_ADMIN_ON_ERROR = false
			end
		end

		if k == "email_test_filter" then
			if type(v) ~= "table" then
				error("Invalid email_test_filter control. Table expected.")
			end
			if v.ON == nil then
				error("Missing required email_test_filter 'ON' parameter. This must be present and set to either true or false.")
			end
			if type(v.ON) ~= "boolean" then
				error("Invalid email_test_filter 'ON' parameter. Boolean value (true or false) expected.")
			end
			if v.ON then
				-- Get fussy if the email_test_filter is turned ON.
				if not v.allowed then
					error("Missing required email_test_filter 'allowed' parameter. If no email addresses are allowed, specify an empty table: {}")
				end
				if not v.otherwise then
					error("Missing required email_test_filter 'otherwise' parameter.")
				end
				if type(v.allowed) ~= "table" then
					error("Invalid email_test_filter 'allowed' parameter. Table of email addresses expected.  If no email addresses are allowed, specify an empty table: {}")
				end
				if type(v.otherwise) ~= "string" then
					error("Invalid email_test_filter 'otherwise' parameter. Single email address value expected.")
				end
			end
		end

		_G[k] = v
	end
end

function environment(args)
	--[[
		This function loads the specified key-value parameters into the global environment.
		It checks for presence of the "test_mode" parameter and sets the boolean global parameter TEST_MODE_ON accordingly. 

		It also checks if any of the specified parameters are overwriting an existing global
		variable. For now, I consider this to be a fatal error and will stop Smartmail 
		if any overwriting is occurring. 
	--]]

	if not type(args) == "table" then
		error("SmartmailRuleDispatcher: the inputs to the environment section must be contained in a key-value table")
	end

	-- Load the parameters into the global environment.
	for k, v in pairs(args) do
		if _G[k] then
			error("SmartmailRuleDispatcher environment variable '" .. k .. "' will overwrite an existing global variable of the same name. This is not permitted.")
		end

		_G[k] = v
	end
end

function set_of_rules(rule_table)
	--[[
		Step through the rule table.
		Each rule is executed in protected call. The idea is that a rule can fail/crash and not take out the rest of the rule set. 
	--]]

	if type(rule_table) ~= "table" then
		error("set_of_rules function expects to receive a table of rules.")
	end

	for count, rule in ipairs(rule_table) do
		local name_ok, name_or_err = pcall(validate_rule_name, rule.name)
		if not name_ok then
			LOGGER:info(
				"=========== Rule >> " .. ACT_TYPE_SC .. 
				" >> Rule number " .. count .. 
				" for ACT_REG_ID " .. ACT_REG_ID.. " ==========="
			)
			LOGGER:error(
				"Rule >> " .. ACT_TYPE_SC .. " >> Number " .. count .. 
				" for ACT_REG_ID " .. ACT_REG_ID.. 
				". Name failed validation. Is the rule name present and correctly formatted?"
			)
		else
			-- Rule name validated ok. Onwards...
			rule.name = name_or_err

			-- Setup log message header strings
			local log_msg_header = "Rule >> " .. ACT_TYPE_SC .. " >> '" .. rule.name .. "' for ACT_REG_ID " .. ACT_REG_ID 
			local log_msg_header_error = log_msg_header .. " failed with error message: " 
			LOGGER:info("=========== " .. log_msg_header .. " ===========")
			local log_msg_header = "\t" .. log_msg_header
			local log_msg_header_error = "\t" .. log_msg_header_error

			-- Init rule_triggered to false
			local rule_triggered = false
			-- Need a home for the rule.cont_top value (this needs to be structured better)
			local parsed_rule = nil

			-- Validate the structure of the rule and return the "continue|stop" flag value in rule.cont_stop
			local rule_ok, rule_or_err = pcall(validate_rule, rule, log_msg_header, log_msg_header_error)
			if rule_ok then
				-- Assign return value to the parsed_rule
				parsed_rule = rule_or_err

				-- Initialise the environment for the rule
				local rule_env = {}
				setmetatable(rule_env, {__index = _G})
				setfenv(execute_rule, rule_env)

				-- Now execute the rule
				local rule_ok, result_or_err  = pcall(execute_rule, parsed_rule, log_msg_header, log_msg_header_error)
				if rule_ok then
					rule_triggered = result_or_err
				else
					rule_err = result_or_err
					LOGGER:error(rule_err or (log_msg_header .. " failed to complete. Error reason was not provided."))
					email_admin(rule_err or (log_msg_header .. "failed to complete. Error reason was not provided."))
				end	
			else
				LOGGER:error(rule_or_err or (log_msg_header .. "failed validation. Error reason was not provided."))
				email_admin(rule_or_err or (log_msg_header .. "failed validation. Error reason was not provided."))		
			end

			--[[
				Tricky question here.... 
				If a rule fails during execution how should it's "continue|stop" flag be interpreted?
			--]]
			if rule_triggered and parsed_rule.cont_stop == "stop" then
				LOGGER:info(log_msg_header .. " has been triggered and ends with a stop flag. The remaining rules will not be executed.")
				break
			elseif rule_err and parsed_rule.cont_stop == "stop" then
				LOGGER:error(log_msg_header .. " ends with a stop flag and crashed during execution. The remaining rules will not be executed.")
				break
			end
		end
	end	
end
--@+node:eoin.20120111111758.1310: *4* Validation of individual rules
--@@c

--[[
	============= SECTION: Validation of individual rules ===============
--]]

function validate_rule_name(name)
	if (not name) then
		name = ""
		error("Missing mandatory parameter 'name'.", 2)
	end
	-- Parse and evaluate
	name, err = dostring(name)
	if not name then
		error("Parsing of rule name failed " .. err, 2)
	end
	-- Type
	if type(name) ~= "string" then 
		error("Rule name must be a string.", 2) 
	end
	return name	
end

function validate_rule(rule, log_msg_header, log_msg_header_error)
	--[[
		INPUT: Unparsed rule from config file
		OUTPUT: Validated, parsed rule table ready for processing
					table keys have same name, but values are the parsed strings
					cont_stop key added to hold value of the validated "continue|stop" flag
		ERRORS: Thrown!

		Validate the structure of the rule
			Mandatory parameters
				name  (string), 
				condition (string - parsing this to a function here. Not executing function yet.), 
				activities (table) 
				last element of "continue" or "stop" (string, 2 allowed values)
			Test parameters (TEST_MODE_ON)
				As above - but activities_test must be defined in place of activities
			Optional 
				data_generation (table - paths to files)
	--]]


	-- Looking at the mandatory parameters first
	-- RULE NAME is validated and parsed separately.

	-- CONDITION
	-- Presence
	if (not rule.condition) then 
		error(log_msg_header_error .. "Validation error. Missing mandatory parameter 'condition'.", 2) 
	end
	-- Parse. Evaluation is deferred. It is run when the dispatcher is looping through the rules
	if type(rule.condition) ~= "string" then
		error(log_msg_header_error .. "Validation error. Parameter 'condition' has already been evaluated. Are the [[ ]] missing?", 2)
	end
	rule.condition_func, err = loadstring([[return ]] .. rule.condition)
	if not rule.condition_func then
		error(log_msg_header_error .. "Validation error. Parameter 'condition' is not valid lua code. " .. err, 2)
	end

	-- ACTIVITIES
	-- Presence
	if (not rule.activities) then 
		error(log_msg_header_error .. "Validation error. Missing mandatory parameter 'activities'.", 2) 
	end
	-- Type
	if type(rule.activities) ~= "table" then 
		error(log_msg_header_error .. "Validation error. Rule activities must be a table.", 2) 
	end

	-- CONTINUE|STOP flag
	-- Presence and value
	if (not rule[table.getn(rule)] == "continue") and (not rule[table.getn(rule)] == "stop") then
		error(log_msg_header_error .. "Validation error. Missing the 'continue|stop' flag")
	end
	rule.cont_stop = rule[table.getn(rule)]

	-- Looking at mandatory parameter for TEST_MODE_ON
	if TEST_MODE_ON then
		-- Presence
		if not (rule.activities_test) then
			error(log_msg_header_error .. "Validation error. Test mode is ON but the rule does not have an 'activities_test' parameter.", 2)
		end
		-- Type
		if (type(rule.activities_test) ~= "table") then
			error(log_msg_header_error .. "Validation error. Rule activities_test must be a table.", 2)
		end

		-- Test mode ON and validated
		LOGGER:info(log_msg_header .. " . Test mode is ON.")
		-- Repoint activities to activities_test
		rule.activities = rule.activities_test
	end	

	-- Looking at the optional parameters
	if rule.data_generation then
		-- Parse and evaluate
		rule.data_generation, err = dostring(rule.data_generation)
		if not rule.data_generation then
			error(log_msg_header_error .. "Validation error. Parsing of rule data_generation failed. " .. err, 2)
		end
		-- Type test
		if type(rule.data_generation) ~= "table" then
			error(log_msg_header_error .. "Validation error. data_generation parameter must be a table, i.e. a set of paths to files.", 2)
		end
	end

	if rule.parameters then
		-- Parse and evaluate the lua code
		rule.parameters, err = dostring(rule.parameters)
		if not rule.parameters then
			error(log_msg_header_error .. "Validation error. Parsing of rule parameter failed (table expected). Error message: " .. err, 2)
		end
		-- Check type. This prevents a harder-to-explain error with the parsing if it's not a table, i.e. not a valid lua expression.
		if type(rule.parameters) ~= "table" then
			error(log_msg_header_error .. "Validation error. Rule parameters must be a table.", 2)
		end
	end

	return rule
end
--@+node:eoin.20120111111758.1311: *4* Execution of individual rules
--@@c

--[[
	============= SECTION: Execution of individual rules ===============
--]]

function execute_rule(rule, log_msg_header, log_msg_header_error)
	--[[
		INPUT: rule table, parsed at the validation stage
		OUTPUT: true if rule triggered, false otherwise
		ERRORS: This function is wrapped in a pcall. All errors are thrown upwards and dealt with by the calling function.

		1) Execute the data generation dofile(s)
		2) Check for and assemble rule parameters
		3) Execute the supplied and parsed condition
		4) If condition satisfied, then step through the activities array.

		LOGGING
			INFO: Write rule name to log file
			INFO: Write triggering of rule to log file
			DEBUG: Write rule inputs to log file (more difficult to do)			

		TEST MODE 
			As above, but execute the activities_test array - if it exists. 
			If activities_test array does NOT exist, then don't run the rule. Skip it.
	--]]


	--[[ 
		Run data_generation file, if specified.
		Check if the file has not already been run (by another rule). 
		If so, don't run it again. If not, run it and store the filename.
		This is just a shim over Smartmail. All the vars populated by the dofiles are global. 
		Therefore, it's a waste of effort to re-run a dofile. Smartmail itself only runs these
		once. 
	--]]

	if rule.data_generation then
		for _, v in ipairs(rule.data_generation) do
			if not element(v, ruleset_datagen_files) then			
				LOGGER:info(log_msg_header .. ". Running data generation file '" .. v .. "'.")
				local dofile_func, err = loadfile(v)
				if not dofile_func then
					error(log_msg_header_error .. "Data generation file '" .. v .. "' is not valid lua code. " .. (err or ""), 2)
				end
				local ok, err = pcall(dofile_func)
				if not ok then
					error(log_msg_header_error .. "Data generation file '" .. v .. "' crashed. " .. (err or ""), 2)
				end
				table.insert(ruleset_datagen_files, v)
			else
				LOGGER:info(log_msg_header .. ". Data generation file '" .. v .. "' has already been run. Using cached variable values.")
			end
		end
	end

	-- Unpack rule parameters into the environment
	if rule.parameters then
		for k, v in pairs(rule.parameters) do
			fenv = getfenv(1)
			fenv[k] = v
			setfenv(1, fenv)
		end
	end

	-- Evaluate the rule condition
	setfenv(rule.condition_func, getfenv(1))
	local ok, result_or_err = pcall(rule.condition_func)
	if not ok then
		error(log_msg_header_error .. "Error executing the condition. " .. (result_or_err or "") .. ".", 2)
	elseif ok and type(result_or_err) ~= "boolean" then
		error(log_msg_header_error .. "Condition did not return boolean value (true|false). Please check the supplied condition.", 2) 
	else
		if not result_or_err then
			return false
		end
	end

	-- Condition triggered. Run through the activities or activities_test_array
	LOGGER:info(log_msg_header .. " has been triggered. Proceeding with " .. ((TEST_MODE_ON and "test activities.") or "activities."))

	-- Initialise rule conditional activities table (this is a local global)
	RULE_CONDITIONAL_ACTIVITIES = {}

	-- Set error_level for stack trace
	local error_level = 2

	for i, activity in ipairs(rule.activities) do	

		local activity_log_msg_header = log_msg_header .. " >> " .. ((TEST_MODE_ON and "Test Activity") or "Activity") .. " " .. i 
		local activity_log_msg_header_error = activity_log_msg_header .. " failed with message: " 

		--[[
			Check for and evaluate activity modifiers.
			This either returns the activity (modified or unchanged) or nil.
			It's safe to overwrite the activity as it's only used once. 
			(Smartmail executes config on a single pass then terminates).
		--]]
		activity = check_activity_modifier(activity, activity_log_msg_header, activity_log_msg_header_error, error_level+1) 

		if activity then
			-- Invoke the activity function with the specified parameters.
			LOGGER:debug("		Activity ".. i .. " : " .. activity[1]) 
			if element(activity[1], available_activity_types) then
				activity_func = _G[activity[1] .. "_activity"]
				-- Set activity function environment
				setfenv(activity_func, getfenv(1))

				local ok, err = pcall(activity_func, activity_log_msg_header, activity_log_msg_header_error, error_level+2, activity)
				if not ok then error(err, error_level) end
			else
				error(activity_log_msg_header .. ". Unknown activity type: " .. 
						((activity[1] and tostring(activity[1])) or "?"), 2)
			end
		end
	end

	-- Rule was triggered. Return true.
	return true
end
--@+node:eoin.20111116154508.1156: *3* ACTIVITIES HELPER FUNCTIONS
--@@c

--[[
	=============== SECTION: Special functions for activities ====================

	I may put these in a separate file - and gives Sears the means to build up a library of activity helper functions
--]]

--@+others
--@+node:eoin.20120227112726.1327: *4* Export to global - put helper var into global env
--@+at
-- Not intended for customers. It's for people writing the helper functions. 
-- Use at your own peril. Put a variable (defined by param name and value) in the global environment. 
-- This is NOT going to check if an existing global var is being overwritten. 
-- 
-- In general the helper functions are intended to operate on their input and do something outside the dispatcher, 
-- i.e. send an email, log action, write to logger. They either succeed or fail in these operations. 
-- They do not return any values to the dispatcher.
-- 
-- Not a good idea for them, on the fly, to be creating new global variables for use in emails or other activities. 
-- We'll end up with spaghetti-code if this becomes the norm. 
--@@c
--@@language lua

function export_to_global(param, value)
	_G[param] = value
end
--@+node:eoin.20120503175824.1351: *4* Define lookup function - used by the new_action_ejb and new_event_ejb activities

--@+at
-- Using a function to specify an EJB object id lookup from shortcode. 
-- It is called from evaluate_key_value_parameter_rhs
--@@c
--@@language lua
function lookup(args)
	if type(args) ~= "table" then
		error("Incorrect parameters supplied to lookup function. A table of parameters of the form: {EJBObjectName, ShortCodeValue} is expected.")
	end
	if table.getn(args) ~= 2 then
		error("Incorrect parameters supplied to lookup function. A table of parameters of the form: {EJBObjectName, ShortCodeValue} is expected.")
	end

	-- A lookup has been specified.
	local id, err = ASSYSTEJB:lookup_id(args[1], args[2])
	if not id then 
		error("Lookup of " .. args[1] .. " id failed for shortcode '" .. args[2] .. "'. " .. (err or "Unknown error"))
	end
	-- Id value was obtained. Return it. 
	return id
end
--@+node:eoin.20111117103037.1152: *4* Evaluating parameters (key-value tables, arrays and single-value)
--@@c
--@@language lua

local function evaluate_key_value_parameter_rhs(log_msg_header_error, error_level, args)

	-- Propogate rule environment
	setfenv(dostring, getfenv(1))

	local args_out = {}

 	-- Very unwieldy (and incomplete, as RHS could be nested) parse and evaluation of lua chunks on the RHS of parameter names.
	local deferred_params = {}
	for k, v in pairs(args) do
		local err
		-- Don't process indices. I'm only after non-integer key-value pairs
		if not tonumber(k) then			
			if v:find("coalesce_recall") then 
				--[[
					Defer evaluation of this parameter. This is really crude. 
					The only safe way to handle coalesce and coalesce_recall ordering is to not have it inside a string chunk.
					But then, we're back into deferred function territory (see 1st checkin of this code) and problems
					with inconsistent parameter RHS representations. 
				--]]
				deferred_params[k] = v
			end
			args_out[k], err = dostring(v)
			if not args_out[k] and err then
				error(log_msg_header_error .. "\n\t\t\t In parameter '" .. k .. "' " .. err, error_level)
			elseif not args_out[k] and (not err) then
				-- The parameter evaluated to nil. Not necessarily an error
				LOGGER:debug("		Parameter '" .. k .. "' evaluated to nil. This, in itself, is not an error - but it may trigger an error later on.")
			end
		end
	end

	for k, v in pairs(deferred_params) do
		args_out[k], err = dostring(v)
		if not args_out[k] then
			error(log_msg_header_error .. err, error_level)
		end		
	end

	return args_out
end

local function evaluate_array_parameter(log_msg_header_error, error_level, args)

	-- Propogate rule environment
	setfenv(dostring, getfenv(1))

	local args_out ={}

	-- Parse and evaluation of lua chunks in the argument list
	-- Return a normal array, i.e. index starts at 1 and increases monotonically.
	out_index = 0
	for i = 1, table.getn(args) do
		v = args[i]
		if v then
			local param, err
			param, err = dostring(v)
			if not param then
				error(log_msg_header_error .. (err or "Unknown error in dispatcher 'evaluate_array_parameter' function."), error_level)
			end
			out_index = out_index + 1
			args_out[out_index] = param
		end
	end

	return args_out
end

local function evaluate_parameter(log_msg_header_error, error_level, value)

	-- Propogate rule environment
	setfenv(dostring, getfenv(1))

	local value_out, err = dostring(value)
	if not value_out then
		error(log_msg_header_error .. (err or "Unknown error in dispatcher 'evaluate_parameter' function."), error_level)
	end
	return value_out
end



--@+node:eoin.20111117103037.1153: *4* email_activity
--@@c
--@@language lua

local function union_email_data(dataset1, dataset2)
	-- The output set needs to be a deep copy.
	-- If only references are used, then dataSet1 is remembered between activities.
	local union = {}
	local dataset1_has_entries = false
	local dataset2_has_entries = false

	-- Copy email address data
	local v1, v2
	if dataset1.elist then
		dataset1_has_entries = true
		union.elist = union.elist or {}
		for _, v1 in ipairs(dataset1.elist) do
			table.insert(union.elist, v1)
		end
	end
	if dataset2.elist then
		dataset2_has_entries = true
		union.elist = union.elist or {}
		for _, v2 in ipairs(dataset2.elist) do
			table.insert(union.elist, v2)
		end
	end

	-- Copy email string data
	if dataset1_has_entries or dataset2_has_entries then
		local separator = ""
		if (dataset1_has_entries and dataset2_has_entries) then 
			separator = ", "
		end
		union.estring = (dataset1.estring or "") .. separator ..  (dataset2.estring or "")
	end

	-- Copy error data
	local e1, e2
	if dataset1.err then
		union.err = union.err or {}
		for _, e1 in ipairs(dataset1.err) do
			table.insert(union.err, e1)
		end
	end
	if dataset2.err then
		union.err = union.err or {}
		for _, e2 in ipairs(dataset2.err) do
			table.insert(union.err, e2)
		end
	end

	return union
end

function process_recipients_special(recipients_data, formatted_data)
	-- Process a list of lists to generate a list of email addresses and the SMTP header->to string.
	if not recipients_data then
		return nil
	else
		-- Examine input data structure. Does this data need to be consumed straight away or do we need to recurse?
		if recipients_data.elist then
			-- This is output of a target function, i.e. assigned_user(), assigned_svd()
			-- Consume elist and estring data. 
			return recipients_data
		elseif is_name_email_pair(recipients_data) then
			-- It's a name, email pair. Consume it.
			return format_name_email_pair(recipients_data)
		elseif is_email_address(recipients_data) then
			-- It's a single email address. This is not permitted. 
			return nil, recipients_data .. " cannot be used. Only {name, email_address} pairs are allowed."
		elseif (type(recipients_data) == "string") then
			-- Either the original input data is a string or we've recursed into the data to arrive at a 
			-- single string value => no {name, email} pair was found. 
			return nil, "Invalid recipient_special data. The name or email portion of the {name, email} pair is nil."
		else
			-- Recurse
			for i= 1, table.getn(recipients_data) do
				v = recipients_data[i]
				local subset, err = process_recipients_special(v, formatted_data)
				if subset then
					formatted_data = union_email_data(formatted_data, subset)
				elseif (not subset) and err then
					formatted_data = union_email_data(formatted_data, { ["err"] = {err} })
				else
					-- No change to formatted data
				end
			end
		end
	end
	return formatted_data
end

function email_activity(log_msg_header, log_msg_header_error, error_level, args)
	--[[
		A wrapper about the standard smartmail email function. 
			- Allows specification of emails in a parameterised fashion (instead of having to do so as a dostring(lua chunk))
			- It leverages the defaults supplied in the AGS BaseConfig.lua file.
			- Can use the recipients_special field that is populated using the target functions.

		The idea is to allow the user to go with the full specification of the 
		email as defined in the Smartmail manual OR to shortcut the full definition by making use of known defaults
		and helper functions.
	--]]

	-- Propogate the rule environment
	setfenv(evaluate_key_value_parameter_rhs, getfenv(1))

	-- Evaluate the right hand side of each of parameters
	args = evaluate_key_value_parameter_rhs(log_msg_header_error, error_level+1, args)

	-- Now, taking the evaluated parameters (or defaults) and invoking the email function
	args.sender		= args.sender or strServiceDeskEmail
	args.header		= args.header or {}
	args.header.from 	= args.header.from or "$strServiceDeskName <$strServiceDeskEmail>"

	--------------------------------------------------------------------------------
	-- Ugly piece of code. Handling the to and cc specifications.
	-- The Lua SMTP email function uses single list to specify all recipients
	-- The header to and cc strings are used to partition the recipients as desired
	--------------------------------------------------------------------------------
	local to_recipients
	if args.recipients_special then
		to_recipients = process_recipients_special(args.recipients_special, {})
		if to_recipients.err then
			LOGGER:error("Errors found when building email to list: " .. table.concat(to_recipients.err))
		end
		if to_recipients.elist and (table.getn(to_recipients.elist) == 0) then 
			to_recipients = nil 
		elseif (not to_recipients.elist) then
			to_recipients = nil
		end
	end

	local cc_recipients
	if args.cc_special then
		cc_recipients = process_recipients_special(args.cc_special, {})
		if cc_recipients.err then
			LOGGER:error("Errors found when building email cc list: " .. table.concat(cc_recipients.err))
		end
		if cc_recipients.elist and (table.getn(cc_recipients.elist) == 0) then 
			cc_recipients = nil 
		elseif (not cc_recipients.elist) then
			cc_recipients = nil
		end
	end

	local all_recipients
	if to_recipients and cc_recipients then
		all_recipients = to_recipients.elist
		for _, v in ipairs(cc_recipients.elist) do
			table.insert(all_recipients, v)
		end
	elseif to_recipients and (not cc_recipients) then
		all_recipients = to_recipients.elist
	elseif (not to_recipients) and cc_recipients then
		all_recipients = cc_recipients.elist
	end

	args.recipients 		= args.recipients or all_recipients
	args.header.subject 	= args.header.subject or args.subject
	args.header.to      	= args.header.to or (to_recipients and to_recipients.estring)
	args.header.cc 		= args.header.cc or (cc_recipients and cc_recipients.estring)
	args.body 			= args.body

	if not args.recipients then
		LOGGER:warn(log_msg_header_error .. "No email addresses have been supplied. Do the specified recipients have address data in assyst?")
	else
		-- Handle template_parameters
		if args.template_parameters then
			for k, v in pairs(args.template_parameters) do
				if _G[k] then
					-- Guard against STOMPING on existing global vars
					error(log_msg_header_error .. "Email template parameter '" .. k .. 
						"' already exists as a global variable. Please rename it here and in the template file.", error_level)
				else
					_G[k] = v
				end
			end
		end

		LOGGER:info("Email arguments: " .. stringify(args))
		-- Propogation of rule environment not needed here. The args must be already evaluated before calling email
		local ok, err = pcall(email, args)

		-- Remove template parameters from global environment. This is really ugly...
		if args.template_parameters then
			for k, v in pairs(args.template_parameters) do
				_G[k] = nil
			end
		end	

		-- Handle errors thrown by email call.
		if not ok then
			error(log_msg_header_error .. (err or "Unknown error"), error_level)
		end
	end
end
--@+node:eoin.20111117103037.1154: *4* log_activity
--@@c

function log_activity(log_msg_header, log_msg_header_error, error_level, args)
	--[[
		Writes INFO messages to Smartmail log file

		args is a string or table of strings
		For the table - output a header line followed by an indented set of messages for each entry in the table.
	--]]

	if table.getn(args) < 2   then
		error(log_msg_header .. " has no usable inputs.", error_level)
	end

	-- Propogate rule environment
	setfenv(evaluate_parameter, getfenv(1))

	for i = 1, table.getn(args) do
		if type(i) == "number" and i > 1 then
			local value = evaluate_parameter(log_msg_header_error, error_level+1, args[i])
			if value and type(value) ~= "string" then LOGGER:info("\t\t" .. stringify(value)) end
			if value then LOGGER:info("\t\t" .. value) end
		end
	end
end
--@+node:eoin.20111117103037.1155: *4* script_activity
--@@c

function script_activity(log_msg_header, log_msg_header_error, error_level, args)
	--[[
		Just execute the lua script in the chunk
	--]]

	if not args[2] then 
		error(log_msg_header_error .. "  No script available to execute.", error_level) 
	end 

	local func, err = loadstring(args[2])
	if not func then
		error(log_msg_header_error .. " Failure parsing script section. " .. (err or "?"), error_level)
	end

	-- Propogate rule environment
	setfenv(func, getfenv(1))
	local ok, err = pcall(func)
	if not ok then
		error(log_msg_header_error .. "Failure running script section. " .. (err or "?"), error_level)
	end
end
--@+node:eoin.20111117103037.1156: *4* new_action and update_event activities - for acli and import processor
--@@c

function new_action_activity(log_msg_header, log_msg_header_error, error_level, args)
	if USE_IMPORT_PROCESSOR then
		-- Propogate rule environment
		setfenv(import_processor_file_writer, getfenv(1))
		import_processor_file_writer(log_msg_header, log_msg_header_error, error_level+1, "new_action", args)
	else
		-- Propogate rule environment
		setfenv(run_acli, getfenv(1))
		run_acli(log_msg_header, log_msg_header_error, error_level+1, "new_action", args)
	end
end

function update_event_activity(log_msg_header, log_msg_header_error, error_level, args)
	if USE_IMPORT_PROCESSOR then
		-- Propogate rule environment
		setfenv(import_processor_file_writer, getfenv(1))
		import_processor_file_writer(log_msg_header, log_msg_header_error, error_level+1, "update_event", args)
	else
		-- Propogate rule environment
		setfenv(run_acli, getfenv(1))
		run_acli(log_msg_header, log_msg_header_error, error_level+1, "update_event", args)
	end
end

function import_processor_file_writer(log_msg_header, log_msg_header_error, error_level, action, args)

	-- Escape backslashes, CR and NL in string.
	local escape = function(s)
		ss = tostring(s)
		if ss then
			ss = ss or ""
			ss = ss:gsub("\\", "\\\\")
			ss = ss:gsub("\r\n", "\n")
			ss = ss:gsub("\n", "\\n")
			return ss
		else
			return s
		end
	end

	-- Propogate rule environment before evaluating params
	setfenv(evaluate_key_value_parameter_rhs, getfenv(1))
   	args = evaluate_key_value_parameter_rhs(log_msg_header_error, error_level+1, args)

	-- Validation of the filename argument
	if not args.filename then
		error(log_msg_header_error .. " Import filename not specified.", error_level)
	end
	local fhandle, err = io.open(args.filename, "w")
	if not fhandle then
		error(log_msg_header_error .. " Failure opening import file. " .. (err or "?"), error_level)
	end

	--[[ 
		Imposing some ordering on the output file: 
			INCIDENTREF followed by EVENTIMPPROFILE followed by ACTIONIMPPROFILE
			Anything except description
			DESCRIPTION
	--]]
	if args.INCIDENTREF then
		fhandle:write("@*@INCIDENTREF@*@:" .. escape(args.INCIDENTREF) .. "\n")
	end
	if args.EVENTIMPPROFILE then
		fhandle:write("@*@EVENTIMPPROFILE@*@:" .. escape(args.EVENTIMPPROFILE) .. "\n")
	end
	if args.ACTIONIMPPROFILE then
		fhandle:write("@*@ACTIONIMPPROFILE@*@:" .. escape(args.ACTIONIMPPROFILE) .. "\n")
	end
	for k, v in pairs(args) do
		if k ~= 1 and k ~= "acli" and  k ~= "filename" and k ~= "INCIDENTREF" and k ~= "EVENTIMPPROFILE" and k ~= "ACTIONIMPPROFILE" and k ~= "DESCRIPTION" then
			fhandle:write("@*@" .. k .. "@*@:" .. (escape(v) or "") .. "\n")
		end
	end
	if args.DESCRIPTION then
		fhandle:write(escape(args.DESCRIPTION) .. "\n")
	end

	if action == "new_action" then
		fhandle:write("|END OF ACTION|\n")
	elseif action == "update_event" then
		fhandle:write("|END OF EVENT UPDATE|\n")
	else
		error(log_msg_header_error .. " Undefined activity '" .. action .. "'", error_level)
	end
end

function run_acli(log_msg_header, log_msg_header_error, error_level, action, args)
	--  Light wrapper about the acli action and event logging

	-- Evaluate the right hand side of each of parameter
	-- Propogate rule environment before evaluating params
	setfenv(evaluate_key_value_parameter_rhs, getfenv(1))
	args = evaluate_key_value_parameter_rhs(log_msg_header_error, error_level+1, args)

	-- Now create ASSYST object (if it doesn't exist)
	ASSYST.acli = args["acli"]
	LOGGER:info(stringify(ASSYST.acli))

	-- Remove parameters that are going to cause offence if written to the acli import file
	args["filename"] = nil
	args["acli"] = nil

	if action == "new_action" then
		local ok, err = ASSYST:new_action(args)
		if not ok then error(log_msg_header_error .. (err or "Unknown error"), error_level) end 
	elseif action == "update_action" then
		local ok, err = ASSYST:update_action(args)
		if not ok then error(log_msg_header_error .. (err or "Unknown error"), error_level) end 
	elseif action == "new_event" then
		local ok, err = ASSYST:new_event(args)
		if not ok then error(log_msg_header_error .. (err or "Unknown error"), error_level) end 
	elseif action == "update_event" then
		local ok, err = ASSYST:update_event(args)
		if not ok then error(log_msg_header_error .. (err or "Unknown error"), error_level) end 
	else
		error("Undefined actvity '" .. action .. "'", error_level)
	end
end

--@+node:eoin.20120323152003.1346: *4* new_action activity for ejb API
--@@c
--@@language lua

function new_action_ejb_activity(log_msg_header, log_msg_header_error, error_level, args)
	-- Evaluate the right hand side of each of parameter
	-- Propogate rule environment before evaluating params
	setfenv(evaluate_key_value_parameter_rhs, getfenv(1))
	args = evaluate_key_value_parameter_rhs(log_msg_header_error, error_level+1, args)

	-- Check for the assyst event id
	if not args.eventId then
		error(log_msg_header_error .. "Missing or nil eventId parameter on ejb new_action.", error_level)
	end

	-- Log the update via the EJB api			
	args.useEJB = nil
	local ok, err = ASSYSTEJB:new_action(args)
	if not ok then
		error(log_msg_header_error .. "Failed to add new action to event " .. args.eventId .. " via assyst EJB api. " .. (err or "Unknown error")) 
	end	
end
--@+node:eoin.20120109104919.1306: *4* update_event activity for ejb API - behaviour different to acli and IP so keep separate
--@@c
--@@language lua

function update_event_ejb_activity(log_msg_header, log_msg_header_error, error_level, args)
	-- Evaluate the right hand side of each of parameter
	-- Propogate rule environment before evaluating params
	setfenv(evaluate_key_value_parameter_rhs, getfenv(1))
	args = evaluate_key_value_parameter_rhs(log_msg_header_error, error_level+1, args)

	-- Check for the assyst event id
	if not args.eventId then
		error(log_msg_header_error .. "Missing or nil eventId parameter on ejb update_event.", error_level)
	end

	-- Log the update via the EJB api			
	local eventId = args.eventId
	args.eventId = nil
	args.useEJB = nil
	local ok, err = ASSYSTEJB:update_event(eventId, args)
	if not ok then
		error(log_msg_header_error .. "Failed to update event id " .. eventId .. " via assyst EJB api. " .. (err or "Unknown error")) 
	end
end

--@+node:eoin.20120111111758.1313: *4* conditional_group_activity
--@@c

function conditional_group_activity(log_msg_header, log_msg_header_error, error_level, args)

	-- Validate the structure of the condition args: { "conditional_group", [[ condition string ]], { list of activity labels } }
	-- 1st element (conditional_group) has already been validated (otherwise we wouldn't be executing this code). 
	if not args[2] then
		error(log_msg_header_error .. "Validation error. The 'conditional_group' activity type must be followed by a condition string and table of activity labels", error_level)
	end
	if args[2] and type(args[2]) ~= "string" then
		error(log_msg_header_error .. "2nd element in 'conditional_group' activity must be a string.", error_level)
	end
	if args[3] and type(args[3]) ~= "table" then
		error(log_msg_header_error .. "3rd element in 'conditional_group' activity must be a table.", error_level)
	end
	for _, v in ipairs(args[3]) do
		if type(v) ~= "string" then
			error(log_msg_header_error .. "The activity label '" .. stringify(v) .. "' is not a string.", error_level)
		end
	end

	-- Parse the condition string
	local condition_func, err = loadstring([[return ]] .. args[2])
	if not condition_func then
		error(log_msg_header_error .. "Validation error. The condition is not valid lua code. " .. err, error_level)
	end

	-- Cross-check activity labels against activity types. 
	-- Labels _cannot_ be activity type names.
	for _, v in ipairs(args[3]) do
		if element(v, available_activity_types) then
			error(log_msg_header_error .. 
					"Validation error. A conditional_group activity label has been set to an activity type name (one of '" .. 
					table.concat(available_activity_types, "', '") .. "'). This is not permitted.", 
				error_level)
		end
	end

	-- Evaluate the condition
	-- Propogate rule environment
	setfenv(condition_func, getfenv(1))
	local ok, result_or_err = pcall(condition_func)
	if not ok then
		error(log_msg_header_error .. "Error executing the condition. " .. (result_or_err or "") .. ".", error_level)
	elseif ok and type(result_or_err) ~= "boolean" then
		error(log_msg_header_error .. "Condition did not return boolean value (true|false). Please check the supplied conditional_group.", error_level) 
	end

	LOGGER:debug("conditional_group: " .. stringify(args))
	LOGGER:debug("conditional_group condition string: " .. args[2])
	if result_or_err then
		LOGGER:debug("conditional_group outcome: ON")
	else
		LOGGER:debug("conditional_group outcome: OFF")
	end

	if result_or_err then
		-- Switch on the labelled activities
		for _, v in ipairs(args[3]) do
			-- Make the label a key in the table. Easier to look up. 
			LOGGER:debug("Turning on conditional activity '" .. v .. "'")
			RULE_CONDITIONAL_ACTIVITIES[v] = true
		end
	end
end
--@+node:eoin.20120112113540.1332: *4* survey_request_activity
--@@c
--@@language lua

function survey_request_activity(log_msg_header, log_msg_header_error, error_level, args)

	-- Evaluate the right hand side of each of parameters
	args = evaluate_key_value_parameter_rhs(log_msg_header_error, error_level+1, args)

	if not args.SURVEY_DEF_SC then
		error(log_msg_header_error .. " Missing required SURVEY_DEF_SC parameter.", error_level)
	end

	if type(args.SURVEY_DEF_SC) ~= "string" then
		error(log_msg_header_error .. " Invalid SURVEY_DEF_SC parameter. String expected.", error_level)
	end

	-- update surv_reg_hk table first, if successful create row in surv_req table
	HKSQL, err = ASSYST:sql([[update surv_req_hk set value = (select max(surv_req_id) + 1 from surv_req)]])
	if not err then
		-- Get Surv_req_id
		SQL1 = [[ select value "SURV_REQ_ID" from surv_req_hk ]]
		HKSQL, err = ASSYST:sql(SQL1)
		if not err then
			SURV_REQ_ID = HKSQL.SURV_REQ_ID

			-- Get Survey Definition ID
			SQL1 = [[
					select surv_def_id "SURV_DEF_ID" from surv_def where surv_def_sc = ']] .. args.SURVEY_DEF_SC .. [['
				]]
			LOGGER:debug(SQL1)	
			SURV_DEF, err = assert(ASSYST:sql(SQL1))
			if (not err) and ((SURV_DEF.SURV_DEF_ID or "") ~= "")  then				
				-- Get Contact User SC
				SQL1 = [[
					select usr_id "AFF_USR_ID" from usr where usr_sc = ']] .. AFF_USR_SC .. [['
					]]
				LOGGER:debug(SQL1)	
				AFF_USER, err = assert(ASSYST:sql(SQL1))
				if not err then
					SQL1 = [[
						insert into surv_req (
						  surv_req_id, stat_flag, modify_id, modify_date, version, 
						  surv_def_id, usr_id, resp_date, resp_type, response_1,
						  response_2, response_3, response_4, response_5,
						  comments,  incident_id,  act_reg_id,  issued_date,  issue_type)
						values (
						  ]] .. SURV_REQ_ID .. [[, 
						  'n',  'AUTO SURVEY',  ]] .. DATESTR .. [[,  1,  ]] .. SURV_DEF.SURV_DEF_ID .. [[, 
						  ]] .. AFF_USER.AFF_USR_ID .. [[,
						  null,  'g',  0,  0,  0,  0,  0,  null, ]] .. EVENT_ID .. [[,  ]]
						  .. ACT_REG_ID .. [[, ]] .. DATESTR .. [[,  'c')
						]]
					LOGGER:debug(SQL1)	
					SURV_REQ_U_SQL, err = assert(ASSYST:sql(SQL1))
					-- if survey req update is successfull, get the id 
					if not err then
						SQL2 = [[select surv_req_id "SURV_REQ_ID" from surv_req where incident_id = ]] .. EVENT_ID .. [[ order by surv_req_id desc]]
						LOGGER:debug(SQL2)
						SQL, err = assert(ASSYST:sql(SQL2))
						if not err then
							-- value returned in SURV_REQ_ID
							EMAIL_SURVEY_URL_EN = [[<a href="]] .. strSurveyLink .. SURV_REQ_ID .. [[">Complete Survey</a>]]
							EMAIL_SURVEY_URL_FR = [[<a href="]] .. strSurveyLink .. SURV_REQ_ID .. [[">cliquer ici</a>]]
							export_to_global("EMAIL_SURVEY_URL_EN", EMAIL_SURVEY_URL_EN)
							export_to_global("EMAIL_SURVEY_URL_FR", EMAIL_SURVEY_URL_FR)
						else
							SURV_REQ_ID = 0
							LOGGER:error("Unable to register survey: " .. args.SURVEY_DEF_SC .. ",  Survey bypased.  Error: " .. (err or "?") .. ", SQL: " .. (SQL1 or ""))
						end
					end
				else
					SURV_REQ_ID = 0
					LOGGER:error("Unable to register survey: " .. args.SURVEY_DEF_SC .. ",  Survey bypased.  Error: " .. (err or "?") .. ", SQL: " .. (SQL1 or ""))
				end
			else
				if err then
					SURV_REQ_ID = 0
					LOGGER:error("Unable to register survey: " .. args.SURVEY_DEF_SC .. ",  Survey bypased.  Error: " .. (err or "??") .. ", SQL: " .. (SQL1 or ""))
				else
					SURV_REQ_ID = 0
					LOGGER:error("Unable to register survey: " .. args.SURVEY_DEF_SC .. ",  Survey not found.")
				end
			end
		else
			SURV_REQ_ID = 0
			LOGGER:error("Unable to register survey: " .. args.SURVEY_DEF_SC .. ",  Survey bypased.  Error: " .. (err or "??") .. ", SQL: " .. (SQL1 or ""))
		end
	else 
		SURV_REQ_ID = 0
		LOGGER:error("Unable to register survey: " .. args.SURVEY_DEF_SC .. ",  Survey bypased.  Error: " .. (err or "??"))
	end
end
--@+node:eoin.20120221124407.1329: *4* survey_request_activity_oracle
--@@c

function survey_request_activity_oracle(log_msg_header, log_msg_header_error, error_level, args)

	-- Evaluate the right hand side of each of parameters
	-- Propogate rule environment before evaluating params
	setfenv(evaluate_key_value_parameter_rhs, getfenv(1))
	args = evaluate_key_value_parameter_rhs(log_msg_header_error, error_level+1, args)

	if not args.SURVEY_REQUEST_SC then
		error(log_msg_header_error .. " Missing required SURVEY_REQUEST_SC parameter.", error_level)
	end

	if type(args.SURVEY_REQUEST_SC) ~= "string" then
		error(log_msg_header_error .. " Invalid SURVEY_REQUEST_SC parameter. String expected.", error_level)
	end

	local ok, err = ASSYST:sql([[update surv_req_hk set value = (select max(surv_req_id) + 1 from surv_req)]])
	if err then
		error(log_msg_header_error .. " Failure to update the hk on the surv_req table. " .. (err or "?"), error_level)
	end

	local sql_insert_survey = 
		[[insert into surv_req (
			surv_req_id, 
			stat_flag, 
			modify_id, 
			modify_date, 
			version, 
			surv_def_id, 
			usr_id, 
			resp_date, 
			resp_type, 
			response_1,
			response_2, 
			response_3, 
			response_4, 
			response_5,
			comments,
			incident_id,
			act_reg_id,
			issued_date,
			issue_type
		)
		values (
			(select value from surv_req_hk), 
			'n',  
			'AUTO SURVEY',  
			SYSDATE,  
			1,  
			(select surv_def_id from surv_def where surv_def_sc = ']] .. args.SURVEY_REQUEST_SC .. [['), 
			(select usr_id from usr where usr_sc = ']] .. AFF_USR_SC .. [['),
			null,  
			'g',  
			0,  
			0,  
			0,  
			0,  
			0,  
			null, ]] .. EVENT_REF .. [[,  ]]
			.. ACT_REG_ID .. [[, SYSDATE,  'c'
		)
	]]

	local rs_insert_survey, err = ASSYST:sql(sql_insert_survey)	
	if err then
		error(log_msg_header_error .. " Failure to insert survey request. " .. (err or "?"), error_level)
	end
end
--@-others
--@-others
--@-leo
