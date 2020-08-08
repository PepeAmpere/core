local moduleInfo = {
	name = "poi",
	desc = "Point of Interest object and its methods.",
	author = "PepeAmpere",
	date = "2019-01-24",
	license = "MIT",
}

-- defining the metatable and access 
local poi = {}
local poiMeta = {}
poiMeta.__index = poi
poiMeta.__metatable = false -- access

local function New(firstInput, defID, ownerID, layerID, position, heading, edgesOut, edgesIn, customData)
	local ID = firstInput
	if type(firstInput) == "table" then
		-- for anyone creating POI from table
		defID = firstInput.defID
		ownerID = firstInput.ownerID
		layerID = firstInput.layerID
		position = firstInput.position
		heading = firstInput.heading
		edgesOut = firstInput.edgesOut
		edgesIn = firstInput.edgesIn
		customData = firstInput.customData
		ID = firstInput.ID
	end
	return setmetatable(
		{
			-- accessible via API
			ID = ID or -1,
			defID = defID or 0,
			ownerID = ownerID, -- playerID
			layerID = layerID or -1, -- layerID
			position = position, -- Vec3
			heading = heading, -- azimuth in degrees, 0 = north
			edgesOut = edgesOut or {},
			edgesIn = edgesIn or {},
			customData = customData or {},
			
			-- private
			dataType = "POI",
		},
		poiMeta
	)
end

local function Connect(poiA, poiB, edgeData)
	poiA.edgesOut[poiB.ID] = edgeData
	poiB.edgesIn[poiA.ID] = edgeData
	return poiA, poiB
end

local function ConnectInverted(poiA, poiB, edgeData)
	poiA.edgesIn[poiB.ID] = edgeData
	poiB.edgesOut[poiA.ID] = edgeData
	return poiA, poiB
end

local function ConnectBothDirections(poiA, poiB, edgeData)
	poiA.edgesOut[poiB.ID] = edgeData
	poiB.edgesIn[poiA.ID] = edgeData
	poiA.edgesIn[poiB.ID] = edgeData
	poiB.edgesOut[poiA.ID] = edgeData 
	return poiA, poiB
end

local function Disconnect(poiA, poiB)
	poiA.edgesOut[poiB.ID] = nil
	poiB.edgesIn[poiA.ID] = nil
	return poiA, poiB
end

local function DisconnectBothDirections(poiA, poiB)
	poiA.edgesOut[poiB.ID] = nil
	poiB.edgesIn[poiA.ID] = nil
	poiA.edgesIn[poiB.ID] = nil
	poiB.edgesOut[poiA.ID] = nil 
	return poiA, poiB
end

