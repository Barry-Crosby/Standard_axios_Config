debug_to_outlook = true
--debug_to_file = "LUA Exercise_XX.txt"

--------------------------------------------------------------------------------------
-- 	LUA Exercises.lua
--
-- 	This script is designed to be used with Smart Mail training to highlight
-- 	basic LUA techniques that are used throughout assyst.
--
--	This can be used asis for a group exercise or copied to LUA Exercise_XX.lua where
--	XX is a unique value for each student.  In this case each file described below should also
--	be created using the _XX suffix
--
--	To initiate this script use LUA Excercise_XX.bat
--
--------------------------------------------------------------------------------------

--
--	IMPORTANT!!!
--
--	Before starting verify the database that you are pointing at and supported email list
--		BaseConfig.lua	- has database connection information
--		SmartMailparms.lua	- has the list of valid email addresse
--
--

--
--	Exercise:   Understand basic SmartMail invocation and logging to assist in script configuration
--
--

LOGGER:info("Start of LUA Exercises.lua (Hello World)")
os.exit(0)		-- this will terminate the script right here

--
--	Exercise:	Understand Lua variables
--
--		Variables in Lua or loosely typed, dynamically declared and case sensitive
--
--		Remove the os.exit(0) above and run the test bat.  
--		Work through the error messages you receive, correcting the script and retesting
--

VARIABLE_ONE = "A variable value"

LOGGER:info("VARIABLE_ONE: " .. VARIABLE_ONE .. " (the double . is lua syntax for concatenate")

LOGGER:info("VARIABLE_TWO: " .. (VARIABLE_TWO or "default value if nil") .. " (the 'or' syntax is used to establish a default value if a variable is nil.  This can happen with variables created from SQL queries of if using uninitialized variables")

VARIABLE_TWO = "Variable two"

LOGGER:info("VARIABLE_TWO: " .. VARIABLE_TOO .. " (without the 'or' this fails")
-- To resolve the 'attempt to concatenate global `VARIABLE_TWO'' error 
-- correct the spelling of TOO in the line above

os.exit(0)

--
--	Exercise:	Working with SQL
--
--		This illustrates how to retrieve extra data values for emails as well as lua table type fields.
--
--		Remove the os.exit(0) above and run the test bat.  
--
--		If you can't sort things out run Smart Mail in debug mode by adding an additional -v parameter. (1 -v == verbose, 2 -v == very verbose)
--

LOGGER:info("Expect a fatal error first time because there's a syntax error in the sql.  Fix the sql and rerun after getting the error")
LOGGER:info("This error indicates there is a syntax problem with the SQL: attempt to index local `T_or_err'")
LOGGER:info("Note that the error above will come out at the end of the SMEXT_send_email.log.")

--------------------------------------------------------------------------------------
-- include_SQL is a lua table that will have a list of one or more sql files to execute
--------------------------------------------------------------------------------------
include_SQL = { "LUA Exercise_XX_sql.lua",}

--------------------------------------------------------------------------------------
-- Include File With Common Global Variables, DB, Path and SMTP Information
--------------------------------------------------------------------------------------
dofile("dofiles\\SmartMailParms.lua")

LOGGER:info("Retrieved SQL value: " .. MY_INCIDENT_ID)
LOGGER:info("Some other values that are automatically retrieved  EVENT: " .. (EVENT_TYPE or "").. (EVENT_REF or "") .. ", AFF_USR_EMAIL: " .. (AFF_USR_EMAIL or ""))
os.exit(0)

--
--	Exercise:	Working with the overall structure
--
--		Change the parameters so that a different incident id is retrieved (don't change the SQL)
--


--
--	Exercise:	Send an email manually (simulate what assyst will do to send an email)
--
--		If working on a desktop with Outlook leave the parameters at the top of the file asis, 
--		otherwise change the debug to go to a file
--
--		Note: If you have configured the SMTP server in BaseConfig.lua you can turn off the debugging options.
--
--		Start by sending an email to yourself
--		comment out the os.exit above and configure the lines below

name = "your name goes here"
email = "youremailaddress@anycorp.com"

email_subject = "Test email"
template = "assign_Open.html"
SMEXT_send_email(name, email, email_subject, template)
LOGGER:info("Test Email Sent")

os.exit(0)


--
--	Exercise:	Generate the email from assyst action job
--
--		Create a new action in assyst LUA EXERCISE XX
--		Configure an action job that runs client side
--		Take the contents of the test bat and put it in the action job 
--		- replacing the hard-coded act_reg_id value with a parameter ($ACT_REG_ID)
--		Take the action in the Windows client against any event and the emails should get generated
--

os.exit(0)


--
--	Exercise:	Generate the email from assyst using the escalation processor
--
--		Modify the action job configured for assyst LUA EXERCISE XX and change it to be server side.
--		Take the LUA EXERCISE XX action.
--		Run the Escalation Processor, External Job Processor and check that the email is sent
--

os.exit(0)

--------------------------------------------------------------------------------------
--   End of File
--------------------------------------------------------------------------------------