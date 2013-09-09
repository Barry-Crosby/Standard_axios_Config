----------------------------------------------------------------------------
-- 2012-08-20 Clear error level at start of import function to avoid false errors
----------------------------------------------------------------------------

-- set some global variables:
td_ext = os.date("%Y%m%d%H%M%S")
ziplogfiles = "..\\Logs\\acli_files_" .. td_ext .. ".zip"
UtilityDir = UtilityDir or lfs.currentdir() .. "\\"

-- common function to create write out the ACLI formatted
-- file that ACLI will process
function create_acli_import_file(dataString, FileName)
	local acli_import_file = FileName
	local IMP_HDR = io.open(acli_import_file, "a")
	if not IMP_HDR then
		print("Error opening import file " .. (FileName or "??"))
		LOGGER:warn("Error opening import file")
		WARNINGS_ENCOUNTERED = true
	else
		LOGGER:debug("Creating Import File: " .. FileName)
		print("Creating Import File: " .. FileName)
		IMP_HDR:write(string.format(dataString))
		IMP_HDR:close()
	end
end

function get_ACLI_cmd(strFile)

	FileChk, err = lfs.attributes(straclipath,"size")
	if err then 
		LOGGER:fatal("-- Invalid entry in BaseConfig.lua for ACLI path (straclipath): " .. straclipath)
		os.exit(-1)
	end

	if strassystDBType:lower() == "sqlserver" then
		aclicmd = "\"" .. straclipath .. "\"" ..
					" \"-v:" .. strassystDBType .. "\"" ..
					" \"-h:" .. strassystDBServer .. "\"" ..
					" \"-d:" .. strassystDBName .. "\"" ..
					" \"-u:" .. strassystUserSM .. "\"" ..
					" \"-p:" .. strassystPWSM .. "\"" ..
					" \"-t:u\"" ..
					" \"-f:" .. strFile .. "\""
	else
		aclicmd = "\"" .. straclipath .. "\"" ..
					" \"-v:" .. strassystDBType .. "\"" ..
					" \"-h:" .. strassystDBName .. "\"" ..
					" \"-d:" .. strassystDBName .. "\"" ..
					" \"-u:" .. strassystUserSM .. "\"" ..
					" \"-p:" .. strassystPWSM .. "\"" ..
					" \"-t:u\"" ..
					" \"-f:" .. strFile .. "\""
	end
	return aclicmd
end

