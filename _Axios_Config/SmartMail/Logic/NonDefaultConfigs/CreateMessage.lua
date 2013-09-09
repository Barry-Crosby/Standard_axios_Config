--debug_to_outlook = true

--------------------------------------------------------------------------------------
-- CreateMEssage.lua
-- Prepared for AGS SmartMail Quick Config (Version 3.0)
--
--	Send an email to the assigned user/team when a "chase up" action is taken.
--	The Chase Up action has been renamed to Status Request.
--
--
-- This script is not supported by Axios Systems. The script is provided as is and Axios Systems
-- accepts no responsibility or liability for the consequences of using this script.
--
--------------------------------------------------------------------------------------
-- to include values from custom form fields use the following syntax:
--		["form field name"] = "template_variable",
-- e.g.
--		["RFC Extended Description"] = "RFC_Extended_Desc",
--
--		This would set the RFC_Extended_Desc variable to the value of the "RFC Extended Description" field
CUST_FIELD_LIST = {	}
		

--------------------------------------------------------------------------------------
-- Include File With Common Global Variables, DB, Path and SMTP Information
--------------------------------------------------------------------------------------
dofile ("dofiles\\SmartMailParms.lua")

--------------------------------------------------------------------------------------
-- Log key data
--------------------------------------------------------------------------------------
LOGGER:info("Start of createmessage.lua: \nEVENT: " .. (EVENT_TYPE or "") .. (EVENT_REF or "") )

ImportFile = strAIMimportpath .. "ImportMessage" .. ACT_REG_ID .. ".autodat"

Message = "max_errors 10\n"
Message = Message  .. "separator '|'\n"
Message = Message  .. "delimiter '^'\n"
Message = Message  .. "batch 100\n"
Message = Message  .. "ignore_dups\n"
Message = Message  .. "table message\n"
Message = Message  .. "columns message_id keyval\n"
Message = Message  .. "message_sc varchar\n"
Message = Message  .. "message_n varchar\n"
Message = Message  .. "message_cat_id lookup message_cat_id from message_cat where message_cat_sc\n"
Message = Message  .. "active_from date currentdate\n"
--Message = Message  .. "active_from date '01/01/2010'\n"
Message = Message  .. "csg_id int '0'\n"
Message = Message  .. "csg_sc varchar ''\n"
Message = Message  .. "modify_id varchar 'Imported'\n"
Message = Message  .. "modify_date date currentdate\n"
Message = Message  .. "disp_to_all char 'n'\n"
Message = Message  .. "stat_flag char\n"
Message = Message  .. "version int '1'\n"
Message = Message  .. "rich_descgrp_id int '0'\n"
Message = Message  .. "message_sort_order int '1'\n"
Message = Message  .. "image_url varchar '/assystimages/info.png'\n"
Message = Message  .. "assyst_user_homepage  char 'y'\n"
Message = Message  .. "business_user_view char 'n'\n"
Message = Message  .. "assyst_user_view char 'y'\n"
Message = Message  .. "+more extended_varchar\n"
Message = Message  .. "data\n"
Message = Message  .. "AUTO MESSAGE " .. ACT_REG_ID .. "|Auto Message|BLUE|n|^\n"
Message = Message  .. string.gsub(ACT_DESC, "(\n)", "<br>") .. "^" 

SMEXT_createIMPfile(ImportFile,Message )
SMEXT_RunACLI_U(ImportFile)			
rename_for_archive = "move \"" .. ImportFile .. " \" \"" .. ImportFile ..  "processed\""
ok,err = os.execute(rename_for_archive)
if err then
	LOGGER:warn(err)
end

--------------------------------------------------------------------------------------
--   End of File
--------------------------------------------------------------------------------------