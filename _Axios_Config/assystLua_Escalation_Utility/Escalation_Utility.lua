--------------------------------------------------------------------------------------
-- 
-- Prepared for AGS FB Quick Config (Version 3.0)
--
-- This script is not supported by Axios Systems. The script is provided as is and Axios Systems
-- accepts no responsibility or liability for the consequences of using this script.
--
-- In most cases no changes should be requird in this file - adjust the config as required
--
--------------------------------------------------------------------------------------
-- Change log
-- 04/26/2012	Initial version of file
--------------------------------------------------------------------------------------

LOGGER:info("...... Starting " .. strUtilityName .. " ...... Database: " .. strassystDBName)
local EscCount = {}

--------------------------------------------------------------------------------------
--  Validate actions from config by loading ids
--------------------------------------------------------------------------------------
ESC_ACTION_IDS = {}
for x = 1, ESC_CNTR do
	ESC_ACTION_IDS[ESC_ACTION["ESC" .. x]] = get_id("ActionType", ESC_ACTION["ESC" .. x], true )
end

--------------------------------------------------------------------------------------
--  Get count of events requiring escalations at each level
--------------------------------------------------------------------------------------
ESC_COUNTS = {}
for x = 1, ESC_CNTR do
	
	SQL = [[
		SELECT count(*) ESC_COUNT
		FROM
			incident i, inc_data id
		WHERE    i.incident_id = id.incident_id 
			AND (i.inc_status = 'o') AND (i.inc_esc]] .. x .. [[ IS NOT NULL) 
			AND (id.intesc]] .. x .. [[ = 'n') 
			AND (i.inc_esc]] .. x .. [[ < ]] .. DATESTR .. [[)]]
--	LOGGER:info("SQL: " .. SQL)
	
	Result, err = ASSYSTEJB:sql(SQL)
	if err then
		LOGGER:fatal("Error executing SQL: " .. (err or "??") .. "/nSQL:" .. SQL)
		os.exit(-3)
	end
	
	ESC_COUNTS[x] = tonumber(Result.ESC_COUNT[1] or 0)
	if ESC_COUNTS[x] > 0 then
		LOGGER:info("Escalation" .. x .. " escalations: " .. ESC_COUNTS[x])
	end

end


--------------------------------------------------------------------------------------
--  Get all events requiring escalation
--------------------------------------------------------------------------------------
for x = 1, ESC_CNTR do
	LOGGER:debug("ESC_" .. x .. "_COUNT: " .. (ESC_COUNTS[x] or "??") )
	if ESC_COUNTS[x] > 0 then	
		SQL = [[
			SELECT     
				i.incident_id ESC_EVENT_ID,
				CASE
					when upper(id.event_type) = 'C' then 'R'
					else upper(id.event_type)
				END
					ESC_EVENT_TYPE
			FROM incident i 
				INNER JOIN inc_data id ON i.incident_id = id.incident_id 
			WHERE
				(i.inc_status = 'o') AND (i.inc_esc]] .. x .. [[ IS NOT NULL) 
				AND (id.intesc]] .. x .. [[ = 'n') 
				AND (i.inc_esc]] .. x .. [[ < ]] .. DATESTR .. [[)]]
			
		Result, err = ASSYSTEJB:sql(SQL)
		if err then
			LOGGER:fatal("Error executing SQL: " .. (err or "??") .. "/nSQL:" .. SQL)
			os.exit(-3)
		end
	
		sNumEsc = ESC_COUNTS[x]
		
--------------------------------------------------------------------------------------
--  Take escalation action and set escalation level for each event
--------------------------------------------------------------------------------------		
		for y = 1, sNumEsc do
			local ok, err = ASSYSTEJB:new_action {
			   actionTypeId = ESC_ACTION_IDS[ESC_ACTION["ESC" .. x]],
			   serviceTime = {duration = tonumber(1000)},
			   serviceCost = {double = tonumber(2)},
			   eventId = tonumber(Result.ESC_EVENT_ID[y]),
			   remarks = "SLA escalation level reached.",
			}
			if ok then
			   strERRMSG = "Successfully added SLA Escalation action " .. ESC_ACTION["ESC" .. x] .. " on incident_id " .. Result.ESC_EVENT_ID[y] .. " in assyst. Action Ref: " .. ok
			   LOGGER:info(strERRMSG)
			else
				ACT_ERR = stringify(err)
				strERRMSG = "Failed to add SLA Esclation action " .. ESC_ACTION["ESC" .. x] .. " on incident_id " .. Result.ESC_EVENT_ID[y] .. " in assyst: " ..(ACT_ERR or "??")
				LOGGER:fatal(strERRMSG)
				os.exit(-3)
			end
			
			--------
			-- Update inc_data table to indicate escalation level
			--------
			SQL = [[UPDATE inc_data 
							set intesc]] .. x .. [[= 'y' 
							where incident_id = ]] .. Result.ESC_EVENT_ID[y]
			Result2, err = ASSYSTEJB:sql(SQL)
			if err then
				LOGGER:fatal("Error executing SQL: " .. (err or "??") .. "/nSQL:" .. SQL)
				os.exit(-3)
			end		
		end
	end
end

LOGGER:info("......" .. strUtilityName .. " Complete......")