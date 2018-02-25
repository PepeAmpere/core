local moduleInfo = {
	name = "hmsf",
	desc = "Time object and its methods.",
	author = "PepeAmpere",
	date = "2018-01-10",
	license = "MIT",
}


local MINUTES_IN_HOUR = 60
local SECONDS_IN_MINUTE = 60
local FRAMES_IN_SECOND = 30
local FRAMES_IN_MINUTE = FRAMES_IN_SECOND * SECONDS_IN_MINUTE
local FRAMES_IN_HOUR = FRAMES_IN_MINUTE * MINUTES_IN_HOUR

-- defining the metatable and access 
local timeObject = {}
local timeObjectMeta = {}
timeObjectMeta.__index = timeObject
timeObjectMeta.__metatable = false -- access

local function new(h, m, s, f)
	return setmetatable(
		{
			h = h or 0,
			m = m or 0, 
			s = s or 0,
			f = f or 0,
		},
		timeObjectMeta
	) 
end

local function isHMSF(hmsfObject)
	return type(hmsfObject) == "table" and type(hmsfObject.h) == "number" and type(hmsfObject.m) == "number" and type(hmsfObject.s) == "number" and type(hmsfObject.f) == "number"
end

local function toFrames(hmsfObject)
	return hmsfObject.h * FRAMES_IN_SECOND +
		   hmsfObject.m * FRAMES_IN_MINUTE +
		   hmsfObject.s * FRAMES_IN_SECOND +
		   hmsfObject.f
end

local function normalize(hmsfObject)
	local frames = toFrames(hmsfObject)
	local RoundFunction = math.floor
	if (frames < 0) then RoundFunction = math.ceil end
	
	hmsfObject.h = RoundFunction(frames / FRAMES_IN_HOUR)
	frames = frames - hmsfObject.h * FRAMES_IN_HOUR
	hmsfObject.m = RoundFunction(frames / FRAMES_IN_MINUTE)
	frames = frames - hmsfObject.m * FRAMES_IN_MINUTE
	hmsfObject.s = RoundFunction(frames / FRAMES_IN_SECOND)
	hmsfObject.f = RoundFunction(frames - hmsfObject.s * FRAMES_IN_SECOND) -- important for not rounded inputs
	
	return hmsfObject
end

local HMSF = new

-- OPERATORS AND BASIC METHODS --

function timeObjectMeta:__add(hmsfObject)
	return normalize(new(0, 0, 0, toFrames(self) + toFrames(hmsfObject)))
end

function timeObjectMeta:__sub(hmsfObject)
	return normalize(new(0, 0, 0, toFrames(self) - toFrames(hmsfObject)))
end

function timeObjectMeta:__mul(scalar)
	if (type(scalar) == "number") then
		return normalize(new(
			self.h * scalar,
			self.m * scalar,
			self.s * scalar,
			self.f * scalar
		))
	end
	return nil
end

function timeObjectMeta:__div(scalar)
	if (type(scalar) == "number") then
		return normalize(new(
			self.h / scalar,
			self.m / scalar,
			self.s / scalar,
			self.f / scalar
		))
	end
	return nil
end

function timeObjectMeta:__eq(hmsfObject)
	return self.h == hmsfObject.h and
		   self.m == hmsfObject.m and 
		   self.s == hmsfObject.s and
		   self.f == hmsfObject.f
end

function timeObjectMeta:__unm()
	return new(
		-self.h,
		-self.m,
		-self.s,
		-self.f
	)
end

function timeObjectMeta:__lt(hmsfObject)
	return toFrames(self) < toFrames(hmsfObject)
end

function timeObjectMeta:__le(hmsfObject)
	return toFrames(self) <= toFrames(hmsfObject)
end

function timeObject:Add(hmsfObject)
	self = self + hmsfObject
	return self -- copy
end

function timeObject:Sub(hmsfObject)
	self = self - hmsfObject
	return self -- copy
end

function timeObject:Mul(scalar)
	self.x = self.x * scalar
	self.y = self.y * scalar
	self.z = self.z * scalar
	return self -- copy(?)
end

function timeObjectMeta:__tostring()
	return "HMSF(" .. self.h .. "," .. self.m .. "," .. self.s .. "," .. self.f .. ")"
end

function timeObject:ToFrames()
	return toFrames(self)
end

function timeObject:Zero()
	self.h = 0
	self.m = 0
	self.s = 0
	self.f = 0
	return self -- in place?, otherwise use 'new'
end

function timeObject:Copy()
	return new(
		self.h,
		self.m,
		self.s,
		self.f
	)
end

function timeObject:Normalize()
	return normalize(new(
		self.h,
		self.m,
		self.s,
		self.f
	))
end

-- custom stuff

function timeObject:HHMMSSFF(h, m, s, f)
	local slots = {h = h, m = m, s = s, f = f}
	local finalString
	
	for k,v in pairs(slots) do
		if v then
			local value = self[k]
			local signPrefix = ""
			
			if (value < 0) then
				value = math.abs(value)
				signPrefix = "-"
			end
			
			if (finalString ~= nil) then
				finalString = finalString .. ":"
			end
			
			if (value < 10) then
				value = "0" .. value
			end
			
			if (finalString == nil) then
				finalString = signPrefix .. tostring(value)
			else
				finalString = finalString .. signPrefix .. tostring(value)
			end
		end
	end
	
	return finalString
end

return HMSF