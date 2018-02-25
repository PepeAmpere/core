local moduleInfo = {
	name 	= "stringExt",
	desc 	= "string functions extension",
	author 	= "PepeAmpere",
	date 	= "2015/12/29", -- re-founded library from 2013
	license = "MIT",
}

-- in all functios the table call of core string functions is replaced by method-call to get maximum performance

---
-- stringExt
-- string functions extension
--
-- @module stríngExt
local newStringExt = {
	---
	-- Split source into array of strings based on separatorPattern
	--
	-- @function [parent=#stríngExt] SplitString
	-- @param #string source String which has to be separated into pieces
	-- @param #string separatorPattern Pattern string which is separation marker
	-- @return #table Array of separated pieces	
	["SplitString"] = function(source, separatorPattern)
		local tableOfResults = {}
		local resultsCount = 1
		local fPattern = "(.-)" .. separatorPattern
		local currentEndPos = 1
		local start, ending, captured = source:find(fPattern, 1)
		while start do
			if start ~= 1 or captured ~= "" then
				tableOfResults[resultsCount] = captured
				resultsCount = resultsCount + 1
			end
			currentEndPos = ending + 1
			start, ending, captured =  source:find(fPattern, currentEndPos)
		end
		if currentEndPos <= #source then
			captured = source:sub(currentEndPos)
			tableOfResults[resultsCount] = captured
			resultsCount = resultsCount + 1
		end
		return tableOfResults		
	end,

	---
	-- Delete all spaces in given source string
	--
	-- @function [parent=#stríngExt] CleanSpaces
	-- @param #string source String where all spaces should be deleted
	-- @return #string String without spaces
	["CleanSpaces"] = function(source)
		return source:gsub("%s+", "")
	end,
	
	---
	-- Replace all spaces in given source string by another string
	--
	-- @function [parent=#stríngExt] ReplaceSpaces
	-- @param #string source String where all spaces should be replaced
	-- @param #string replacement String which is put there instead of every removed space
	-- @return #string String with all replacements done
	["ReplaceSpaces"] = function(source, replacement)
		return source:gsub("%s+", replacement)
	end,
	
	---
	-- Replace all matches of given pattern in given sourc string by replacement string
	--
	-- @function [parent=#stríngExt] ReplaceString
	-- @param #string source Source string where replacements should be done
	-- @param #string pattern Pattern we search for
	-- @param #string replacement Replacement for every founded item
	-- @return #string String with all replacements done
	["ReplaceString"] = function(source, pattern, replacement)
		return source:gsub(pattern, replacement)
	end,
	
	---
	-- Make URL-suffix from given sentence
	--
	-- @function [parent=#stríngExt] MakeLink
	-- @param #string source Source string which should be processed
	-- @return #string Procesed string ready to be URL-suffix
	["MakeLink"] = function(source)
		local newLink = stringExt.ReplaceString(source, "%s+-%s+", "-")
		return stringExt.ReplaceSpaces(newLink, "-")
	end,
}

-- END OF MODULE DEFINITIONS --

-- update global tables 
if (stringExt == nil) then stringExt = {} end
for k,v in pairs(newStringExt) do
	-- if (stringExt[k] ~= nil) then Spring.Echo("NOTIFICATION: Attempt to rewrite global table in module [" .. moduleInfo.name ..  "] - key: " .. k) end
	stringExt[k] = v 
end
