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


ldap {
	server = "xxx",
	user = "CN=yyy,OU=Netherlands,OU=Consultants,OU=AGS,OU=_Users,OU=Axios,DC=axiossystems,DC=com",
	password = "",



	query = {
		base_dn = {
					"OU=AGS,OU=_Users,OU=Axios,DC=axiossystems,DC=com", 
					
					},
		filter = {
				"(&(objectClass=person))",
				},
			},

	attributes = {
		"objectGUID",
		"sAMAccountName",
		"givenName",
		"sn",
		"cn",
		"title",
		"department",
		"l",
		"telephoneNumber",
		"mail",
		"mobile",
		"manager",
	},
}

mod_ldap_factory {
    id = "SECOND",
    server = "xxx",
    user = "CN=User,OU=Netherlands,OU=Consultants,OU=AGS,OU=_Users,OU=Axios,DC=axiossystems,DC=com",
    password = "",
}
SECOND:connect()


usr {
	KEY = [[ objectGUID ]],

	usr_sc = [[ upper(sAMAccountName) ]],
	usr_n = [[ cn ]],

--	sectn_dept_sc = [[ upper(concat(department, "-")) ]],
	
--	bldng_room_sc = [[ 	]],
--	anet_login = [[ concat("ad_".. sAMAccountName) ]],
	tele = [[ telephoneNumber ]],
	email_add = [[ mail ]],
--	work_mobile = [[ mobile ]],
	first_name = [[ givenName ]],
	salutation = [[ sn ]],

	contact_mail = no_update [[ "y" ]],
	contact_tele = no_update [[ "n" ]],
	contact_print = no_update [[ "n" ]],
	contact_bleep = no_update [[ "n" ]],
	contact_fax = no_update [[ "n" ]],
	line_manager_sc = [[ local lineManager
        if manager and #manager > 0 then
            for dn, attrs in SECOND:search {
                        base = manager, filter = "(objectClass=*)",
                        scope = "base", attrs = { "sAMAccountName" },
                    } do
                if attrs and type(attrs["sAMAccountName"]) == "string" then
                    lineManager = attrs["sAMAccountName"]
                    break
                end
            end
        end
        return ((lineManager) or "")
    ]],
}

