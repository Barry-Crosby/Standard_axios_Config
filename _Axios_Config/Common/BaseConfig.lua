--------------------------------------------------------------------------------------
--- BaseConfig.lua contains common environment specific settings for  
--- all Lua based components, CUG, aLua Mailbox Processor, and SmartMail
--------------------------------------------------------------------------------------
-- Change log
-- 02/12/2009	Initial version of file
-- 05/28/09		Tested with aLua
-- 06/02/09		Combined all conf files from all Lua based tools
-- 02/15/12		Added email information here
--------------------------------------------------------------------------------------

BASE_FOLDER = "\\_Axios_Config\\"

-----------------------------------------------------------------
--- Common Set Variables
------------------------------------------------------------------
strServiceDeskName = "Anycorp Service Desk"  									-- From (display name) for emails sent from SmartMail
strServiceDeskSVD = "SERVICE DESK"
strServiceDeskEmail = "Anycorp@anycorp.com"        						-- From (email address) for emails sent from SmartMail
strAuthEmail = "Admin@anycorp.com"         								-- Email address for authorization replies (optional)
strAdminEmailName = "assyst Technical Administrator"           		-- Admin Email for SmartMail SMTP errors 
strAdminEmail = "servicedesk@anycorp.com"           					-- Admin Email Address for SmartMail SMTP errors 
strassystDBType = "SQLServer"											-- Type of DB SQLServer or Oracle
strDBInterface = "ado"													-- "oo4o", "ado" , "oci" or odbc",
strassystDBServer = "localhost"											-- DB Server of assyst database
strassystDBName = "assyst10search"										-- assyst Database Name
strassystUserMBR = "assystadmin"       									-- Mailbox Reader assyst user  (optional)
strassystPWMBR = "axios"     											-- Mailbox Reader assyst user paswword
strassystUserAP = strassystUserMBR      								-- Action Processor assyst user
strassystPWAP = strassystPWMBR     										-- Action Processor  assyst user paswword
strassystUserCUG = strassystUserMBR										-- Contact User Gateway assyst user
strassystPWCUG = strassystPWMBR    										-- Contact User Gateway assyst user password
strassystUserSM = strassystUserMBR 										-- SmartMail assyst user
strassystPWSM = strassystPWMBR    										-- SmartMail assyst user password
strIntServerProd = "prodintegrationserver"
strIntServerDev = "VM-FDB-SQL-01"
strIntServerTest = "testintegrationserver"

strassystServer = "127.0.0.1"
strassystBaseURL = "http://" .. strassystServer .. ":8080/"
strBaseURL = strassystBaseURL
strEJBUrl = "http://localhost:8990/assyst/assystEJB"					-- URL for EJB (RESTful API service) if used
strassystWebURL = strassystBaseURL .. "assystweb"						-- URL for assyst Web.   Used for linking to events from emails
strassystNetURLBase = strassystBaseURL .. "assystnet/application/assystNET.jsp"				-- URL for assyst Net.   Used for linking from emails
strassystNETEventLink = "#type=16;id="
strassystMobileURL = strassystBaseURL .. "assystHtml"				-- URL for assyst Mobile.   Used for linking to events from emails
COMP_LOGO =	"http://www.Anycorp.com/images/Anycorp.gif"      		-- Link to Company Logo
COMP_LOGO = "" -- Set to empty string to suppress logo in email
strServerType = "SQLServer"												-- DB Type used for acli imports
straclipath = "\\Program Files (x86)\\assyst Enterprise 10.0\\acli.exe"					-- Path where acli.exe is located
--straclipath = "\\Program Files\\assyst10R0\\acli.exe"
strAIMimportpath = BASE_FOLDER .. "AIM\\"								-- Path where acli.exe will put the import files
strESCimportpath = BASE_FOLDER .. "AIM\\"								-- Path where acli.exe will put the import files for escalation processor
strImportProfile = "GENERAL FAULT"								 		-- Valid assyst Import Profile 
strActionProfile = "GENERAL ACTION"										-- Valid assyst Action Profile 
strassystVersion = "9.0"												-- Version of assyst. Only used for V9
strKnowledgeOwner = "Knowledge Manager"									-- Name of user that owns creating Knowledge procedures (optional)
strKnowledgeOwnEmail = "servicedesk@anycorp.com"						-- email address of knowledge owner (for knowledge candidate)
strSMTPServer = "127.0.0.1"
strPOPServer = "127.0.0.1"

strRequestMajorCategorySC = "REQUEST"									-- Major Category associated with Service Requests

ExcludeAdditionalInformationFromDescription = "YES"						-- Change to NO if you want additional information in EVENT_DESC

-- Define the text that will display a URL link in the html template for a user to click on that will take them to their survey in assystNET.
bIncludeSurvey = true													-- Set to true to include a survey link
strSurveyLink = strassystNetURLBase .. "#;type=29;id="
EMAIL_SURVEY_TEXT_FR = "S'il vous plaît cliquer ici pour remplir un court sondage concernant votre expérience."
EMAIL_SURVEY_TEXT_EN = "Please click here to complete a short survey regarding your experience."

bAutoAssignToProblemMgmt = true
PROBLEM_MGMT_SVD = "PROBLEM MGMT"

CUSTOM_FIELD_BOOLEAN_TRUE = "Yes"
CUSTOM_FIELD_BOOLEAN_FALSE = ""
CUSTOM_FIELD_DATE_FORMAT_SQL = 102  -- (101 == MM/DD/YYYY, 102 == YYYY,MM,DD, 103 == DD/MM/YYYY - Internet has many more)

--------------------------------------------------------------------------------------
-- Start RulesDispatcher Control Defaults
--------------------------------------------------------------------------------------
controls_default_test_mode_on = false
controls_default_debug_to_outlook = true
controls_default_use_import_processor = true

-- email_test_filter settings
	controls_email_test_filter_on = false
	-- Allowed email addresses must be entered in lower case
	controls_email_test_filter_allowed = {
		"admin1@anycorp.com", "admin2@anycorp.com",
	}
	controls_email_test_filter_otherwise = "otherwise@anycorp.com"

-- admin_email settings
	controls_admin_email_on = true
	controls_admin_email_name = strAdminEmailName
	controls_admin_email_email_address = strAdminEmail
--------------------------------------------------------------------------------------
-- End RulesDispatcher Control Defaults
--------------------------------------------------------------------------------------


--------------------------------------------------------------------------------------
-- Settings for email approvals and automated replies
--------------------------------------------------------------------------------------
strApprovalEmailAddress = "mbr@anycorp.com"
strApprovalString = "Approved"
strNotApprovedString = "Denied"
strReopenRequest = "Reopen request"

--------------------------------------------------------------------------------------
if string.upper(strassystDBType) == "SQLSERVER" then
	DATESTR = "getdate()"
else
	DATESTR = "sysdate"
end