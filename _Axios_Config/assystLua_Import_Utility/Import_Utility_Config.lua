--------------------------------------------------------------------------------------
-- Import_Utility_Config.lua
-- Prepared for AGS aLua Config (Version 5.1)
--
-- This script is not supported by Axios Systems. The script is provided as is and Axios Systems
-- accepts no responsibility or liability for the consequences of using this script.
--
-- Operation: The script will append the source import file to the header file
-- 			  and then run the ACLI import. Errors will be capture in the log file and an email will be
--			  sent to the administrator. 
-- NOTE: Folder names below must have a trailing "\" as the last character.
--------------------------------------------------------------------------------------
-- 2012-08-20 Update with new format to manage sequence of files
--------------------------------------------------------------------------------------
	strUtilityName = "Import_Utility"		-- do not change
--------------------------------------------------------------------------------------
	LOG_LEVEL = "INFO"							-- Must be one of "ERROR", "WARN", "INFO", "DEBUG". Defaults to INFO if omitted
	BypassLoggingEnvironment = "y"

-- Folder for import file headers
	HDR_FOLDER = [[\_Axios_Config\ImportFiles\ImportHeaders\]]

-- Folder where source import files will be placed
	SOURCE_FOLDER = [[\_Axios_Config\ImportFiles\ImportFilesReady\]]

-- List of source files (in SOURCE_FOLDER) and each related header to use
-- the import file names will be based on the source file name (not the header file)
	SOURCE_FILES_LIST = {
		{
			["JobTitle.csv"] = "JobTitleHeader.txt",
		},
		{
			["CostCenter.csv"] = "CostCenterHeader.txt",
		},
		{
			["Bldng.txt"] = "BuildingHeader.txt",
		},
		{
			["BldngRoom.txt"] = "BuildingRoomHeader.txt",
		},
		{
			["Sectn.txt"] = "SectnHeader.txt",
		},
		{
			["SectnDept.txt"] = "SectnDeptHeader.txt",
		},
	}

-- Folder to place import files for ACLI to import
	AIM_FOLDER = [[\_Axios_Config\AIM\]]
	
-- Folder to place import generated log files
	ARCHIVE_FOLDER = [[\_Axios_Config\AIM\Archive\]]

--------------------------------------------------------------------------------------
--
-- set up environemnt
--
--------------------------------------------------------------------------------------
-----  Execute logic and global files ------
strBASE_FOLDER = "\\_Axios_Config\\"
SCRIPT_PATH = strBASE_FOLDER .. "assystLua_" .. strUtilityName .. "\\"
dofile(strBASE_FOLDER .. "Common\\BaseConfig.lua")             			   	-- load Lua environment variables
dofile(strBASE_FOLDER .. "common\\Functions\\Axios_Logging_Utility.lua")				-- Load logging utilities
dofile(strBASE_FOLDER .. "common\\Functions\\functions.lua")             			   	-- load ACLI import functions
dofile(strBASE_FOLDER .. "assystLua_" .. strUtilityName .. "\\" .. strUtilityName .. ".lua")				   	-- run logic file

