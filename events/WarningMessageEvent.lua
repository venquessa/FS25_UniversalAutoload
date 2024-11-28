local WarningMessageEvent = {}
UniversalAutoload.WarningMessageEvent = WarningMessageEvent

local WarningMessageEvent_mt = Class(WarningMessageEvent, Event)
InitEventClass(WarningMessageEvent, "WarningMessageEvent")
-- print("  UniversalAutoload - WarningMessageEvent")

function WarningMessageEvent.emptyNew()
	local self = Event.new(WarningMessageEvent_mt)
	return self
end

function WarningMessageEvent.new(vehicle, messageId)
	local self = WarningMessageEvent.emptyNew()
	self.vehicle = vehicle
	self.messageId = messageId
	return self
end

function WarningMessageEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	self.messageId = streamReadInt32(streamId)
	self:run(connection)
end

function WarningMessageEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
	streamWriteInt32(streamId, self.messageId)
end

function WarningMessageEvent:run(connection)
	if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
		UniversalAutoload.showWarningMessage(self.vehicle, self.messageId, true)
	end
end

function WarningMessageEvent.sendEvent(vehicle, messageId, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			-- print("server: Warning Message Event")
			g_server:broadcastEvent(WarningMessageEvent.new(vehicle, messageId), nil, nil, object)
		else
			print("client: Warning Message Event - SHOULD BE TRIGGERED BY SERVER ONLY")
		end
	end
end