local CycleContainerEvent = {}
UniversalAutoload.CycleContainerEvent = CycleContainerEvent

local CycleContainerEvent_mt = Class(CycleContainerEvent, Event)
InitEventClass(CycleContainerEvent, "CycleContainerEvent")
-- print("  UniversalAutoload - CycleContainerEvent")

function CycleContainerEvent.emptyNew()
	local self = Event.new(CycleContainerEvent_mt)
	return self
end

function CycleContainerEvent.new(vehicle, direction)
	local self = CycleContainerEvent.emptyNew()
	self.vehicle = vehicle
	self.direction = direction
	return self
end

function CycleContainerEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	self.direction = streamReadUInt8(streamId)
	self:run(connection)
end

function CycleContainerEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
	streamWriteUInt8(streamId, self.direction)
end

function CycleContainerEvent:run(connection)
	if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
		UniversalAutoload.cycleContainerTypeIndex(self.vehicle, self.direction, true) 
	end
end

function CycleContainerEvent.sendEvent(vehicle, direction, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			--print("server: Cycle Container Event")
			g_server:broadcastEvent(CycleContainerEvent.new(vehicle, direction), nil, nil, object)
		else
			--print("client: Cycle Container Event")
			g_client:getServerConnection():sendEvent(CycleContainerEvent.new(vehicle, direction))
		end
	end
end