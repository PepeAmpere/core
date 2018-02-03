local moduleInfo = {
	name = "message",
	desc = "Message API extension for sending messages of various types",
	author = "PepeAmpere",
	date = "2015-05-12",
	license = "notAlicense",
}

-- load dependencies if necessary
if (stringExt == nil) then attach.Module(modules, "stringExt") end -- attacher mandatory in such case

-- LOCAL CONSTANTS
local MESSAGE_TYPE_SEPARATOR = "#"
local MESSAGE_ITEMS_SEPARATOR = "|"
local MESSAGE_EQUATION = "="
local MESSAGE_ELEMENT_OPENING = "{"
local MESSAGE_ELEMENT_CLOSING = "}"
local MESSAGE_ELEMENT_ENDING = "x"

local DEBUG_MESSAGE_LOG_ENCODED = false
local DEBUG_MESSAGE_LOG_INGNORED_BY_RECEIVER = false
-- global constants injection if needed
if (constants) then -- if included before this module is loaded
	DEBUG_MESSAGE_LOG_ENCODED = constants.DEBUG.MESSAGE.LOG_ENCODED
	DEBUG_MESSAGE_LOG_INGNORED_BY_RECEIVER = constants.DEBUG.MESSAGE.LOG_INGNORED_BY_RECEIVER
end

-- SPEEDUP 
local pairs = pairs
local tostring = tostring
local type = type

local spEcho = Spring.Echo
local spSendLuaUIMsg = Spring.SendLuaUIMsg
local spSendLuaGaiaMsg = Spring.SendLuaGaiaMsg
local spSendLuaRulesMsg = Spring.SendLuaRulesMsg
local spGetGameRulesParam = Spring.GetGameRulesParam
local spSetFeatureRulesParam = Spring.SetFeatureRulesParam
local spSetUnitRulesParam = Spring.SetUnitRulesParam
local spSetTeamRulesParam = Spring.SetTeamRulesParam
local spSetGameRulesParam = Spring.SetGameRulesParam
local spValidUnitID = Spring.ValidUnitID
local spValidFeatureID = Spring.ValidFeatureID

