local moduleInfo = {
	name 	= "actionTypes",
	desc	= "Action types definition. Independent module.", 
	author 	= "PepeAmpere", -- based on tsp_actions.lua from OTE
	date 	= "2015/08/07",
	license = "MIT",
}

--[[ 
UNIVERSAL MODULE

main criteria is to keep this module as most as universal - this mean that:
	1) here should be no game-related reference like specific unitDefName, unitID, function set, etc.
	2) we should avoid to reference (include) functionality of modules which are part of different technology (except module `message`) 
	and use messages to communicate with other modules
	3) expected message receiver (module name) should be explicitly mentioned in comment 
]]--

local spCreateUnit 			= Spring.CreateUnit
local spGetGroundHeight 	= Spring.GetGroundHeight
local spGetUnitPosition 	= Spring.GetUnitPosition
local spGetUnitsInArea 		= Spring.GetUnitsInArea
local spGetUnitsInSphere 	= Spring.GetUnitsInSphere
local spGiveOrderToUnit 	= Spring.GiveOrderToUnit
local spTransferUnit 		= Spring.TransferUnit

local CMD_ATTACK 			= CMD.ATTACK
local CMD_MOVE				= CMD.MOVE
local CMD_GUARD 			= CMD.GUARD

local newActionTypes = {
	["Teleport"] = {
		["Unit"] = function()
		end,
	},
	["Jumpjet"] = function()
	end,
	["Airstrike"] = {
		["Simple"] = function(position, planeUnitDefID, ownerTeamID, spawnPosition, spawnHeading, leavePosition)
			-- position 		- 3D vector - target position
			-- planeUnitDefID 	- number	- unitDefID
			-- ownerTeamID 		- number 	- teamID
			-- spawnPosition 	- 3D vector - (optional) position of spawn - where from the unit fly
			-- spawnHeading 	- string 	- (optional) heading of spawned unit
			-- leavePosition 	- 3D vector - (optional) position where unit leave the game
			
			-- use optional parameters or defaults
			local newSpawnPosition = spawnPosition or {0, spGetGroundHeight(0, 0) + 150, 0}
			local newLeavePosition = leavePosition or {0, spGetGroundHeight(0, 0) + 150, 0}
			local newSpawnHeading = spawnHeading or "s"
			-- TBD replace by spawn speed vector which will consist vector implicitly and there will be instant rotation after spawn
			
			-- TBD maybe replace direct spawn by reference
			local planeID = spCreateUnit(planeUnitDefID, newSpawnPosition[1], newSpawnPosition[2], newSpawnPosition[3], newSpawnHeading, ownerTeamID) -- spawn airplane unit
			spGiveOrderToUnit(planeID, CMD_ATTACK, position, {"shift"}) -- attack order to plane to given position
			spGiveOrderToUnit(planeID, CMD_MOVE, newLeavePosition, {"shift"}) -- plane flies away
			-- TBD destroy plane
			
			return true
		end,
	},
	["Spawn"] = {
		["AssistUnit"] = function(targetOfAssistance, ownerTeamID, assistUnitDefName)
			-- targetOfAssistance 	- number 	- unitID
			-- ownerTeamID 			- number	- teamID
			-- assistUnitDefName 	- string 	- unitDefName
		
			local targetPosX, targetPosY, targetPosZ = spGetUnitPosition(targetOfAssistance) -- get pos of targetOfAssistance
			local assistUnitID = spCreateUnit(assistUnitDefName, targetPosX, targetPosY + 50, targetPosZ, "s", ownerTeamID) -- create assist unit
			spGiveOrderToUnit(assistUnitID, CMD_GUARD, {targetOfAssistance}, {}) -- start assistance

			return true
		end,
		["One"] = function(unitDefName, position, ownderTeamID, heading)
			-- unitDefName 	- string 		- unitDefName
			-- position		- 3D vector 	- position of spawn
			-- ownerTeamID 	- number		- teamID		
			-- heading 		- number/string	- (optional) heading direction
			
			local newSpawnHeading = heading or "s"
			
			spCreateUnit(unitDefName, position[1], position[2], position[3], newSpawnHeading, ownderTeamID)
		end,
		["Complex"] = function(unitDefName, position, ownderTeamID, count, formationDef, formationHeading, formationScales, notOnSurface)
			-- unitName 			- string 		- unitDefName
			-- position				- 3D vector 	- position of spawn
			-- ownerTeamID 			- number		- teamID		
			-- count 				- number 		- (optional) number of units to spawn
			-- formationDef 		- array of 3D vectors - (optional) formation of spawned items
			-- formationHeading		- number 		- (optional) heading in degrees
			-- formationScales		- 3D vectors 	- (optional) multipliers in (mainly) X and Z directions
			-- notOnSurface 		- bool 			- (optional) Y is not based on surface height, its based on input vector + formation + scales
			
			swarmFormation2D = {
				[1]  = {0,0},		[2]  = {9,-1},		[3]  = {2,-8},		[4]  = {-5,-7},		[5]  = {-10,4},
				[6]  = {1,10},		[7]  = {12,9},		[8]  = {16,-2},		[9]  = {12,-11},	[10] = {1,-17},
				[11] = {-8,-16},	[12] = {-15,-3},	[13] = {-15,10},	[14] = {-5,18},		[15] = {8,19},
				[16] = {21,13},		[17] = {25,2},		[18] = {21,-10},	[19] = {6,-20},		[20] = {-4,-22},
				[21] = {-17,-7},	[22] = {-22,2},		[23] = {-15,20},	[24] = {3,26},		[25] = {18,23},
				[26] = {29,10},		[27] = {28,-7},		[28] = {21,-20},	[29] = {5,-27},		[30] = {-13,-24},
			} -- TEMPORARY FORMATION DEFINITION
			
			-- temporary defaults
			local temporaryHeading = "n"
			local formationScales = formationScales or {1, 1, 1}
			
			for i=1, count do
				local finalX = position[1] + swarmFormation2D[i][1] * formationScales[1]
				local finalZ = position[3] + swarmFormation2D[i][2] * formationScales[3] -- ! current 2D formation have only 2 values
				spCreateUnit(unitDefName, finalX, spGetGroundHeight(finalX, finalZ), finalZ, temporaryHeading, ownderTeamID) -- ! curently on suface
			end
		end,
		["BySpawner"] = function()
		end,
	},
}

-- END OF MODULE DEFINITIONS --

-- update global tables 
if (actionTypes == nil) then actionTypes = {} end
for k,v in pairs(newActionTypes) do
	-- if (actionTypes[k] ~= nil) then Spring.Echo("NOTIFICATION: Attempt to rewrite global table in module [" .. moduleInfo.name ..  "] - key: " .. k) end
	actionTypes[k] = v 
end