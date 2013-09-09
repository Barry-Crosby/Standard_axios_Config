--------------------------------------------------------------------------------------
-- CommonFunctions.lua
-- This is a common header file that contains functions to be shared across scripts
-- NOTE - commonParms.lus must be executed first before these functions are called
--------------------------------------------------------------------------------------
-- Prepared for AGS SmartMail Quick Config (Version 3.0)
--
-- This script is not supported by Axios Systems. The script is provided as is and Axios Systems
-- accepts no responsibility or liability for the consequences of using this script.
--
--------------------------------------------------------------------------------------
-- Change log
-- Aug 06 2009	Added SMEXT_CallACLI function
-- Aug 09 2009	Added getPureEventDesc function
-- Sep 08 2009	Update recipientaddressformat to handle empty email address
-- Sep 09 2009	Add SMEXT_send_email_withCC
-- Sep 12 2009	Set validList correctly when allowedEmails is not used
-- Oct 06 2009  Changed recipientnameformat to format to and cc's in name<email> format
-- Oct 07 2009  Fixed return on recipientnameformat function
-- Oct 08 2009	More changes on email validation to make sure array sizes match and
--				Both the recipients and the formatted email names show the actual email used
-- Oct 08 2009  Fixed message variable in SMEXT_createIMPfile function
-- Feb 24 2010  Added SMEXT_FormatNameFromEmail to get 'nice' name format from emails. The function takes 2 parameters. The first parameter is an email address,
--				the second parameter is the separator character between the first and last name (i.e. sam_smith@any.com, separator = '_')
-- Mar  2 2010	Modified EVENT_TYPE_U to handle changes that are actually service requests
-- Mar 21 2010	Put common prefix on general functions
-- Jan 13 2010	Changed to put < > around email addresses in getElist so all addresses are in this format (prevent SMTP error)
-- Feb 22 2012	Delete all functions covered by RulesDispatcher
-- Jul 17 2012  Add getEmailSubjectPrefix and getEventLink
-------------------------
-------------------------


-- Format EventDesc without extra data for email (for parent for ticket desc)
function getPureEventDesc(strEventDesc)
--
-- Logic to exclude custom web fields from description if required
--
	END_OF_REG = (string.find(strEventDesc, "<==# ADDITIONAL INFORMATION") or "")
	if (END_OF_REG ~= "") then
		PURE_EVENT_DESC = string.sub(strEventDesc,1, END_OF_REG - 3)
	else
		PURE_EVENT_DESC = strEventDesc
	end

	return PURE_EVENT_DESC
end

if ExcludeAdditionalInformationFromDescription == "YES" then
	EVENT_DESC = getPureEventDesc(EVENT_DESC)
end

function getEnvironment()
--[[
Checks the server's hostname & machine_name environment variables to determine whether we're running in PROD, DEV, or some other environment.
This will be used elsewhere to set various variables & strings as appropriate for each environment
This function must be located here because CommonFunctions depends upon this file, and is executed after.
]]
	serverName = upper((os.getenv("HOSTNAME") or os.getenv("COMPUTERNAME") or os.getenv("MACHINE_NAME") or ""))
	if (serverName == upper(strIntServerProd) ) then
		return "PROD"
	elseif (serverName == upper(strIntServerDev )) then
		return "DEV"
	elseif (serverName == upper(strIntServerTest )) then
		return "TEST"
	else
		return "UNKNOWN SERVER: " .. serverName
	end
end


serverEnv = getEnvironment()

function getEmailSubjectPrefix()
	if (serverEnv ~= "PROD") then
		email_subject_prefix = "[" .. serverEnv .."] "
	else
		email_subject_prefix =""
	end
	return email_subject_prefix
end

strEmailSubjectPrefix = getEmailSubjectPrefix()

function getEventLink(sText, sEventId, sLink, bWeb, bMobile, bNet)

	sResult = ""
	
	if EVENT_TYPE == "d" then
		sDecisionLink = "&actTypeId=-1"
	else
		sDecisionLink = ""
	end

	if bWeb then
		sResult = sText .. "<A HREF=\""
			.. strBaseURL .. "assystweb/event/DisplayEvent.do?dispatch=getEvent&eventId="
			.. sEventId
			.. "&resultset=EventSearchEventList&ncAction=RESETHISTORY&ncForwardName=EventSearch&history=HISTORYCLEAR"
			.. sDecisionLink
			.. "\">"
			.. sLink
			.. ".</A><br>"
	elseif bMobile then
		sResult = sText .. "<A HREF=\""
			.. strBaseURL .. "assystHtml/event/DisplayEvent.do?dispatch=getEvent&eventId="
			.. sEventId
			.. "&resultset=EventSearchEventList&ncAction=RESETHISTORY&ncForwardName=EventSearch&history=HISTORYCLEAR\">"
			.. sLink
			.. ".</A><br>"
	else 	-- NET
		sResult = sText .. "<A HREF=\""
			.. strBaseURL .. "assystnet/application/assystNET.jsp#type=16;id="
			.. sEventId
			.. "\">"
			.. sLink
			.. ".</A><br>"
	end		
		
	return sResult

