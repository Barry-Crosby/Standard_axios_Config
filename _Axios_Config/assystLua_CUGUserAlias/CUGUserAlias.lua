--------------------------------------------------------------------------------------------
-- Change Log
-- 2012-07-26 Add email address to ZZ user
-- 2012-08-21 Correct assyst User update to use usr_alias_id instead of usr_id
-- 2012-11-12 Handle null email addresses
--            Correct contact user update to set both usr_alias and usr_alias_sc
--            Update alias user's email address when usr_sc changes
--------------------------------------------------------------------------------------------
LOGGER:info("...... Starting " .. strUtilityName .. " ...... Database: " .. strassystDBName)

-- set some global variables:
file_date_part = os.date("%Y%m%d%H%M%S")


header_update_alias_user = [[max_errors 1000
separator '|'
delimiter '"'
batch 100
update assyst_usr_id
table assyst_usr
columns assyst_usr_id keyval
assyst_usr_sc varchar
assyst_usr_n varchar
mail_addr varchar
stat_flag char
modify_id varchar 'CUG-ALIAS-UPD-LINKED_AUSER'
modify_date date currentdate
data
]]

header_update_alias_link = [[max_errors 1000
separator '|'
delimiter '"'
batch 100
update usr_sc
table usr
columns usr_id keyval
usr_sc varchar
usr_alias_id lookup assyst_usr_id from assyst_usr where assyst_usr_sc
usr_alias_sc varchar
modify_id varchar 'CUG-ALIAS-UPD-LINK'
modify_date date currentdate
data
]]

header_new_alias_user = [[max_errors 1000
separator '|'
delimiter '"'
batch 100
ignore_dups
table assyst_usr
columns assyst_usr_id keyval
assyst_usr_sc copy_varchar
assyst_usr_sc varchar
assyst_usr_n varchar
mail_addr varchar
stat_flag char 'n'
modify_id varchar 'CUG-ALIAS-ADD'
modify_date date currentdate
data
]]

header_update_usr_alias = [[max_errors 1000
separator '|'
delimiter '"'
batch 100
update usr_sc
table usr
columns usr_id keyval
usr_sc varchar
usr_alias_id lookup assyst_usr_id from assyst_usr where assyst_usr_sc
usr_alias_sc varchar
modify_id varchar 'CUG-ALIAS-UPD'
modify_date date currentdate
data
]]

header_add_vip_alerts = [[max_errors 1000
separator '|'
delimiter '"'
batch 100
insert
table incspc
columns incspc_id keyval
incspc_item lookup usr_id from usr where usr_sc
display_rmk varchar
incspc_type int '50'
incspc_code char 'a'
inc_display_now char 'y'
inc_serious int '0'
inc_prior int '0'
incspc_start date currentdate
stat_flag char 'n'
modify_id varchar 'CUG-VIP-ALERT'
modify_date date currentdate
version int '1'
data
]]

-- 
--	Import file parameters
--
if strassystDBType:lower() == "sqlserver" then
	strConcatenate = "+"
else
	strConcatenate = "||"
end

separator = "|"

--
--	SQL Scripts
--

SQL_USERS_TO_ADD = [[ 
	SELECT usr_sc USR_SC
		, usr_n USR_N
		, email_add EMAIL_ADDRESS
		FROM usr
		WHERE usr.usr_alias_sc = ']] .. DEFAULT_ALIAS .. [['
			and usr.stat_flag = 'n'
			and usr.usr_sc <> 'GUEST']]

	
SQL_USERS_TO_UPDATE = [[
	SELECT usr_sc USR_SC
		, usr_alias_id ASSYST_USR_ID
		, usr_n USR_N
		, email_add EMAIL_ADDRESS
		, stat_flag STAT_FLAG
		, 'ZZ_']] .. strConcatenate .. [[ usr_sc NEW_ALIAS_SC
		, usr_alias_sc USR_ALIAS_SC
		FROM usr 
		WHERE usr.usr_alias_sc <> 'ZZ_']] .. strConcatenate .. [[ usr_sc
			and usr.usr_alias_sc <> ']] .. DEFAULT_ALIAS .. [['
			and usr.usr_alias_sc <> ''
			and usr.usr_sc <> 'GUEST'
			and usr.usr_sc <> 'ZZ-ANET-HOMEPAGE']]

--
--	Update any assyst users where the short code of the Contact User has been updated (e.g. after marriage)
--
function users_to_update()

	local count = 0
	local sImport1Line = ""
	local sImport2Line = ""
	
