--------------------------------------------------------------------------------------
-- Reminder Utility.lua (originally copied from Auto Close
-- Prepared for AGS aLua 3.6 Scripting
--
-- This script is not supported by Axios Systems. The script is provided as is and Axios Systems
-- accepts no responsibility or liability for the consequences of using this script.
--
-- This script notifies Assignee's via Smartmail after pending time has breached the time
-- Specified in the ASSIGNEE_DAYS_PENDING in the Reminder_Config.lua file
-- adjusts for weekend days in SQL.
--------------------------------------------------------------------------------------
LOGGER:info("...... Starting " .. strUtilityName .. " ...... Database: " .. strassystDBName)
LOGGER:info("Major Categories: " .. REMINDER_MAJOR_CATEGORY1 
	.. "/" .. REMINDER_MAJOR_CATEGORY2
	.. "/" .. REMINDER_MAJOR_CATEGORY3
	.. "/" .. REMINDER_MAJOR_CATEGORY4
	.. "/" .. REMINDER_MAJOR_CATEGORY5)

REMINDER_ACTION_ID = get_id("ActionType", REMINDER_ACTION_SC, true)			--Return the Action ID for the Reminder Action name defined in Config
M_REMINDER_ACTION_ID = get_id("ActionType", M_REMINDER_ACTION_SC, true)		--Return the Action ID for the  Manager Reminder Action name defined in Config		

DATE_ADJUST = 0	-- only works for SQL
if (strServerType or "") == "SQLServer" then
	-- check to see if date is Monday or Tuesday and add 2 if so
	STRSQL = ([[
		SELECT 'OK' "OK"
		WHERE DATENAME(d , getDate())  in (1, 2)
	]])

	result, err = ASSYSTEJB:sql(STRSQL)
	LOGGER:debug(stringify(result or err))

	if err then
		LOGGER:error("Error checking day of week.  Error: " .. (err or "?") .. ", SQL: " .. (STRSQL or ""))
		os.exit(-1)
	end

	if result.OK then 
		DATE_ADJUST = 2
	end
end

LOGGER:debug("DATE_ADJUST: " .. stringify(DATE_ADJUST))

REMINDER_DAYS = tonumber(REMINDER_DAYS or 1) + tonumber(DATE_ADJUST)								-- Adds weekend day count if necessary to Reminder days
MANAGER_REMINDER_DAYS = tonumber(MANAGER_REMINDER_DAYS or 3) + tonumber(DATE_ADJUST)				-- Adds weekend day count if necessary to manager reminder days

-- Below Section builds the Reminder category syntax for the SQL statement.
if REMINDER_MAJOR_CATEGORY1 ~= nil then
	sMajorCategoryParams = "(inc_major.inc_major_sc = '".. REMINDER_MAJOR_CATEGORY1 .. "'"
end	
if REMINDER_MAJOR_CATEGORY2 ~= nil then
	sMajorCategoryParams = sMajorCategoryParams .. " OR inc_major.inc_major_sc = '".. REMINDER_MAJOR_CATEGORY2 .. "'"
end	
if REMINDER_MAJOR_CATEGORY3 ~= nil then
	sMajorCategoryParams = sMajorCategoryParams .. " OR inc_major.inc_major_sc = '".. REMINDER_MAJOR_CATEGORY3 .. "'"
end	
if REMINDER_MAJOR_CATEGORY4 ~= nil then
	sMajorCategoryParams = sMajorCategoryParams .. " OR inc_major.inc_major_sc = '".. REMINDER_MAJOR_CATEGORY4 .. "'"
end
if REMINDER_MAJOR_CATEGORY5 ~= nil then
	sMajorCategoryParams = sMajorCategoryParams .. " OR inc_major.inc_major_sc = '".. REMINDER_MAJOR_CATEGORY5 .. "'"
end
sMajorCategoryParams = sMajorCategoryParams .. ")"

function getSQL(parmReminderDays)

result = ([[
SELECT DISTINCT(incident.incident_id)
      FROM incident
        INNER JOIN
           inc_cat
              ON incident.inc_cat_id = inc_cat.inc_cat_id
        INNER JOIN
           inc_major
              ON inc_cat.inc_major_id = inc_major.inc_major_id
		INNER JOIN
			inc_data
			  ON incident.incident_id = inc_data.incident_id
	    INNER JOIN
            act_reg  
              ON incident.incident_id = act_reg.incident_id		  
		INNER JOIN
            act_type 
              ON act_reg.act_type_id = act_type.act_type_id  
      WHERE inc_status = 'o'
           AND inc_data.u_date1 is null
		   AND act_type.private_act = 'n' 
		   AND]] .. sMajorCategoryParams .. [[
		   AND act_type.user_status = 'n'
		   AND act_type.future_act = 'n'
           AND incident.incident_id not in
            
  (SELECT DISTINCT (incident.incident_id)
      FROM incident  
            INNER JOIN  
            inc_data  
                  ON incident.incident_id = inc_data.incident_id  
            INNER JOIN
            act_reg  
                  ON incident.incident_id = act_reg.incident_id
            INNER JOIN
            act_type 
                  ON act_reg.act_type_id = act_type.act_type_id  
            INNER JOIN
            inc_cat
                 ON incident.inc_cat_id = inc_cat.inc_cat_id
            INNER JOIN
            inc_major
                 ON inc_cat.inc_major_id = inc_major.inc_major_id
      WHERE  inc_status = 'o'
           AND inc_data.u_date1 is null
		   AND incident.date_logged > getdate() - ]] .. parmReminderDays .. [[
		   AND (act_type.act_type_sc <> ']] .. REMINDER_ACTION_SC .. [[' OR act_type.act_type_sc <> ']] .. M_REMINDER_ACTION_SC .. [[')
           AND act_reg.date_actioned > getdate() - ]] .. parmReminderDays .. [[
           AND]] .. sMajorCategoryParams .. [[)
  ORDER BY incident.incident_id ]] )
  
	return result
 end
 
 function processReminderResults(parmResultSet, parmReminderAction, parmReminderActionId, parmDaysAgo)
 
	LOGGER:info("Processing reminders - action: " .. parmReminderAction .. ", Days ago: " .. parmDaysAgo)
	
	strRemarks = "Event has not been actioned in " .. parmDaysAgo .. " (or more) days."
			.. " Please update the event daily to avoid reminders."
	 
	 if parmResultSet and parmResultSet.incident_id and #parmResultSet.incident_id > 0 then
		LOGGER:debug("Set reminder for the following events:\n " .. stringify(parmResultSet.INC_ID))		

		iTest = 1
		for x,inc_id in ipairs(parmResultSet.incident_id) do
				
			local ok, err = ASSYSTEJB:new_action {
				importProfile = ACTION_IMPORT_PROFILE,
				eventId = tonumber(inc_id),
				actionTypeId = parmReminderActionId,
				remarks	= (stringify(strRemarks)),
			}
			if ok then
			   strERRMSG = "Successfully added action " .. parmReminderAction .. " on incident_id: " .. inc_id .. " in assyst. Action Ref: " .. ok
			   LOGGER:info(strERRMSG)
			else
				ACT_ERR = stringify(err)
				strERRMSG = "Failed to add action " .. parmReminderAction .. "  on incident_id: " .. inc_id .. " in assyst: " ..(ACT_ERR or "?")
				LOGGER:error(strERRMSG)
			end

		end
	else
		LOGGER:info(" No events found that have been sitting unactioned during the specified time for the " .. parmReminderAction .. " reminder.")
	end
 
end
	
STRSQL1 = getSQL(REMINDER_DAYS)
result1, err1 = ASSYSTEJB:sql(STRSQL1)
LOGGER:debug(stringify(result1 or err1))
if err1 then
	LOGGER:error("Unable to query events to for standard reminder action.  Error: " .. (err2 or "?") .. ", SQL: " .. (STRSQL1 or ""))
	os.exit(-1)
end

processReminderResults(result1, REMINDER_ACTION_SC, REMINDER_ACTION_ID, REMINDER_DAYS)

if MANAGER_REMINDER_DAYS > 0 then
	STRSQL2 = getSQL(MANAGER_REMINDER_DAYS)
	result2, err2 = ASSYSTEJB:sql(STRSQL2)
	LOGGER:debug(stringify(result2 or err2))
	if err2 then
		LOGGER:error("Unable to query events to for manager reminder action.  Error: " .. (err2 or "?") .. ", SQL: " .. (STRSQL2 or ""))
		os.exit(-1)
	end

	processReminderResults(result2, M_REMINDER_ACTION_SC, M_REMINDER_ACTION_ID, MANAGER_REMINDER_DAYS)
	
end
		
LOGGER:info("...... " .. strUtilityName .. " Complete ...... ")