end


--------------------------------------------------------------------------------------
-- 		FUNCION SMEXT_FormatNameFromEmail
--
--		Returns a user friendly name based on their email address
--		This can be used when the user data has formal names in the data but friendly names in the email
--
--------------------------------------------------------------------------------------
function SMEXT_FormatNameFromEmail(email_addr, sep)
--	the second parameter is the separator character between the first and last name (i.e. sam_smith@any.com, separator = '_')

	LOGGER:info("In SMEXT_FormatNameFromEmail")
	fname = "unknown"
	lname = ""
	if not sep then
		sep = '.'
	end
	
	if (email_addr or "") == "" then
		return ""
	end
	
	if string.find(email_addr, '@') == 0 then
		return email_addr
	end
	
	if string.find(email_addr, sep, 1, true) > 0 and string.find(email_addr, sep, 1, true) < string.find(email_addr, '@') then 
		fname = string.sub(email_addr, 1, string.find(email_addr, sep, 1, true) -1)
		lname = string.sub(email_addr, string.len(fname) + 2, string.find(email_addr, '@') - 1)
	else
		fname = string.sub(email_addr, 1, charindex('@',email_addr)-1)
	end
	
--	LOGGER:info("SMEXT_FormatNameFromEmail: " .. (email_addr or "") .. ", fname: " .. (fname or "") .. ", lname: " .. (lname or "") )
	
	if lname == "" then
		return fname
	else
		return fname .. " " .. lname
	end
	
end

function SMEXT_FormatNameFromDate(formatdate)

	-- If the value isn't the expected length just get out
	if string.len(formatdate) ~= 10 then
		return formatdate
	end
	
	-- If the value isn't the expected format just get out
	if string.sub(formatdate,3,3) ~= "/" then
		return formatdate
	end
	
	return string.sub(formatdate,4,5) .. "/" .. string.sub(formatdate,1,2) .. string.sub(formatdate,6)
end


function SMEXT_createIMPfile(ImpFileStr,CmdStr)
	impFile, err = io.open(ImpFileStr, "w")
	if not (impFile) then
		LOGGER:error ("Failed to open file: " .. ImpFileStr .. ", err: " .. (err or "?"))
	else
		impFile:write(CmdStr)
		io.close(impFile)
	end
end

-- Run ACLI in Import Utility mode
function SMEXT_RunACLI_U(aFileName)
	aclicmd = "\"" .. straclipath .. "\" -v:SQLserver -h:" .. strassystDBServer .. " -d:" ..strassystDBName .. " "
	aclicmd = aclicmd .. "-u:" .. strassystUserSM .. " -p:" .. strassystPWSM .." -ui:n -f:" .. aFileName .. " "
	aclicmd = aclicmd .. "-t:u -ep:\"" .. strImportProfile .. "\" -ap:\"" .. strActionProfile .. "\""

	LOGGER:info("SMEXT_RunACLI_U aclicmd: " .. aclicmd)

	-- Execute ACLI
	Result = os.execute("\"" .. aclicmd)
	if Result ~= 0 then
		LOGGER:error("Error executing ACLI command.  Result: " .. tostring(Result) .. ", ACLI Command: \"" .. aclicmd .. "\"")
	end
end

function SetEventTypeU()
	EVENT_TYPE_AIM = string.upper(EVENT_TYPE)
	if EVENT_TYPE == "i" then
		EVENT_TYPE_U = ""
	elseif EVENT_TYPE == "c" then
		if EVENT_TYPE_EXT == "s" then
			EVENT_TYPE_U = "S"
		else
			EVENT_TYPE_U = "R"
		end
	else
		EVENT_TYPE_U = string.upper(EVENT_TYPE)
	end
end

SetEventTypeU()


dofile("dofiles\\ExtraFunctions.lua")
dofile("dofiles\\get_html.lua")




