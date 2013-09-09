--------------------------------------------------------------------------------------
-- Archive_Utility_Config.lua
-- Prepared for AGS SmartMail Quick Config (Version 3.0)
--
-- This script is not supported by Axios Systems. The script is provided as is and Axios Systems
-- accepts no responsibility or liability for the consequences of using this script.
--
--
--------------------------------------------------------------------------------------
LOG_LEVEL = "INFO"		-- Must be one of "ERROR", "WARN", "INFO", "DEBUG". Defaults to INFO if omitted

-- How many days to keep ACLI import and error files 
-- Files older than this value are removed.

ARCHIVEDAYS = 30
strArchivePath = "\\_Axios_Config\\aim\\"			-- Must include ending \\

strUtilityName = "Archive_Utility"
BypassLoggingEnvironment = "y"

--------------------------------------------------------------------------------------
--
-- set up environemnt
--
--------------------------------------------------------------------------------------
-----  Execute logic and global files ------
strBASE_FOLDER = "\\_Axios_Config\\"
dofile(strBASE_FOLDER .. "Common\\BaseConfig.lua")             			   	-- load Lua environment variables
dofile(strBASE_FOLDER .. "common\\Functions\\Axios_Logging_Utility.lua")				-- Load logging utilities
dofile(strBASE_FOLDER .. "common\\Functions\\functions.lua")             			   	-- load ACLI import functions
dofile(strBASE_FOLDER .. "assystLua_" .. strUtilityName .. "\\" .. strUtilityName .. ".lua")				   	-- run logic file
