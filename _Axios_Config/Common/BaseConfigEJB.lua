--------------------------------------------------------------------------------------
--- BaseConfigEJB.lua contains standard settings to support the use of EJB calls
--------------------------------------------------------------------------------------
-- Change log
-- 04/26/2012	Initial version of file
--------------------------------------------------------------------------------------

-- set up environment
require "assystEJB"
assystEJB {	url = strEJBUrl,}

if ((BypassLoggingEnvironment or "") ~= "y") then
	-------------------------------------------------------------------------------------
	--
	-- set up environemnt
	--
	--------------------------------------------------------------------------------------
	require "lfs"
	require "logging.file"
	local LogDir = lfs.currentdir() .. "\\Logs"
	local LogFile = (LOG_FILE or "ProcessingLog.txt")
	ChgDir,err = lfs.chdir(LogDir)
		if not ChgDir then
			MkDir, err = lfs.mkdir(LogDir)
			if not MkDir then 
				os.exit(-2) 
			else
				print("Directory " .. LogDir .. " created")
			end
		else 
			ChgDir,err = lfs.chdir("..")
		end
	LOGGER = logging.file(LogDir .. "\\" .. LogFile)
	LOGGER:setLevel(string.upper(LOG_LEVEL or "INFO"))  -- ERROR, WARN, INFO, DEBUG
end
--------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------
--
-- General function to get the ID based on a lookup
--
--------------------------------------------------------------------------------------
function get_id(sTable, sSC, failonerror)

	id, err = ASSYSTEJB:lookup_id(sTable, sSC )
	if err then
		if failonerror then
			LOGGER:fatal("Error looking up ID.  Table: " .. (sTable or "") .. ", LookupSC: " .. (sSC or "") .. ", Error: " .. (err or "??"))
			os.exit(-3)
		else
			id = -1
		end
	end
	
	return id

end
