--------------------------------------------------------------------------------------
-- SmartMailExtensions.lua
-- This is a common header file that contains parmameters and functions to be shared across SmarMail scripts
--------------------------------------------------------------------------------------
-- Prepared for AGS SmartMail Quick Config (Version 3.0)
--
-- This script is not supported by Axios Systems. The script is provided as is and Axios Systems
-- accepts no responsibility or liability for the consequences of using this script.
--
--------------------------------------------------------------------------------------
-- Change log
-- Feb 24, 2010	Updated for new Quick Config Structure and file names
-- Mar 22, 2010 Renamed to SmartMailExtensions and included common functions
--------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------
-- Load Global Variables
-- Get Common Lua Settings and Variables ------
--------------------------------------------------------------------------------------
strRoot = "\\_Axios_Config\\"								-- Base path used to reference other Lua files and SmartMail quick config files
dofile(strRoot .. "Common\\BaseConfig.lua")  		-- REQUIRED (DO NOT EDIT)

--------------------------------------------------------------------------------------
--    Variables used in email templates
-- Use this area to define static variables that can be used across email templates and smartmail scripts
--------------------------------------------------------------------------------------
linefeedchar = "\n" 								-- for plain text email
-- linefeedchar = "<br>" 									-- for html emails
AUTO_ASSIGN_TEXT_PREFIX = "Automatic Event Assignment"

-- SMTP settings
--------------------------------------------------------------------------------------
smtp {
 server = strSMTPServer,								-- smtp server address 
 admin_email = strAdminEmail,
 --port = 25,
 --user = "...",
 --password = "...",
 --domain = "...",
}

-- Common settings and functions below should generally not be changed unless updates are required for Oracle

-- Paths to SQL and Lua files (DO NOT CHANGE)
--------------------------------------------------------------------------------------
strPathRoot = 			strRoot .. "SmartMail\\Logic\\"			-- Folder where SmartMail configuration files are located (i.e. assign.lua, SMEXT_send_email.lua)
strPathToTemplates = 	strRoot .. "SmartMail\\Templates\\" 	-- Path to templates (do not change)
strPathToImages = 		strRoot .. "SmartMail\\images"			-- Path to images folder used for templates
strPathToSql = 			strRoot .. "SmartMail\\SQL\\"   	  	-- Path to your SQL (do not change

--------------------------------------------------------------------------------------
-- SmartMail Database settings for SQL Server (Oracle is below)
--------------------------------------------------------------------------------------
assystdb {
           interface = "ado",				-- do not change
           server    = strassystDBServer,	-- assyst database server
           name      = strassystDBName,		-- SmartMail assyst Database Name
           user      = strassystUserSM,		-- SmartMail assyst Database user
           password  = strassystPWSM,		-- SmartMail assyst Database user Password
	   --------------------------------------------------------------------------------------

		   xsql      = strPathToSql .. "extra_sql.lua",  -- REQUIRED (DO NOT EDIT)
}

--------------------------------------------------------------------------------------
-- SmartMail Database settings for Oracle 
--------------------------------------------------------------------------------------
--assystdb {
--	interface = "oo4o", -- (or "oci")
--	service = "name of your assyst DB Oracle service",
--	user = "your assyst DB user name",
--	password = "your assyst DB password",
--}

PURE_EVENT_DESC = ""

dofile("dofiles\\SmartMailExtensionFunctions.lua")
