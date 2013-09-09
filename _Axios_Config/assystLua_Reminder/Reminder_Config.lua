--------------------------------------------------------------------------------------
-- Reminder_Config.lua
-- Prepared for AGS aLua 3.6 Scripting
--
-- This script is not supported by Axios Systems. The script is provided as is and Axios Systems
-- accepts no responsibility or liability for the consequences of using this script.
--
-- Uses the assystEJB for taking Reminder action
--
--------------------------------------------------------------------------------------

strUtilityName = "Reminder"
BypassLoggingEnvironment = "y"

-- ************ USER CONFIGURABLE PARAMETERS BELOW ******************
LOG_LEVEL = "INFO"																-- Must be one of "ERROR", "WARN", "INFO", "DEBUG". Defaults to INFO if omitted
REMINDER_DAYS = 2																-- days to wait before taking reminder action
MANAGER_REMINDER_DAYS = 3														-- days to wait before taking manager reminder action (0 - never action)
REMINDER_MAJOR_CATEGORY1 = "FAULTS"												-- Specify up to 5 major categories to take reminders on. 
REMINDER_MAJOR_CATEGORY2 = "INQUIRY"
REMINDER_MAJOR_CATEGORY3 = ""
REMINDER_MAJOR_CATEGORY4 = ""
REMINDER_MAJOR_CATEGORY5 = ""
ACTION_IMPORT_PROFILE = "ANET"
REMINDER_ACTION_SC = "REMINDR TO ACTN"												-- Specify reminder action that will be run against returned records for notification.
M_REMINDER_ACTION_SC = "MANAGR REMINDER"											-- Specify reminder action that will be run against returned records for manager notification.
-- ************** END OF USER CONFIGURABLE PARAMETERS********************

strBASE_FOLDER = "\\_Axios_Config\\"
dofile(strBASE_FOLDER .. "Common\\BaseConfig.lua")  								-- load Lua environment variables
dofile(strBASE_FOLDER .. "Common\\BaseConfigEJB.lua")  							-- load EJB environment and functions
dofile(strBASE_FOLDER .. "common\\Functions\\Axios_Logging_Utility.lua")		-- Load logging utilities
dofile(strBASE_FOLDER .. "assystLua_Reminder\\" .. strUtilityName .. ".lua")		-- run logic file
