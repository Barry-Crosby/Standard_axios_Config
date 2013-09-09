--------------------------------------------------------------------------------------
--- BaseConfigDB.lua generic db connection
--------------------------------------------------------------------------------------

require "db"

-- DB CONNECION INFO - DO NOT EDIT
if strassystDBType:lower() == "oracle" then
	db {
		dbtype = strassystDBType,
		interface = strDBInterface,
        name      = strassystDBName,	
        user      = strassystUserSM,	
        password  = strassystPWSM,		
	}
else
	db {
		dbtype = strassystDBType,
		interface = strDBInterface,
		server    = strassystDBServer,	
        name      = strassystDBName,	
        user      = strassystUserSM,	
        password  = strassystPWSM,		
	}
end

if not DB:is_connected() then
	ok, err = DB:connect()
	if err then 
		LOGGER:fatal("Stopping " .. (strUtilityName or "unknown script") .. ", Database connection error: " .. (err or "??"))
		os.exit(-3)
	end
end
