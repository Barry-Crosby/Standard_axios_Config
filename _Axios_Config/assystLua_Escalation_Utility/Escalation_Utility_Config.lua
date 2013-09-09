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

strUtilityName = "Escalation_Utility"
BypassLoggingEnvironment = "y"

LOG_LEVEL = "INFO"		-- Must be one of "ERROR", "WARN", "INFO", "DEBUG". Defaults to INFO if omitted

ESC_CNTR = 10	-- Can be set lower to make this more efficient if you now the level of escalations being performed

-- Actions to take on the event when escalated at each escalation level. Th actions must be valid Actions in assyst.
-- DO NOT EDIT the first column 'ESCx', only change the action that will be taken at that esclation level. 
-- If you only need 4 escalations, you only need to define actions for ESC1, ESC2, ESC3, and ESC4. All others (ESC5-ESC10) will be ignored.

ESC_ACTION = {	ESC1 = "ESC1 REACHED",
				ESC2 = "ESC2 REACHED",
				ESC3 = "ESC3 REACHED",
				ESC4 = "ESC4 REACHED",
				ESC5 = "ESC5 REACHED",
				ESC6 = "ESC6 REACHED",
				ESC7 = "ESC7 REACHED",
				ESC8 = "ESC8 REACHED",
				ESC9 = "ESC9 REACHED",
				ESC10 = "ESC10 REACHED",
}

strBASE_FOLDER = "\\_Axios_Config\\"
dofile(strBASE_FOLDER .. "Common\\BaseConfig.lua")  						-- load Lua environment variables
dofile(strBASE_FOLDER .. "Common\\BaseConfigEJB.lua")  					-- load EJB environment and functions
dofile(strBASE_FOLDER .. "common\\Functions\\Axios_Logging_Utility.lua")				-- Load logging utilities
dofile(strBASE_FOLDER .. "common\\Functions\\functions.lua")             			   	-- load ACLI import functions
dofile(strBASE_FOLDER .. "assystLua_" .. strUtilityName .. "\\" .. strUtilityName .. ".lua")		-- run logic file
