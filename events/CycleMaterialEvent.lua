local CycleMaterialEvent = {}
UniversalAutoload.CycleMaterialEvent = CycleMaterialEvent

local CycleMaterialEvent_mt = Class(CycleMaterialEvent, Event)
InitEventClass(CycleMaterialEvent, "CycleMaterialEvent")
-- print("  UniversalAutoload - CycleMaterialEvent")

function CycleMaterialEvent.emptyNew()
	local self = Event.new(CycleMaterialEvent_mt)
	return self
end

function CycleMaterialEvent.new(vehicle, direction)
	local self = CycleMaterialEvent.emptyNew()
	self.vehicle = vehicle
	self.direction = direction
	return self
end

function CycleMaterialEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	self.direction = streamReadUInt8(streamId)
	self:run(connection)
end

function CycleMaterialEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
	streamWriteUInt8(streamId, self.direction)
end

function CycleMaterialEvent:run(connection)
	if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
		UniversalAutoload.cycleMaterialTypeIndex(self.vehicle, self.direction, true) 
	end
end

function CycleMaterialEvent.sendEvent(vehicle, direction, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			--print("server: Cycle Material Event")
			g_server:broadcastEvent(CycleMaterialEvent.new(vehicle, direction), nil, nil, object)
		else
			--print("client: Cycle Material Event")
			g_client:getServerConnection():sendEvent(CycleMaterialEvent.new(vehicle, direction))
		end
	end
end