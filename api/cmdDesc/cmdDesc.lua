local moduleInfo = {
	name 	= "cmdDesc",
	desc	= "Library for interaction with commands descriptions", 
	author 	= "PepeAmpere",
	date 	= "2015/08/12",
	license = "MIT",
}

local spFindUnitCmdDesc = Spring.FindUnitCmdDesc
local spInsertUnitCmdDesc = Spring.InsertUnitCmdDesc
local spEditUnitCmdDesc = Spring.EditUnitCmdDesc
local spRemoveUnitCmdDesc = Spring.RemoveUnitCmdDesc

newCmdDesc = {
	["Add"] = function(unitID, cmdDefDesc, initState)
		local thisCmdDescription = cmdDefDesc
		if (spFindUnitCmdDesc(unitID, cmdDefDesc.id)) then
			return false -- already exists
		end

		local insertID = 123456 -- back of the pack 
		cmdDefDesc.params[1] = initState
		spInsertUnitCmdDesc(unitID, insertID + 1, cmdDefDesc)

		return true
	end,
	["UpdateButton"] = function(unitID, cmdDefDesc, statusString)
		local cmdDescID = spFindUnitCmdDesc(unitID, cmdDefDesc.id)
		if (cmdDescID == nil) then
			return false -- does not exist
		end

		cmdDefDesc.params[1] = statusString
		spEditUnitCmdDesc(unitID, cmdDescID, { 
			params 	= cmdDefDesc.params, 
			tooltip = cmdDefDesc.tooltip,
		})

		return true
	end,
	["Remove"] = function(unitID, cmdDefID)
		local cmdDescID = spFindUnitCmdDesc(unitID, cmdDefID)
		if (cmdDescID ~= nil) then
			spRemoveUnitCmdDesc(unitID, cmdDescID)
			return true
		end

		return false -- does not exist
	end,			
}

-- END OF MODULE DEFINITIONS --

-- update global tables 
if (cmdDesc == nil) then cmdDesc = {} end
for k,v in pairs(newCmdDesc) do
	-- if (cmdDesc[k] ~= nil) then Spring.Echo("NOTIFICATION: Attempt to rewrite global table in module [" .. moduleInfo.name ..  "] - key: " .. k) end
	cmdDesc[k] = v 
end