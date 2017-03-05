local moduleInfo = {
	name 	= "attach",
	desc	= "modules and files loader",
	author 	= "PepeAmpere",
	date 	= "2016/01/01",
	license = "notAlicense",
}

newAttach = {
	["File"] = function(filePath, logRule, techName)
		if (VFS.FileExists(filePath)) then
			local VFSMODE = VFS.ZIP_ONLY
			VFS.Include(filePath, nil, VFSMODE)
			return true
		else
			local prefix = ""
			if (techName ~= nil) then prefix = "[" .. techName .. "] " end
			
			if (logRule == nil or logRule == "ERROR") then 
				Spring.Echo(prefix .. "ERROR: Attempt to load not existing file: " .. tostring(filePath))
				return false 
			end
			if (logRule == "WARNING") then 
			 	Spring.Echo(prefix .. "WARNING: Attempt to load not existing file: " .. tostring(filePath))
				return false 
			end
			if (logRule == "INFO") then 
				Spring.Echo(prefix .. "INFO: Optional file does not exist: " .. tostring(filePath))
				return false 
			end
			if (logRule == "NOTHING") then 
				return false 
			end
		end
	end,
	["Module"] = function(modulesData, moduleName)
		local thisModuleData = modulesData[moduleName]
		if (thisModuleData == nil) then
			Spring.Echo("ERROR: Attempt to load not defined module [" .. moduleName .. "]. Check [modules] table definition.")
			return false
		else
			local someFail = false
			if (thisModuleData.data == nil) then
				Spring.Echo("ERROR: Attempt to load not defined module.data for module [" .. moduleName .. "]. Check [modules] table definition.")
				someFail = true
			end
			if (thisModuleData.data.path == nil) then
				Spring.Echo("ERROR: Attempt to load not defined module.data.path for module [" .. moduleName .. "]. Check [modules] table definition.")
				someFail = true
			end
			if (thisModuleData.data.head == nil) then
				Spring.Echo("ERROR: Attempt to load not defined module.data.head for module [" .. moduleName .. "]. Check [modules] table definition.")
				someFail = true			
			end
			
			if (not someFail) then
				return attach.File(thisModuleData.data.path .. thisModuleData.data.head)
			else
				return false
			end
		end		
	end,	
	["try"] = {
		["File"] = function(filePath, techName)
			return attach.File(filePath, "NOTHING", techName)
		end,
		["ModuleOptionalConfigs"] = function(moduleConfigPath, listOfFiles, techName)
			if (moduleConfigPath ~= nil) then -- try to load all expected configs
				for index, fileName in pairs(listOfFiles) do
					local currentFilePath = moduleConfigPath .. fileName
					attach.try.File(currentFilePath, techName)
				end
			end
		end,
	},
}

-- END OF MODULE DEFINITIONS --

-- update global tables 
if (attach == nil) then attach = {} end
for k,v in pairs(newAttach) do
	if (attach[k] ~= nil) then Spring.Echo("NOTIFICATION: Attempt to rewrite global table in module [" .. moduleInfo.name ..  "] - key: " .. k) end
	attach[k] = v 
end

