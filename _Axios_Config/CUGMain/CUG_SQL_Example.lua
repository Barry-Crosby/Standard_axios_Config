
--- Insert the following after the assyst definition.

ASSYST:connect()

COST_CENTER, err = ASSYST:multi_row_sql ([[
	select cost_centre_sc COST_CENTER_SC, cost_centre_n COST_CENTER_NAME
	from cost_centre
	where stat_flag = 'n'
	and cost_centre_id > 0
]])

ASSYST:disconnect()

function load_data_from_sql()
	COST_CENTER_LOOKUP = {}
	
	for cnt, usr_n in ipairs(COST_CENTER.COST_CENTER_SC) do
		COST_CENTER_LOOKUP[cost_centre_n] = COST_CENTER.COST_CENTER_SC[cnt]
	end	
end

load_data_from_sql()

-- Clear SQL resultsets
COST_CENTER.COST_CENTER_SC, COST_CENTER.COST_CENTER_NAME = nil, nil

--- CSV or LDAP section goes here

--- Example usage within a usr function

cost_centre_sc = [[
		if COST_CENTER_LOOKUP[department] then
			return COST_CENTER_LOOKUP[department]
		else
			return nil
		end
	]],
