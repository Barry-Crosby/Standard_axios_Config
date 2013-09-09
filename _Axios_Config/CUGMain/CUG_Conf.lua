---  Start of standard configuration
BASE_FOLDER = "\\_Axios_Config\\"
dofile(BASE_FOLDER .. "Common\\BaseConfig.lua")        -- load Lua environment variables

global {
     loglevel = INFO,
     max_fail_to_good_ratio = 0.5,
     max_fail_count = 300,
}

assyst {
     version = "9.0SP2",
     dbtype = strassystDBType,
     interface = strDBInterface,
     server = strassystDBServer,
     name = strassystDBName,
     user = strassystUserCUG,
     password = strassystPWCUG,
     acli = straclipath,
}

csv {

	file = "\\_Axios_Config\\ImportFiles\\ImportFilesReady\\UserData.txt",					  
	attributes = { "UniqueIdentifier", "LANID", "JobTitle", "CostCentre", "Organization", "Location", "EMailAddr", 
						"Telephone", "FirstName", "MiddleInitial", "LastName", "VIPFlag", "Extension", "WorkMobile", 
						"Manager", "JobCode", "EmployeeStatus" }, 
	header = false,
}

function record_result(sMessage)

	outfile:write(sMessage .. "\n")

end

-- Initialize Data Issues File
	outfile, err = io.open("/_Axios_Config/CUGMain/CUGdataissues.csv", "a")
	if err then error("File open failed. Error message: " .. (err or "?")) end

	record_result("Message,UserSC,User Name,Field,Input Value,Default Value Used")

usr {
	KEY = [[ UniqueIdentifier ]],

	usr_sc = [[ LANID ]],
					
	usr_n = [[ 	format_name(LastName, FirstName, MiddleInitial, UniqueIdentifier) ]],
	
	usr_role_sc = [[ check_sc(upper(JobTitle), "NOT USED", "usr_role_sc", LANID, LastName) ]],
	sectn_dept_sc = [[ check_sc(upper(concat( Organization, "-" )), "UNKNOWN-", "sectn_dept_sc", LANID, LastName) ]],
	bldng_room_sc = [[ check_sc(upper(concat( Location, "-" )), "UNKNOWN-", "bldng_room_sc", LANID, LastName) ]],
	--cost_centre_sc =  [[ check_sc(CostCentre, "UNKNOWN", "cost_centre_sc", LANID, concat(LastName, "Cost Center: ", CostCentre)) ]],
	--internal_id = not used
	--staff_no = not used
	tele = [[ Telephone ]],
	ext = [[ Extension ]],
	email_add = [[ EMailAddr ]],

	contact_mail = no_update [[ "y" ]],
	contact_tele = no_update [[ "y" ]],
	contact_print = [[ VIPFlag ]],
	anet_login =  [[ "CU-" .. LANID ]],
    net_pswd = no_update [[ "xx"]],
    usr_alias_sc = no_update [[ "ZANET" ]],
	anet_licence = no_update [[ "n" ]],
	licence_role_sc = no_update [[ "STANDARD USER" ]],

	--docket_type_sc = not used 
	first_name = [[ (FirstName or "") ]],
	middle_name = [[ (LastName or "") ]],
	usr_flag1 = [[ (JobCode or "") ]],
	--usr_flag2 = not used 
	
    line_manager_sc = [[ -- change empty string to nil
            if (manager or "") == "" then 
                return nil 
            else 
				manager_check = check_sc(upper(manager), "", "line_manager_sc", LANID, concat(LastName, "Manager: ", Manager))
				if ((manager_check or "") == "") then
					return nil
				else
					return manager_check
				end
            end ]],
			
	stat_flag = [[ discontinue_map(EmployeeStatus) ]],
}


maps {

	discontinue_map = {

		-- an active setting other than A is taken to mean discontinued,
		-- anything else is active

		"y",
		["A"] = "n",
	},

}

transforms{
	
	format_name = function(firstname, lastname, middleinitial, uniqueid)
	
		tempname = concat( LastName, ", ", FirstName, " ", MiddleInitial)
		
		if (left(uniqueid,3) or "") == "Con" then
			tempname = tempname .. " (Consultant)"
		end
		
		return tempname
	
	end,
	
	-----------------------------------------------------------------
	--  Check to see that a short code exists and if not log a message and return default
	-----------------------------------------------------------------
	check_sc = function (sc_test, default_value, field, user_sc, name)
		if (sc_test or "") == "" then
			good_sc = default_value
			record_result("Lookup missing - default used," .. (user_sc or "") .. "," .. (name or "") .. "," .. (field or "") .. "," .. (sc_test or "") .. "," .. (default_value or ""))
		else
			if is_valid_lookup(sc_test) then
				good_sc = sc_test
			else
				good_sc = default_value
		 		record_result("Lookup not found," .. (user_sc or "") .. "," .. (name or "") .. "," .. (field or "") .. "," .. (sc_test or "")  .. "," .. (default_value or ""))
			end
		end
		return good_sc
	end,
}