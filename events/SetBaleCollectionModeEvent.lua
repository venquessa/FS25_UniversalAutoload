local SetBaleCollectionModeEvent = {}
UniversalAutoload.SetBaleCollectionModeEvent = SetBaleCollectionModeEvent

local SetBaleCollectionModeEvent_mt = Class(SetBaleCollectionModeEvent, Event)
InitEventClass(SetBaleCollectionModeEvent, "SetBaleCollectionModeEvent")
-- print("  UniversalAutoload - SetBaleCollectionModeEvent")

function SetBaleCollectionModeEvent.emptyNew()
	local self = Event.new(SetBaleCollectionModeEvent_mt)
	return self
end

function SetBaleCollectionModeEvent.new(vehicle, baleCollectionMode)
	local self = SetBaleCollectionModeEvent.emptyNew()
	self.vehicle = vehicle
	self.baleCollectionMode = baleCollectionMode
	return self
end

function SetBaleCollectionModeEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	self.baleCollectionMode = streamReadBool(streamId)
	self:run(connection)
end

function SetBaleCollectionModeEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
	streamWriteBool(streamId, self.baleCollectionMode)
end

function SetBaleCollectionModeEvent:run(connection)
	if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
		UniversalAutoload.setBaleCollectionMode(self.vehicle, self.baleCollectionMode, true)
	end
end

function SetBaleCollectionModeEvent.sendEvent(vehicle, baleCollectionMode, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			--print("server: Set BaleCollectionMode Event")
			g_server:broadcastEvent(SetBaleCollectionModeEvent.new(vehicle, baleCollectionMode), nil, nil, object)
		else
			--print("client: Set BaleCollectionMode Event")
			g_client:getServerConnection():sendEvent(SetBaleCollectionModeEvent.new(vehicle, baleCollectionMode))
		end
	end
end