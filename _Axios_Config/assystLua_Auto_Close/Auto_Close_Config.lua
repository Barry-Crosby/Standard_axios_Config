--------------------------------------------------------------------------------------
-- Auto_Close_Config.lua
-- Prepared for AGS SmartMail Quick Config (Version 5.0)
--
-- This script is not supported by Axios Systems. The script is provided as is and Axios Systems
-- accepts no responsibility or liability for the consequences of using this script.
--
-- Uses the assystEJB for taking CLOSURE action
--
--------------------------------------------------------------------------------------

strUtilityName = "Auto_Close"
BypassLoggingEnvironment = "y"

LOG_LEVEL = "INFO"							-- Must be one of "ERROR", "WARN", "INFO", "DEBUG". Defaults to INFO if omitted

CLOSE_DAYS = 3								-- number of days after an event in Close Pending state is Closed
CLOSE_BY_USER = "SERVICE-DESK"							-- Set to value of user to record close against or blank for user who took Resolve Action
CLOSE_BY_SVD = "SERVICE DESK"							-- Set to value of user to record close against or blank for SVD that took Resolve Action
ACTION_IMPORT_PROFILE = "GENERAL ACTION"   	-- Action Import Profile to use for all Auto Closures
CLOSE_LIMIT = " top 5 "						-- use to limit the number of closures per run

-- Remark to put in the Closure action remark
CLOSE_REMARK = "Auto Closed after " .. CLOSE_DAYS .. " days."

strBASE_FOLDER = "\\_Axios_Config\\"
dofile(strBASE_FOLDER .. "Common\\BaseConfig.lua")  						-- load Lua environment variables
dofile(strBASE_FOLDER .. "Common\\BaseConfigEJB.lua")  					-- load EJB environment and functions
dofile(strBASE_FOLDER .. "common\\Functions\\Axios_Logging_Utility.lua")				-- Load logging utilities
dofile(strBASE_FOLDER .. "common\\Functions\\functions.lua")             			   	-- load ACLI import functions
dofile(strBASE_FOLDER .. "assystLua_" .. strUtilityName .. "\\" .. strUtilityName .. ".lua")		-- run logic file


