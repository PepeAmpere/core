local moduleInfo = {
	name 	= "timeExt",
	desc 	= "Library with time related functions",
	author 	= "PepeAmpere",
	date 	= "2015/08/18",
	license = "notAlicense",
}

-- HMSF time format
-- = {hours, minutes, seconds, remainingFrameTime}
-- ! it allows all inputs, e.g. {1, 5, 85, 13} - which is invalid from perspective H:M:S, because there are more seconds than 60
-- ! so all functions do the calculations in "frames" and convert result in HMSF even if input was in HMSF

include 'LuaRules/Configs/constants.lua'

-- speed-ups
local FRAMES_IN_SECOND = constants.FRAMES_IN_SECOND
local FRAMES_IN_MINUTE = FRAMES_IN_SECOND * constants.SECONDS_IN_MINUTE
local FRAMES_IN_HOUR = FRAMES_IN_MINUTE * constants.MINUTES_IN_HOUR

local spGetGameFrame 	= Spring.GetGameFrame
local spGetGameSeconds 	= Spring.GetGameSeconds -- we try to avoid this

local floor = math.floor

local function HMSFtoFrames(timeInHMSF) -- time format convertor - from HMSF to frames
	return timeInHMSF[1]*FRAMES_IN_HOUR + timeInHMSF[2]*FRAMES_IN_MINUTE + timeInHMSF[3]*FRAMES_IN_SECOND + timeInHMSF[4]
end

local function FramesToHMSF(remainingFrameTime) -- time units convertor - from frames to HMSF 
	local hours	= floor(remainingFrameTime/FRAMES_IN_HOUR)
	if (hours > 0) then	remainingFrameTime = remainingFrameTime - hours*FRAMES_IN_HOUR end

	local minutes = floor(remainingFrameTime/FRAMES_IN_MINUTE)
	if (minutes > 0) then remainingFrameTime = remainingFrameTime - minutes*FRAMES_IN_MINUTE end

	local seconds = floor(remainingFrameTime/FRAMES_IN_SECOND)
	if (seconds > 0) then remainingFrameTime = remainingFrameTime - seconds*FRAMES_IN_SECOND end

	return {hours, minutes, seconds, remainingFrameTime}
end

local newTimeExt = {
	["Add"] = function(oldTimeInHMSF, deltaInHMSF) -- returns sum of two time values
		local resultInFrames = HMSFtoFrames(oldTimeInHMSF) + HMSFtoFrames(deltaInHMSF)
		return FramesToHMSF(resultInFrames), resultInFrames
	end,
	["AddToCurrent"] = function(deltaInHMSF) -- returns current time increased by delta parameter
		local resultInFrames = spGetGameFrame() + HMSFtoFrames(deltaInHMSF)
		return FramesToHMSF(resultInFrames), resultInFrames
	end,
	["Current"] = function(returnType) -- returns current time in specified format
		if (returnType == "seconds") then
			return floor(spGetGameFrame() / 30), spGetGameSeconds() -- second return value is engine seconds value to compare
		elseif (returnType == "HMSF") then
			return FramesToHMSF(spGetGameFrame())
		end
		
		-- default result is in frames
		return spGetGameFrame()
	end,
	["Diff"] = function(minuendInHMSF, subtrahendInHMSF) -- returns delta of two time values
		local diffInFrames = HMSFtoFrames(minuendInHMSF) - HMSFtoFrames(subtrahendInHMSF)
		return FramesToHMSF(diffInFrames), diffInFrames
	end,
	["Multiply"] = function(timeInHMSF, multiplier) -- returns multiplied time value
		local timeInFrames = HMSFtoFrames(timeInHMSF)
		local multiplied = timeInFrames * multiplier
		return FramesToHMSF(multiplied), multiplied
	end,
}

-- END OF MODULE DEFINITIONS --

-- update global tables 
if (timeExt == nil) then timeExt = {} end
for k,v in pairs(newTimeExt) do
	if (timeExt[k] ~= nil) then Spring.Echo("NOTIFICATION: Attempt to rewrite global table in module [" .. moduleInfo.name ..  "] - key: " .. k) end
	timeExt[k] = v 
end

