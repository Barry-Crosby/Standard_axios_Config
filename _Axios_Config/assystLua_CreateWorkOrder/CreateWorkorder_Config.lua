--------------------------------------------------------------------------------------
-- Escalations_Utility_Config.lua
-- Prepared for AGS FB Quick Config (Version 3.0)
--
-- This script is not supported by Axios Systems. The script is provided as is and Axios Systems
-- accepts no responsibility or liability for the consequences of using this script.
--
--------------------------------------------------------------------------------------
-- Change log
-- 04/26/2012	Initial version of file
--------------------------------------------------------------------------------------

strUtilityName = "CreateWorkorder"
BypassLoggingEnvironment = "y"

LOG_LEVEL = "DEBUG"		-- Must be one of "ERROR", "WARN", "INFO", "DEBUG". Defaults to INFO if omitted

--The link reason that will be used to link the calls
local link_reason_sc = "WORKORDER"

--Category that linked events should get
local linked_call_category = "WORKORDER"

strBASE_FOLDER = "\\_Axios_Config\\"
dofile(strBASE_FOLDER .. "Common\\BaseConfig.lua")  						-- load Lua environment variables
dofile(strBASE_FOLDER .. "Common\\BaseConfigEJB.lua")  					-- load EJB environment and functions
dofile(strBASE_FOLDER .. "common\\Functions\\Axios_Logging_Utility.lua")				-- Load logging utilities
dofile(strBASE_FOLDER .. "common\\Functions\\functions.lua")             			   	-- load ACLI import functions
dofile(strBASE_FOLDER .. "assystLua_" .. strUtilityName .. "\\" .. strUtilityName .. ".lua")		-- run logic file
