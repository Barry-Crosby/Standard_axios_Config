html_indx = {}
function find_lua_variables(strLine3)
	indx = 0
	tmpString, tmpString2, tmpStr2  = "", "", ""
	start_indx, end_indx = 0, 0
	strLine2 = strLine3
	for s =1, cntr do --in f_handler:lines() do 
		start_indx = string.find(strLine2, "<@PE@", indx)
		if start_indx then
			end_indx = string.find(strLine2, "@P@>", start_indx)
			tmpString = string.sub(strLine2, start_indx + 5, end_indx - 1)
				if tmpString then 	-- find any quoted strings and change to non escape quotes
					tmpString2, err = string.gsub(tmpString, "@Q@", "@QQ@")
				end
			tmpStr2 = "<@PE@" .. tmpString .. "@P@>" 
			strLine2, err = string.gsub(strLine2, tmpStr2, "@QQ@ .. @LP@" .. tmpString2 .. "@RP@ .. @QQ@")
			indx = end_indx + 1
		end
	end
end

function find_lua_functions(strLine3)
	indx = 0
	tmpString, tmpString2, tmpStr2  = "", "", ""
	start_indx, end_indx = 0, 0
	strLine2 = strLine3
	for s =1, cntr do --in f_handler:lines() do 
		start_indx = string.find(strLine2, "<@P@", indx)
		if start_indx then
			end_indx = string.find(strLine2, "@P@>", start_indx)
			tmpString = string.sub(strLine2, start_indx + 4, end_indx - 1)
				if tmpString then 	-- find any quoted strings and change to non escape quotes
					tmpString2, err = string.gsub(tmpString, "@Q@", "@QQ@")
				end
			tmpStr2 = "<@P@" .. tmpString .. "@P@>" 
			strLine2 = string.gsub(strLine2, "@P@>%s*<@P@", " ")
			if string.find(strLine2, "@P@>%s*" .. tmpStr2 .. "%s*<@P@") then
				strLine2, err = string.gsub(strLine2, tmpStr2,  tmpString2)			
			elseif string.find(strLine2, "@P@>%s*" .. tmpStr2) then
				strLine2, err = string.gsub(strLine2, tmpStr2, tmpString2 .. "showHTML = showHTML .. @QQ@")
			elseif string.find(strLine2, tmpStr2 .. "%s*<@P@") then
				strLine2, err = string.gsub(strLine2, tmpStr2, "@QQ@" .. tmpString2)
			else
				strLine2, err = string.gsub(strLine2, tmpStr2, "@QQ@" .. tmpString2 .. "showHTML = showHTML .. @QQ@")
			end
		indx = end_indx 
		end
	end
	strLine4 = strLine2
end


function SMEXT_get_html(H_file)
H_file = strPathToTemplates .. "includes/" .. H_file
	f_handler, err = io.open(H_file,"r")
	strLines, showHTML = "", ""
	cntr = 0
	for strLineIn in f_handler:lines() do
		strLine = string.gsub(strLineIn, "\"", "@Q@")   -- replace quotes
		strLine = string.gsub(strLine, "%s*<", "<")		-- replace leading white space before opening tag
		strLine = string.gsub(strLine, "%s*\n", "")		-- replace crlf
		strLine = string.gsub(strLine, "%(", "@LP@")	-- replace left parantheses
		strLine = string.gsub(strLine, "%)", "@RP@")	-- replace right parantheses
		strLine = string.gsub(strLine, "%[", "@LB@")	-- replace left bracket
		strLine = string.gsub(strLine, "%]", "@RB@")	-- replace right bracket
		strLine = string.gsub(strLine, "<%%=", "<@PE@") -- replace <%=
		strLine = string.gsub(strLine, "<%%", "<@P@") -- replace <%
		strLine = string.gsub(strLine, "%%>", "@P@>")	-- replace %>
		strLines = strLines .. strLine
		cntr = cntr + 1
	end
	-- find lua variables tagged by  <%=  %>
	find_lua_variables(strLines)
	-- find lua functions tagged by <%  %>
	find_lua_functions(strLine2)

	-- put all the pieces back into Lua format
		strLine = string.gsub(strLine2, "@Q@", "\\\"" )   -- replace quotes
		strLine = string.gsub(strLine, "@QQ@", "\"" )   -- replace quotes
		strLine = string.gsub(strLine, "<@PE@", "<%%=") -- replace <%=
		strLine = string.gsub(strLine, "<@P@", "<%%") 	-- replace <%
		strLine = string.gsub(strLine, "@P@>", "%%>")	-- replace %>
		strLine = string.gsub(strLine, "@RP@", "%)")	-- replace right parantheses
		strLine = string.gsub(strLine, "@LP@", "%(")	-- replace left parantheses
		strLine = string.gsub(strLine, "@RB@", "%]")	-- replace right bracket
		strLine = string.gsub(strLine, "@LB@", "%[")	-- replace left bracket
		strLine2 = strLine

	strLines = "showHTML = \"" .. strLine2 .. "\""
	loadstring(strLines)()
	return showHTML
end

