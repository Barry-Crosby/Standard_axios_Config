--------------------------------------------------------------------------------------
-- Archive_Utility.lua
-- Prepared for AGS SmartMail Quick Config (Version 3.0)
--
-- This script is not supported by Axios Systems. The script is provided as is and Axios Systems
-- accepts no responsibility or liability for the consequences of using this script.
--
-- This script is called by the Escalations.lua file when Smartmail is run
-- It updates the escalation levels on events and will take an Action. The Action  
-- must be defined in assyst. The action job could be used to send emails.
--
--------------------------------------------------------------------------------------
-- set up environemnt
LOGGER:info("...... Starting " .. strUtilityName .. "....")

FileDir = strArchivePath
ArchDir = strArchivePath .."Archive\\"

FileList = {
	"*.err",
	"*.out",
	"*.red",
	"*.dat",
	"*.autodatprocessed",
	}

LOGGER:info ("Archiving files from " .. (FileDir or "") ..  " to " .. (ArchDir or ""))
	
-- Archive / move log file and related files
for i, moveFile in ipairs(FileList) do
		archive_cmd = "move \"" .. FileDir .. moveFile .. " \" \"" .. ArchDir .. "\""
		LOGGER:debug("archive_cmd DIFF: " .. archive_cmd )
		ok,err = os.execute(archive_cmd)
		LOGGER:debug(err or "OK")
end

-- Remove files that are older than the ARCHIVEDAYS defined above
DelDays = tonumber(ARCHIVEDAYS)*24*60*60

LOGGER:info ("Deleting files over " .. ARCHIVEDAYS .. " days old from " .. ArchDir)
if (ArchDir and DelDays) then
	testDate =os.time() 
	for file in lfs.dir(ArchDir) do
		if file ~= "." and file ~= ".." then
			local f = ArchDir .. file
			fDate = lfs.attributes(f).modification
--				LOGGER:debug("DATE DIFF: " .. testDate .. " File: " .. f .. "  Date: " .. fDate )
			if ARCHIVEDAYS == 0 then
				os.remove(f)
			elseif testDate - fDate > DelDays then
				LOGGER:debug("Deleting file: " .. f)
				ok,err = os.remove(f)
				LOGGER:debug(err or "OK")
			end
		end
	end
end


LOGGER:info("...... " .. strUtilityName .. " Complete .......")