function run_acli_import_single_with_error_checking(filename)
	
	FileChk, err = lfs.attributes(UtilityDir .. "runacli.bat","size")
	if err then 
		LOGGER:fatal(UtilityDir .. "runacli.bat  was not found. The import cannot run without it (run_acli_import_single(filename)).")
		os.exit(-1)
	end
	
	ACLIcmd = get_ACLI_cmd(filename)

	sCmd = " start " .. UtilityDir .. "runacli.bat " .. SCRIPT_PATH .. "ImportUtility.ini " .. ACLIcmd
	LOGGER:debug(" About to run: " .. sCmd)
	os.execute(sCmd)
	check_acli_processes()
	
	-- look for errors in the corresponding log files
	impErrMSG = ""
	filenamebase = string.sub(filename,string.len(AIM_FOLDER) + 1,string.len(filename)-4)
	
	related_files = {
		filenamebase .. "errline.err", 	-- list of files that will be moved to the archive directory
		filenamebase .. ".err", 
		filenamebase .. ".dat"
	}

	srchCriteria = {
		"ERROR :",
		"FATAL :",
		"FAILURE :",
		"FAIL :",
		"ERROR:",
		"FATAL:",
		"FAILURE:",
		"FAIL:",
	}
	
	haveErrors = false
				
	f_handler, err = io.open(AIM_FOLDER .. filenamebase .. ".out","r")  
	if not(f_handler) then 
		impErrMSG = impErrMSG .. "Failed to open file: " .. AIM_FOLDER .. filenamebase .. ".out. Could not check for errors" .. (err or "?") .. "\n"
	else
		LOGGER:debug("Checking for errors in file: " .. AIM_FOLDER .. filenamebase .. ".out")
		cntnt = gsub(f_handler:read("*all"),"\n"," ")
		--LOGGER:debug(cntnt)

		for i, srchTxt in ipairs(srchCriteria) do
			errCount = 0
			for w in string.gfind(cntnt, srchTxt) do
				errCount = errCount + 1
			end
					
			if errCount > 0 then
				haveErrors = true
				impErrMSG = impErrMSG .. errCount .. " \"" .. srchTxt .. "\" errors in log file " .. filenamebase .. ".out" .. "\n"
			end
		end
		
		if f_handler then io.close(f_handler) end

		machine_name = os.getenv("COMPUTERNAME")
			
		-- if we find one or more errors, then send an email with this log file and other related files
		if haveErrors == true then
			impErrMSG = impErrMSG .. "Errors during import processing of " .. filenamebase.. ", files can be found on " .. machine_name .. " in " .. AIM_FOLDER .. "\n"
			impErrMSG = impErrMSG .. "Command: " .. sCmd .. "\n"
		else
			LOGGER:debug("No Errors found during import of file " .. filename)
			
			-- Move log file and related files to archive folder
			archive_cmd = "move \"" .. AIM_FOLDER .. filenamebase .. ".out" .. "\" \"" .. ARCHIVE_FOLDER .. filenamebase .. ".out"
			LOGGER:debug("Archive command: " .. archive_cmd)
			os.execute(archive_cmd)
			for i, add_file in ipairs(related_files) do
				archive_cmd = "move \"" .. AIM_FOLDER .. add_file .. "\" \"" .. ARCHIVE_FOLDER .. add_file
				LOGGER:debug("Archive command: " .. archive_cmd)			
				os.execute(archive_cmd)
			end
		end
			
	
	end
	
	if string.len((impErrMSG or "")) > 3 then
		LOGGER:warn(string.rep ("-", 60) .. "\n" .. impErrMSG)
		WARNINGS_ENCOUNTERED = true
	end

end

function run_acli_import_batch(filelist)

local procCntr = 0
	FileChk, err = lfs.attributes(UtilityDir .. "runacli.bat","size")
	if err then 
		LOGGER:fatal(UtilityDir .. "runacli.bat  was not found. The import cannot run without it (function run_acli_import_batch(filelist)).")
		setupERR = true
	end

	for idx, fName in ipairs(filelist) do
	ACLIcmd = get_ACLI_cmd(fName)
		procCntr = procCntr + 1
	LOGGER:debug("Importing file: " .. fName)
	
	os.execute("start ImportUtility.ini ".. UtilityDir .. "runacli.bat " .. ACLIcmd )
	if procCntr == (MAX_ACLI_PROCS or 1) or idx == #filelist then
		check_acli_processes()
		procCntr = 0
	end
		
	end
end


function check_acli_processes()
local sleeptime = 10
	require "socket"	-- For sleep() and gettime()
	sleep = socket.sleep
	procname = "acli.exe"
	proc_found = nil
	repeat 
		print("Checking for end of ACLI process every " .. sleeptime .. " seconds")
		sleep(sleeptime)
		f = assert (io.popen ("echo&&tasklist /SVC | find \"" .. procname .. "\""))
		for line in f:lines() do
			if string.match(line, procname)  then
				print(line)
				proc_found = true
			else
				proc_found = nil
			end
		end -- for loop
		f:close()
	until (proc_found == nil)
	if not proc_found then
		print("Process '" .. procname .. "' not found. Continuing.")
	end
end

function cleanup_env()
-- clean up OS file system by zipping up all ACLI files and putting the zip file in the Log directory
	os.execute("cd \"" .. HOME_DIR .. "\\ACLI\"&&zip " .. ziplogfiles .. " -1 -D -m  *.*")
end