---
---	Process any users to update
---
	local result, err = DB:multi_row_sql(SQL_USERS_TO_UPDATE)

	if result then
		for x = 1, result.n do
			-- Alias assyst Users
			sImport1Line = sImport1Line 
			.. result.ASSYST_USR_ID[x]
			.. separator  .. result.NEW_ALIAS_SC[x] 
			.. separator  .. "ZZ_" .. result.USR_N[x] 
			.. separator  .. stringify((result.EMAIL_ADDRESS[x] or "")) 
			.. separator  .. result.STAT_FLAG[x] 
			.. "\n"
			
			-- Contact User Alias
			sImport2Line = sImport2Line
			 .. result.USR_SC[x] 
			.. separator  .. result.NEW_ALIAS_SC[x] 
			.. separator  .. result.NEW_ALIAS_SC[x] 
			.. "\n"
			
			count = count + 1
			LOGGER:info("Updating link on " .. result.USR_SC[x] .. ", from: " .. result.USR_ALIAS_SC[x] .. ", to: " .. result.NEW_ALIAS_SC[x])
		end
		
		if count > 0 then
			LOGGER:info("Updating " .. stringify(count) .. " alias users with revised short codes")
			local dataString  = header_update_alias_user .. sImport1Line
			local fileName = AIM_FOLDER .. "UPD_ZZ-AssystUsers_import." .. file_date_part .. ".dat"
			
			create_acli_import_file(dataString, fileName)
			run_acli_import_single_with_error_checking(fileName)
		
			dataString  = header_update_alias_link .. sImport2Line
			local fileName = AIM_FOLDER .. "UPD_User_Alias_Link_import." .. file_date_part .. ".dat"
			create_acli_import_file(dataString, fileName)
			run_acli_import_single_with_error_checking(fileName)
			
			LOGGER:info(stringify(count) .. " alias users updated")
		else
			LOGGER:info("No alias users to update")
		end
	else
		LOGGER:info("No alias users updated.  SQL result: " .. (err or "no error"))
	end

end

--
--	Add alias users for any new contact users (based on the alias matching the default for new users)
--  After adding the alias user update the contact user to point to the new assyst user
--
function add_alias_users()

	local count = 0
	local sImport1Line = ""
	local sImport2Line = ""
	
---
---	Process any users to add
---
	local result, err = DB:multi_row_sql(SQL_USERS_TO_ADD)

	if result then
		for x = 1, result.n do
		
		-- Import file to add alias
			sImport1Line = sImport1Line 
			 .. DEFAULT_ALIAS 
			.. separator  .. "ZZ_" .. result.USR_SC[x] 
			.. separator  .. "ZZ_" .. result.USR_N[x] 
			.. separator  .. stringify((result.EMAIL_ADDRESS[x] or "")) 
			.. "\n"
			
		-- Import file to update contact user
			sImport2Line = sImport2Line
			 .. result.USR_SC[x] 
			.. separator  .. "ZZ_" .. result.USR_SC[x] 
			.. separator  .. "ZZ_" .. result.USR_SC[x] 
			.. "\n"
			
			count = count + 1
		end
		
		if count > 0 then
			LOGGER:info("Adding " .. stringify(count) .. " alias users")
		
			local dataString  = header_new_alias_user .. sImport1Line
			local fileName = AIM_FOLDER .. "ADD_ZZ-AliasUsers_import." .. file_date_part .. ".dat"
			
			create_acli_import_file(dataString, fileName)
			run_acli_import_single_with_error_checking(fileName)
		
			dataString  = header_update_usr_alias .. sImport2Line
			local fileName = AIM_FOLDER .. "UPD_Set_User_Alias_import." .. file_date_part .. ".dat"
			create_acli_import_file(dataString, fileName)
			run_acli_import_single_with_error_checking(fileName)
			
			LOGGER:info(stringify(count) .. " alias users added")
		else
			LOGGER:info("No alias users to add")
		end
	else
		LOGGER:info("No alias users to add.  SQL result: " .. (err or "no error"))
	end

end

--
--	Add VIP Alerts for new VIPs
--
function add_vip_alerts()

	local count = 0
	local sImport1Line = ""
	
---
---	Process any users to add
---
	local result, err = DB:multi_row_sql(SQL_VIP_ALERTS_TO_ADD)

	if result then
		for x = 1, result.n do
		
		-- Import file to add alias
			sImport1Line = sImport1Line 
			 .. result.USR_SC[x] 
			.. separator  .. VIP_ALERT_TEXT 
			.. "\n"
			
			count = count + 1
		end
		
		if count > 0 then		
			LOGGER:info("Adding " .. stringify(count) .. " VIP users")
			local dataString  = header_add_vip_alerts .. sImport1Line
			local fileName = AIM_FOLDER .. "ADD_VIP_ALERTS_import." .. file_date_part .. ".dat"
			
			create_acli_import_file(dataString, fileName)
			run_acli_import_single_with_error_checking(fileName)
		
			LOGGER:info(stringify(count) .. " VIP Alerts added")
		else
			LOGGER:info("No VIP Alerts to add")
		end
	else
		LOGGER:info("No VIP Alerts to add.  SQL result: " .. (err or "no error"))
	end

end

users_to_update()
add_alias_users()

if (SQL_VIP_ALERTS_TO_ADD or "") ~= "" then
	add_vip_alerts()
end

LOGGER:info("...... Ending " .. strUtilityName .. ".......")