local function DisconnectAll(poiA, pois)
	local pairsToRemove = {}
	for poiID, edgeData in pairs(poiA.edgesOut) do
		pairsToRemove[#pairsToRemove + 1] = {poiA.ID, poiID}
	end
	for poiID, edgeData in pairs(poiA.edgesIn) do
		pairsToRemove[#pairsToRemove + 1] = {poiID, poiA.ID}
	end
	for i=1, #pairsToRemove do
		local firstID = pairsToRemove[i][1]
		local secondID = pairsToRemove[i][2]
		pois[firstID], pois[secondID] = pois[firstID]:Disconnect(pois[secondID])
	end
	return pois, pairsToRemove
end


local function IsConnected(poiA, poiB, edgeData) -- edgeData if not nil has to work on == operator
	local AID = poiA.ID
	local BID = poiB.ID
	local AOut = poiA.edgesOut
	if (AID ~= nil and BID ~=nil and AOut ~= nil) then
		if edgeData ~= nil then
			return AOut[BID] == edgeData 
		else
			return AOut[BID] ~= nil
		end
	end
	return false
end

local POI = New

function poiMeta:__add(poiB) -- poiA -> poiB, directed edge from A to B
	return Connect(self, poiB, 0) -- basic edge
end

function poiMeta:__sub(poiB)
	return Disconnect(self, poiB)
end

function poiMeta:__mul(poiB) -- poiA <-> poiB, edges in both directions between A and B
	return ConnectBothDirections(self, poiB, 0) -- basic edge
end

function poiMeta:__div(poiB) -- poiA 0 poiB, cancel all edges between A and B
	return DisconnectBothDirections(self, poiB)
end

function poiMeta:__eq(poiB)
	return self.ID == poiB.ID
end

function poiMeta:__unm() -- do nothing
	return self
end      

function poi:Connect(poiB, edgeData)
	return Connect(self, poiB, edgeData)
end

function poi:ConnectInverted(poiB, edgeData)
	return ConnectInverted(self, poiB, edgeData)
end

function poi:ConectBothDirections(poiB)
	return self * poiB
end

function poi:Disconnect(poiB)
	return Disconnect(self, poiB)
end

function poi:DisconnectAll(pois)
	return DisconnectAll(self, pois)
end

function poiMeta:__lt(poiB) -- a < b = has b outgoing edge conntecting a?
	return IsConnected(poiB, self)
end

function poi:IsConnected(poiB, edgeData) -- a < b = has b outgoing edge conntecting a?
	return IsConnected(self, poiB, edgeData)
end

function poiMeta:__tostring()
	local edgesOutString = "out:"
	local edgesInString = "in:"
	for id, edgeData in pairs(self.edgesOut) do
		edgesOutString = edgesOutString .. id .. "(" .. tostring(edgeData) ..  "),"
	end
	for id, edgeData in pairs(self.edgesIn) do
		edgesInString = edgesInString .. id .. "(" .. tostring(edgeData) ..  "),"
	end
	return 	"POI(ID=" .. tostring(self.ID) ..
		",defID=" .. tostring(self.defID) ..
		",ownerID=" .. tostring(self.ownerID) ..
		",pos=" .. tostring(self.position) .. "," .. 
		edgesOutString .. edgesInString .. 
		")"
end

function poiMeta:__concat()
	return tostring(self)
end

function poi:GetDistance(poiB)
	return (self.position):Distance(poiB.position)
end

function poi:GetID()
	return self.ID
end

function poi:SetID(ID)
	self.ID = ID
	return self
end

function poi:GetDefID()
	return self.defID
end

function poi:SetDefID(defID)
	self.defID = defID
	return self
end

function poi:GetLayerID()
	return self.layerID
end

function poi:SetLayerID(layerID)
	self.layerID = layerID
	return self
end

function poi:GetEdgesOut()
	return self.edgesOut
end

function poi:GetEdgesIn()
	return self.edgesIn
end

function poi:GetPosition()
	return self.position
end

function poi:SetPosition(position)
	self.position = position
	return self
end

function poi:GetPositionCoordinates()
	return self.position:GetCoordinates()
end

function poi:GetPositionAsSpringVector()
	return self.position:AsSpringVector()
end

function poi:GetOwnerID()
	return self.ownerID
end

function poi:SetOwner(ownerID)
	self.ownerID = ownerID
	return self
end

function poi:RotateByHeading(heading)
	self.heading = self.heading + heading
	return self -- copy
end

function poi:SetCustomData(key, value)
	self.customData[key] = value
	return self
end

function poi:GetCustomData(key)
	return self.customData[key]
end

--[[
function poi:Copy(pois, newID)
	if pois == nil then return self end
	if newID == nil then return self end
	if newID == 0 then return self end
	if pois[newID] ~= nil then return self end
	
	local newPoi = New(
		self.ID,
		self.defID,
		self.ownerID,		
		self.position,
		self.heading,
		self.edgesOut,
		self.edgesIn,
		self.customData
	)
	
	for id, edgeData in pairs(self.edgesOut) do
		pois[id].edgesIn[newID] = edgeData
	end
	for id, edgeData in pairs(self.edgesIn) do
		pois[id].edgesOut[newID] = edgeData
	end
	return self, newPoi
end
]]--

return POI
