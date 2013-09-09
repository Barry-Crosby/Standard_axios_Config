--------------------------------------------------------------------------------------
-- Survey Utility.lua
-- Prepared for AGS SmartMail Quick Config (Version 5.0)
--
-- This script is not supported by Axios Systems. The script is provided as is and Axios Systems
-- accepts no responsibility or liability for the consequences of using this script.
--
--------------------------------------------------------------------------------------

LOGGER:info("...... Starting " .. strUtilityName .. " ...... Database: " .. strassystDBName)


---  Get count of open surveys
SQL = [[
	SELECT count(surv_req_id) "OPEN_SURVEY_COUNT" 
		FROM surv_req
		WHERE resp_type <> 'c'
		AND resp_type <> 'i']]

Result, err = ASSYSTEJB:sql(SQL)
if err then
	LOGGER:fatal("Error executing SQL: " .. (err or "??") .. "/nSQL:" .. SQL)
	os.exit(-3)
else
	StartingCount = Result.OPEN_SURVEY_COUNT[1]
end


if string.upper(strassystDBType) == "SQLSERVER" then
	DATE_CLAUSE = " WHERE issued_date < " .. DATESTR .. " - 14 "
else
	DATE_CLAUSE = " WHERE issued_date < TRUNC(" .. DATESTR .. ") - 14 "
end

SQL = [[
	UPDATE surv_req
	SET modify_id = 'SQL UPDATE',
		modify_date =  ]] .. DATESTR .. [[, 
		resp_date = ]] .. DATESTR .. [[, 
		resp_type= 'i', 
		response_1 = 0, 
		response_2 = 0,
		response_3 = 0, 
		response_4 = 0, 
		response_5 = 0, 
		comments = 'Survey over 2 weeks old auto ignored'
		]] .. DATE_CLAUSE .. [[
		AND resp_type <> 'c'
		AND resp_type <> 'i']]

Result, err = ASSYSTEJB:sql(SQL)
if err then
	LOGGER:fatal("Unable to ignore old surveys. Error executing SQL: " .. (err or "??") .. "/nSQL:" .. SQL)
	os.exit(-3)
end

SQL = [[
	SELECT count(surv_req_id) "OPEN_SURVEY_COUNT" 
		FROM surv_req
		WHERE resp_type <> 'c'
		AND resp_type <> 'i']]
		
Result, err = ASSYSTEJB:sql(SQL)
if err then
	LOGGER:fatal("Unable to count surveys. Error executing SQL: " .. (err or "??") .. "/nSQL:" .. SQL)
	os.exit(-3)
else
	EndingCount = Result.OPEN_SURVEY_COUNT[1]
end

LOGGER:info("...... Survey Utility Complete.  Surveys marked ignored: " .. (StartingCount - EndingCount) .. " ......")