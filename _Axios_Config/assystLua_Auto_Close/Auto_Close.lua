--------------------------------------------------------------------------------------
-- Auto Close Utility.lua
-- Prepared for AGS aLua 3.6 Scripting
--
-- This script is not supported by Axios Systems. The script is provided as is and Axios Systems
-- accepts no responsibility or liability for the consequences of using this script.
--
-- This script closes all Pending Close events  after the time specified in the
-- CLOSE_DAYS variable in the Auto_Close_Config.lua file
-- adjusts for weekend days in SQL.
--------------------------------------------------------------------------------------
LOGGER:info("...... Starting " .. strUtilityName .. " ...... Database: " .. strassystDBName)

CLOSE_ADJUST = 0	-- only works for SQL
if (strServerType or "") == "SQLServer" then
	-- check to see if date is Monday or Tuesday and add 2 if so
	STRSQL = ([[
		SELECT 'OK' "OK"
		WHERE DATENAME(d , getDate())  in (1, 2)
	]])

	result, err = ASSYSTEJB:sql(STRSQL)
	print(stringify(result or err))

	if err then
		LOGGER:error("Error checking day of week.  Error: " .. (err or "?") .. ", SQL: " .. (STRSQL or ""))
		os.exit(-1)
	end

	if result.OK then 
		CLOSE_ADJUST = 2
	end
end

LOGGER:debug("CLOSE_ADJUST: " .. stringify(CLOSE_ADJUST))

-- set default close days to 3 if not in config file and add adjustment
CLOSE_DAYS = tonumber(CLOSE_DAYS or 3) + tonumber(CLOSE_ADJUST)


STRSQL1 = ([[
	SELECT ]] .. (CLOSE_LIMIT or "") .. [[incident.incident_id "INC_ID", 
		incident.inc_resolve_usr "ACTIONING_USER_ID",
		incident.inc_resolve_svd "RESOLVING_SVD_ID",
		incident.cause_item_id "CAUSE_ITEM_ID",
		incident.cause_id "CAUSE_CATEGORY_ID"
	FROM incident
	WHERE incident.inc_status = 'p'
	AND incident.inc_resolve_act  < getdate() - ]] .. CLOSE_DAYS .. [[
	order by incident.inc_resolve_act
]])

result1, err1 = ASSYSTEJB:sql(STRSQL1)
if err1 then
	LOGGER:error("Unable to query events to close.  Error: " .. (err or "?") .. ", SQL: " .. (STRSQL1 or ""))
	os.exit(-1)
end

if result1 and result1.INC_ID and #result1.INC_ID > 0 then
	LOGGER:debug("Auto Closing the following events:\n " .. stringify(result1.INC_ID))		

	for x,inc_id in ipairs(result1.INC_ID) do
		if (CLOSE_BY_USER or "") == "" then
			closeById = tonumber(result1.ACTIONING_USER_ID[x])
			closeBySVDId = tonumber(result1.RESOLVING_SVD_ID[x])
		else
			closeById = get_id("AssystUser", CLOSE_BY_USER, true)
			closeBySVDId = get_id("ServDept", CLOSE_BY_SVD, true)
		end
		
		local ok, err = ASSYSTEJB:new_action {
			importProfile = ACTION_IMPORT_PROFILE,
			eventId = tonumber(inc_id),
			actionTypeId = 5,
			remarks	= (CLOSE_REMARK or "Event auto closed."),
			actionedById = closeById,
			actioningServDeptId = closeBySVDId,
			causeCategoryId = tonumber(result1.CAUSE_CATEGORY_ID[x]),
			causeItemId = tonumber(result1.CAUSE_ITEM_ID[x]),
			serviceTime = {duration = tonumber(100)},
			serviceCost = {double = tonumber(2)}
		}
		if ok then
		   strERRMSG = "Successfully added " .. (CLOSE_ACTION or "Closure") .. " action on incident_id: " .. inc_id .. " in assyst. Action Ref: " .. ok
		   LOGGER:info(strERRMSG)
		else
			ACT_ERR = stringify(err)
			strERRMSG = "Failed to add " .. (CLOSE_ACTION or "Closure") .. " action on incident_id: " .. inc_id .. " in assyst: " ..(ACT_ERR or "?")
			LOGGER:error(strERRMSG)
		end
	end
else
	LOGGER:info(" No events found in pending close status to auto close.")
end

LOGGER:info("...... " .. strUtilityName .. " Complete ...... ")