local newMessage = {
	-- @description encode given message of whatever type and return encoded string
	-- @argument messageToBeEncoded [anything] value of any type (see supported ones in encoders)
	-- @return encodedString [string]
	["Encode"] = function(messageToBeEncoded)		
		local typeSeparator = MESSAGE_TYPE_SEPARATOR
		local itemsSeparator = MESSAGE_ITEMS_SEPARATOR
		local equation = MESSAGE_EQUATION
		local elementOpening = MESSAGE_ELEMENT_OPENING
		local elementClosing = MESSAGE_ELEMENT_CLOSING
		local elementEnding = MESSAGE_ELEMENT_ENDING
		local encoders = {}
		encoders = {
			["boolean"] = function(messageChunk, typeSeparator)
				local boolInString = "false"
				if (messageChunk) then boolInString = "true" end
				return "boolean" .. typeSeparator .. boolInString
			end,
			["nil"] = function(messageChunk, typeSeparator)
				return "nil" .. typeSeparator .. "nil"
			end,
			["number"] = function(messageChunk, typeSeparator)
				return "number" .. typeSeparator .. messageChunk
			end,
			["string"] = function(messageChunk, typeSeparator)
				return "string" .. typeSeparator .. messageChunk
			end,
			["table"] = function(messageChunk, typeSeparator, itemsSeparator, equation, elementOpening, elementClosing, elementEnding, level)
				level = level or 0
				local tableInString = "table" .. typeSeparator .. elementOpening .. level .. elementClosing
				local itemsCounter = 0

				for key, value in pairs(messageChunk) do

					if (itemsCounter > 0) then tableInString = tableInString .. itemsSeparator end

					local valueInString = encoders[type(value)](value, typeSeparator, itemsSeparator, equation, elementOpening, elementClosing, elementEnding, level + 1)
					tableInString = tableInString .. key .. equation .. valueInString
					itemsCounter = itemsCounter + 1
				end

				return tableInString .. elementOpening .. level .. elementEnding .. elementClosing
			end,


			-- not supported data types
			["function"] = function()
				spEcho("[" .. moduleInfo.name .. "] ERROR, tried to encode NOT SUPPORTED DATA TYPE: thread")
				return "function" .. typeSeparator .. "error"
			end,
			["thread"] = function()
				spEcho("[" .. moduleInfo.name .. "] ERROR, tried to encode NOT SUPPORTED DATA TYPE: thread")
				return "thread" .. typeSeparator .. "error"
			end,
			["userdata"] = function()
				spEcho("[" .. moduleInfo.name .. "] ERROR, tried to encode NOT SUPPORTED DATA TYPE: userdata")
				return "userdata" .. typeSeparator .. "error"
			end,
		}

		local encodedString = encoders[type(messageToBeEncoded)](messageToBeEncoded, typeSeparator, itemsSeparator, equation, elementOpening, elementClosing, elementEnding)

		if (DEBUG_MESSAGE_LOG_ENCODED) then
			spEcho("[" .. moduleInfo.name .. "][DEBUG_MESSAGE_LOG_ENCODED] encoded string: " .. encodedString)
		end
		
		return encodedString
	end,
	
	-- @description return decoded message
	-- @argument encodedMessage [string] value of any type (see supported ones in encoders)
	-- @return decodedMessage [anything] same type, same message which was coded
	["Decode"] = function(encodedMessage)
		local typeSeparator = MESSAGE_TYPE_SEPARATOR
		local itemsSeparator = MESSAGE_ITEMS_SEPARATOR
		local equation = MESSAGE_EQUATION
		local elementOpening = MESSAGE_ELEMENT_OPENING
		local elementClosing = MESSAGE_ELEMENT_CLOSING
		local elementEnding = MESSAGE_ELEMENT_ENDING
		decoders = {
			["boolean"] = function(messageChunk)
				stringToBool = false
				if (messageChunk == "true") then stringToBool = true end
				return stringToBool
			end,
			["nil"] = function()
				return nil
			end,
			["number"] = function(messageChunk, typeSeparator)
				return tonumber(messageChunk)
			end,
			["string"] = function(messageChunk, typeSeparator)
				return messageChunk
			end,
			["table"] = function(messageChunk, typeSeparator, itemsSeparator, equation, elementOpening, elementClosing, elementEnding, level)
				level = level or 0
				local newTable = {}
				local thisLevelContentString = messageChunk

				if (level == 0) then
					local openElement = elementOpening .. level .. elementClosing
					local closingElement = elementOpening .. level .. elementEnding .. elementClosing
					thisLevelContentString = string.match(messageChunk, (openElement .. "(.-)" .. closingElement))
				end
				-- spEcho("MSG:", thisLevelContentString)

				local openSubElement = elementOpening .. (level + 1) .. elementClosing
				local closingSubElement = elementOpening .. (level + 1) .. elementEnding .. elementClosing
				local subTables = {}
				local subTablesCounter = 0
				local stringWithoutSubtables = string.gsub(thisLevelContentString, (openSubElement .. "(.-)" .. closingSubElement), function(a) subTables[#subTables + 1] = a; return "TABLE" end)
				-- spEcho("noTab:", stringWithoutSubtables)

				local sequence = stringExt.SplitString(stringWithoutSubtables, itemsSeparator)
				-- spEcho("value 1: " .. (subTables[1] or "nothing"))

				for i=1, #sequence do
					local newItem = stringExt.SplitString(sequence[i], equation)
					local newKey = newItem[1]
					local newValueType = stringExt.SplitString(newItem[2], typeSeparator)
					local newValue
					if (newValueType[1] == "table") then
						subTablesCounter = subTablesCounter + 1
						newValue = decoders[newValueType[1]](subTables[subTablesCounter], typeSeparator, itemsSeparator, equation, elementOpening, elementClosing, elementEnding, level + 1)
					else
						newValue = decoders[newValueType[1]](newValueType[2], typeSeparator, itemsSeparator, equation, elementOpening, elementClosing, elementEnding, level + 1)
					end

					-- conver simple array index into number
					if (tonumber(newKey) ~= nil) then newKey = tonumber(newKey) end

					newTable[newKey] = newValue
					-- spEcho(newKey, "=>", newValue)
				end

				return newTable
			end,

			-- not supported data types
			["function"] = function()
				return nil
			end,
			["thread"] = function()
				return nil
			end,
			["userdata"] = function()
				return nil
			end,
		}

		local sequence = stringExt.SplitString(encodedMessage, typeSeparator)
		
		if (sequence[1] ~= nil and decoders[sequence[1]] ~= nil) then -- check to avoid decoding not coded messages
			return decoders[sequence[1]](encodedMessage, typeSeparator, itemsSeparator, equation, elementOpening, elementClosing, elementEnding)
		else
			-- better is to return nil instead returning encodedMessage itself
			return nil
		end
	end,
	
	
	-- technical functions handling the registration/call overhead
	["handler"] = {		
		-- @description Check if there is registered given handler
		-- @privacy private to message.lua and all loaders of message receivers
		-- @argument name [string] unique key
		-- @return registered [bool]
		-- @return count [number] amount of registered events, if no event, return nil
		["IsRegistered"] = function(name)
			local eventCount = spGetGameRulesParam(name)
			if (eventCount ~= nil) then
				local listOfHandlers = {}
				for i=1, eventCount do
					listOfHandlers[i] = name .. i
				end
				return true, listOfHandlers
			end
			return false, eventCount
		end,
		
		-- @description Check if there is registered given handler
		-- @privacy private
		-- @argument name [string] unique key
		-- @argument func [function] function which is triggered by event
		-- @argument newIndex [number] index making the key unique if there are multiple handlers of same event name
		["RegisterSynced"] = function(name, func, newIndex)
			if (newIndex == nil) then newIndex = 1 end
			
			local newName = name .. newIndex
			gadgetHandler:RegisterGlobal(newName, func)
			spSetGameRulesParam(name, newIndex) -- allow us to check amount of handlers registered
			Spring.Echo("Event handler registred: " .. newName)
		end,
	},
	
	-- SYNCED GADGET => SYNCED GADGETS communication
	
	-- @description simulates propagation of the information by handling event functions in all gadgets registered
	-- @argument messageToBeSent [table] pairs of keys and values passed to different gadget
	-- @comment sent ONLY ONCE in whole simulation
	["SendSyncedRules"] = function(messageToBeSent)
		-- this is fake msg sending, its event handler calling
		local subject = messageToBeSent.subject
		
		-- call all event handler functions registered... what a HACK!
		local exist, listOfHandlers = message.handler.IsRegistered(subject, i)
		if (exist) then
			for i=1, #listOfHandlers do
				Script.LuaRules[listOfHandlers[i]](messageToBeSent, 0)
			end
		end
	end,
	
	-- SYNCED GADGET => UNSYNCED GADGET communication
	
	-- @description simulates propagation of the information by handling event functions in all unsynced gadgets
	-- @argument messageToBeSent [table] pairs of keys and values passed to different gadget
	-- @comment sent ONLY ONCE in whole simulation
	["SendSyncedToUnsynced"] = function(messageToBeSent)
		-- this is fake msg sending, its event handler calling
		local subject = messageToBeSent.subject
		local encodedMessage = message.Encode(messageToBeSent)
		
		SendToUnsynced(subject, encodedMessage)
	end,	
	
	-- @description simulates propagation of the information by handling event functions in all unsynced gadgets
	-- @argument subject [string] - unique string identfiing the transfer
	-- @argument message [string or number or boolean] - no tables allowed
	-- @comment sent ONLY ONCE in whole simulation
	["SendSyncedToUnsyncedDecoded"] = function(subject, message)
		-- this is fake msg sending, its event handler calling		
		SendToUnsynced(subject, message)
	end,	
	
	-- GADGET => WIDGETS communication via storing it in memory
	
	-- @description simulates propagation of the information by storing it in engine memory slot on a unit
	-- @argument messageToBeSent [table] pairs of keys and values, stored in memory one by one
	-- @argument unitID [number] unique engine reference ID of a unit
	-- @argument accessPolicy [string] access rules to give information, possible values listed in comment, same policy for all items of given message
	-- @comment possible access policies of the accessPolicy are same as for the Spring.SetUnitRulesParam
	-- 'private' : only readable by the ally (default)
	-- 'allied'  : readable by ally + ingame allied
	-- 'inlos'   : readable if the unit is in LOS
	-- 'inradar' : readable if the unit is in AirLOS
	-- 'public'  : readable by all
	-- @comment sent ONLY ONCE in whole simulation
	-- @comment !seems value is limited to string or number, any other data type has to be encoded via message.Encode
	["SendSyncedInfoUnit"] = function(messageToBeSent, unitID, accessPolicy)
		local newAccessPolicy = {}
		if (accessPolicy == nil) then 
			newAccessPolicy.private = true
		else
			newAccessPolicy[accessPolicy] = true
		end
		
		if (unitID ~= nil and spValidUnitID(unitID)) then
			for k, v in pairs(messageToBeSent) do
				spSetUnitRulesParam(unitID, k, v, newAccessPolicy)
			end
		end
	end,
	
	-- @description simulates propagation of the information by storing it in engine memory slot on a feature
	-- @comment in all aspects same as message.SendSyncedInfoUnit funtion 
	["SendSyncedInfoFeature"] = function(messageToBeSent, featureID, accessPolicy)
		local newAccessPolicy = {}
		if (accessPolicy == nil) then 
			newAccessPolicy.private = true
		else
			newAccessPolicy[accessPolicy] = true
		end
		
		if (featureID ~= nil and spValidFeatureID(featureID)) then
			for k, v in pairs(messageToBeSent) do
				spSetFeatureRulesParam(featureID, k, v, newAccessPolicy)
			end
		end
	end,
	
	-- @description simulates propagation of the information by storing it in engine memory slots on a team level
	-- @argument messageToBeSent [table] pairs of keys and values, stored in memory one by one
	-- @argument teamID [number] unique engine reference ID of a team
	-- @argument accessPolicy [string] access rules to give information, possible values listed in comment, same policy for all items of given message
	-- @comment possible access policies of the accessPolicy are same as for the Spring.SetTeamRulesParam
	-- 'private' : only readable by the ally (default)
	-- 'allied'  : readable by ally + ingame allied
	-- 'public'  : readable by all
	-- @comment sent ONLY ONCE in whole simulation
	-- @comment !seems value is limited to string or number, any other data type has to be encoded via message.Encode
	["SendSyncedInfoTeam"] = function(messageToBeSent, teamID, accessPolicy)
		local newAccessPolicy = {}
		if (accessPolicy == nil) then 
			newAccessPolicy.private = true
		else
			newAccessPolicy[accessPolicy] = true
		end
		
		if (teamID ~= nil) then
			for k, v in pairs(messageToBeSent) do
				spSetTeamRulesParam(teamID, k, v, newAccessPolicy)
			end
		end
	end,
	
	-- @description simulates propagation of the information by storing it in engine memory slot on a team level
	-- @argument messageToBeSent [table] pairs of keys and values
	-- @argument teamID [number] unique engine reference ID of a team
	-- @argument accessPolicy [string] access rules to give information, possible values listed in comment, same policy for all items of given message
	-- @comment possible access policies of the accessPolicy are same as for the Spring.SetTeamRulesParam
	-- 'private' : only readable by the ally (default)
	-- 'allied'  : readable by ally + ingame allied
	-- 'public'  : readable by all
	-- @comment sent ONLY ONCE in whole simulation
	-- @comment anyone insterested in message stored there have decode it first
	["SendSyncedInfoTeamPacked"] = function(subject, messageToBeSent, teamID, accessPolicy)
		local newAccessPolicy = {}
		if (accessPolicy == nil) then 
			newAccessPolicy.private = true
		else
			newAccessPolicy[accessPolicy] = true
		end
		
		if (teamID ~= nil) then
			spSetTeamRulesParam(teamID, subject, messageToBeSent, newAccessPolicy)
		end
	end,
	
	-- @description simulates propagation of the information by storing it in engine global memory slots
	-- @argument messageToBeSent [table] pairs of keys and values, stored in memory one by one
	-- @comment sent ONLY ONCE in whole simulation
	-- @comment !seems value is limited to string or number, any other data type has to be encoded via message.Encode
	["SendSyncedInfoGame"] = function(messageToBeSent)
		for k, v in pairs(messageToBeSent) do
			spSetGameRulesParam(k, v)
		end
	end,
	
	-- @description simulates propagation of the information by storing it in engine global memory slot
	-- @argument subject [string] pairs of keys and values, stored in memory one by one
	-- @argument encodedMessage [string] table encoded
	-- @comment anyone insterested in message stored there have decode it first
	["SendSyncedInfoGamePacked"] = function(subject, encodedMessage)
		spSetGameRulesParam(subject, encodedMessage)
	end,
	
	-- WIDGET => GADGETS communication
	
	-- @comment	Sends real message for each client running this code
	["SendRules"] = function(messageToBeSent)
		local encodedMessage = message.Encode(messageToBeSent)
		spSendLuaRulesMsg(encodedMessage)
		return encodedMessage
	end,
	
	-- WIDGET => WIDGETS communication
	
	-- @comment	Sends real message for each client running this code
	["SendUI"] = function(messageToBeSent)
		local encodedMessage = message.Encode(messageToBeSent)
		spSendLuaUIMsg(encodedMessage)
		return encodedMessage
	end,
	["SendGaia"] = function(messageToBeSent)
		local encodedMessage = message.Encode(messageToBeSent)
		spSendLuaGaiaMsg(encodedMessage)
		return encodedMessage
	end,
	["Receive"] = function(encodedMessage, playerID, context)
		-- encodedMessage	- string 	- coded message
		-- playerID			- number 	- playerID of sender?
		-- context 			- string 	- (optional) reciever sub-key (e.g. identifier of gadget handling message if we store multiple reactions for same message in same system)
		
		-- CONTEXT
		-- ? i was also thinking about having sub-modules of recievers covering given context but for simple cases it would make situation more complicated
		-- usually let empty or use name of file calling message.Receive
		
		local decodedMsg = message.Decode(encodedMessage) -- I decode the message
		
		if (decodedMsg == nil) then return end -- ingnore not-coded messages
		local msgSubject = decodedMsg.subject -- I save message subject to variable which selects function handling given message
		
		-- if list of handlers doesn't exist, user possible use want to use message.Decode only or load proper file
		if (receiveCustomMessage == nil) then spEcho("[" .. moduleInfo.name .. "][ERROR] tried to call non-existing table of receivers [" .. msgSubject .. "]. Maybe you want just message.Decode() function instead.") end
		
		-- if handler exist, run its function
		if (receiveCustomMessage[msgSubject] ~= nil) then 
			return receiveCustomMessage[msgSubject](decodedMsg, playerID, context)
		else
			if (DEBUG_MESSAGE_LOG_ENCODED) then
				spEcho("[" .. moduleInfo.name .. "][DEBUG_MESSAGE_LOG_ENCODED] tried to call non-existing receiver [" .. msgSubject .. "]")
			end
			-- we ignore all messages which have not defined reciever - it is intended!
			return nil
		end
	end,
	
	-- STANDARDIZED ATTACHER
	
	-- @description attach custom message receiver module functions into global data structure
	-- @argument newReceiveCustomMessage [table] table of functions, key: name, value: function
	-- @argument moduleInfo [table] module information
	["AttachCustomReceiver"] = function(newReceiveCustomMessage, moduleInfo)
		if (receiveCustomMessage == nil) then receiveCustomMessage = {} end
		for subject,functionRef in pairs(newReceiveCustomMessage) do
			if (receiveCustomMessage[subject] ~= nil) then Spring.Echo("NOTIFICATION: Attempt to rewrite global table in module [" .. moduleInfo.name ..  "] - key: " .. k) end
			receiveCustomMessage[subject] = functionRef
			
			-- synced msg sim via adding handler instead of the receiver
			if (gadgetHandler and gadgetHandler:IsSyncedCode()) then -- only in synced receiver
				local exist, listOfHandlers = message.handler.IsRegistered(subject)
				if (not exist) then
					message.handler.RegisterSynced(subject, functionRef)
				else
					message.handler.RegisterSynced(subject, functionRef, #listOfHandlers + 1)
				end
			end
			
			if (gadgetHandler and not (gadgetHandler:IsSyncedCode())) then
				Spring.Echo(subject, functionRef)
				--gadgetHandler:AddSyncAction(subject, functionRef)
			end
			
			-- unsynced experimental
			if (widgetHandler) then
				-- TBD if needed, currently not needed
			end
		end
	end,
	
	-- @description attach custom message sender module functions into global data structure
	-- @argument newSendCustomMessage [table] table of functions, key: name, value: function
	-- @argument moduleInfo [table] module information
	["AttachCustomSender"] = function(newSendCustomMessage, moduleInfo)
		if (sendCustomMessage == nil) then sendCustomMessage = {} end
		for subject,functionRef in pairs(newSendCustomMessage) do
			if (sendCustomMessage[subject] ~= nil) then Spring.Echo("NOTIFICATION: Attempt to rewrite global table in module [" .. moduleInfo.name ..  "] - key: " .. k) end
			sendCustomMessage[subject] = functionRef
		end
	end,
}

-- END OF MODULE DEFINITIONS --

-- update global tables 
if (message == nil) then message = {} end
for k,v in pairs(newMessage) do
	-- if (message[k] ~= nil) then Spring.Echo("NOTIFICATION: Attempt to rewrite global table in module [" .. moduleInfo.name ..  "] - key: " .. k) end
	message[k] = v 
end

