--------------------------------------------------------------------------------------
-- Import_Utility.lua
-- Prepared for AGS SmartMail Quick Config (Version 5.0)
--
-- This script is not supported by Axios Systems. The script is provided as is and Axios Systems
-- accepts no responsibility or liability for the consequences of using this script.
--
--------------------------------------------------------------------------------------
-- 2012-08-20 Update to ensure files are processed in sequence
--------------------------------------------------------------------------------------

LOGGER:info("---- Starting assyst Import Utility ----")

-- initial check that conifguration folders, ACLI, and required files are valid
UtilityDir = UtilityDir or lfs.currentdir() .. "\\"
setupMSG = string.rep("-",60) .. "\n"

dirChk, err = lfs.chdir (HDR_FOLDER)
if err then 
	setupMSG = setupMSG .. "-- Invalid entry in the Configuration file for the Import Header file folder location (HDR_FOLDER). The directory does not exist. \n"
	setupERR = true
end

dirChk, err = lfs.chdir (SOURCE_FOLDER)
if err then 
	setupMSG = setupMSG .. "-- Invalid entry in the Configuration file for the Import Source file location (SOURCE_FOLDER). The directory does not exist.\n"
	setupERR = true
end

dirChk, err = lfs.chdir (AIM_FOLDER)
if err then 
	setupMSG = setupMSG .. "-- Invalid entry in the Configuration file for the Import Target Folder location (AIM_FOLDER). The directory does not exist.\n"
	setupERR = true
end

dirChk, err = lfs.chdir (ARCHIVE_FOLDER)
if err then 
	setupMSG = setupMSG .. "-- Invalid entry in the Configuration file for the Archive Folder location (ARCHIVE_FOLDER). The directory does not exist.\n"
	setupERR = true
end

FileChk, err = lfs.attributes(straclipath,"size")
if err then 
	setupMSG = setupMSG .. "-- Invalid entry in BaseConfig.lua for ACLI path (straclipath).\n"
	setupERR = true
end

FileChk, err = lfs.attributes(UtilityDir .. "runacli.bat","size")
if err then 
	setupMSG = setupMSG .. "-- The file 'runACLI.bat' was not found in the directory '" .. UtilityDir .. "'. The import cannot run without it.\n"
	setupERR = true
end

FileChk, err = lfs.attributes(UtilityDir .. "ImportUtility.ini","size")
if err then 
	setupMSG = setupMSG .. "-- The file 'ImportUtility.ini' was not found in the directory '" .. UtilityDir .. "'. The import cannot run properly without it.\n"
	setupERR = true
end

if setupERR then
	setupMSG = setupMSG .. "Please correct the errors above and then retry the import.\n"
	LOGGER:error(setupMSG)
	os.exit(-2)
end
lfs.chdir (UtilityDir)


-- For each sorce file/header file pair, check if the source and header files are in the configured folders. If not, log a warning and move on.
impErrMSG = ""
for cntr,SOURCE_FILES in ipairs(SOURCE_FILES_LIST) do
-- print(stringify(SOURCE_FILES))
	for src,hdr in pairs(SOURCE_FILES) do
		HDRfileSize, hdrerr = lfs.attributes(HDR_FOLDER .. hdr,"size") -- chk hdr file
		if hdrerr then
			warnMSG_HDR = "Header file '" .. hdr .. " was not found in the folder " .. HDR_FOLDER
			skipImport = true
		end
		SRCfileSize, srcerr = lfs.attributes(SOURCE_FOLDER .. src,"size") -- chk hdr file
		if srcerr then
			warnMSG_SRC = "Source file '" .. src .. " was not found in the folder " .. SOURCE_FOLDER
			skipImport = true
		end
		if skipImport then
			local errMsg = string.rep ("-", 60) .. "\n" .. (warnMSG_HDR or "") .. (warnMSG_HDR and warnMSG_SRC and "\n" or "") .. (warnMSG_SRC or "")
			errMsg = errMsg .. "\nPlease check your SOURCE_FILES_LIST configuration entries or the file names in the source folder.\n"
			LOGGER:warn(errMsg) 
			skipImport = nil
		else
			-- combine the files and then run the import
			importFileBaseName = string.sub(src,1,string.len(src)-4)
			cmd = "copy /B " .. HDR_FOLDER .. hdr .. " + " .. SOURCE_FOLDER .. src .. " " .. AIM_FOLDER .. importFileBaseName .. ".dat"
			os.execute(cmd)
			-- check to see that the file was copied successfully
			IMPfileSize, impfile_err = lfs.attributes(AIM_FOLDER .. importFileBaseName .. ".dat","size")
			if impfile_err then
				impErrMSG = impErrMSG .. "Import file '" .. AIM_FOLDER .. importFileBaseName .. ".dat was not created successfully. Source file " .. src .. " was not imported.\n"
				impfile_err = nil
			else
				-- run ACLI to import the file
				LOGGER:info("Processing: " .. AIM_FOLDER .. importFileBaseName .. ".dat")
				run_acli_import_single_with_error_checking(AIM_FOLDER .. importFileBaseName .. ".dat")
			end
		end
	end
end
	if string.len((impErrMSG or "")) > 3 then
		LOGGER:error(string.rep ("-", 60) .. "\n" .. impErrMSG)
	end

LOGGER:info("---- Ending assyst Import Utility ----")