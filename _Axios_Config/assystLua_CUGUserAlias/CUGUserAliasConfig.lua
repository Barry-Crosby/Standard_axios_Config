-- CUGConfig.lua
------------------
LOG_LEVEL = "INFO"		-- Must be one of "ERROR", "WARN", "INFO", "DEBUG". Defaults to INFO if omitted

strUtilityName = "CUGUserAlias"
BypassLoggingEnvironment = "y"
WARNINGS_ENCOUNTERED = false

-- assyst User that was default alias during CUG execution
-- This will also be the user that will be copied to the new ZZ-User
	DEFAULT_ALIAS = "ZANET"

-- Set VIP Criteria
-- Set to empty string to bypass VIP logic
SQL_VIP_ALERTS_TO_ADD = [[			
	SELECT usr_sc USR_SC
		FROM usr
		WHERE usr_rmk like('%VICE PRESIDENT%')
			AND usr_id not in (SELECT incspc_item FROM incspc WHERE incspc_type = 50)
]]
SQL_VIP_ALERTS_TO_ADD = "" -- bypass for now
VIP_ALERT_TEXT = "VIP -- please use extra care"
	
strBASE_FOLDER = "\\_Axios_Config\\"
dofile(strBASE_FOLDER .. "Common\\BaseConfig.lua")  						-- load Lua environment variables
dofile(strBASE_FOLDER .. "common\\Functions\\Axios_Logging_Utility.lua")				-- Load logging utilities
dofile(strBASE_FOLDER .. "Common\\BaseConfigDB.lua")  						-- load DB environment and functions
dofile(strBASE_FOLDER .. "common\\Functions\\functions.lua")             			   	-- load ACLI import functions

AIM_FOLDER = strBASE_FOLDER .. "AIM\\"
ARCHIVE_FOLDER = AIM_FOLDER .. "Archive\\"

SCRIPT_PATH = strBASE_FOLDER .. "assystLua_" .. strUtilityName .. "\\"

dofile(strBASE_FOLDER .. "assystLua_" .. strUtilityName .. "\\" .. strUtilityName .. ".lua")		-- run logic file

-- This will trigger an email to the technical administrator
if WARNINGS_ENCOUNTERED then
	LOGGER:error("One or more warnings were detected during processing that should be reviewed")
end