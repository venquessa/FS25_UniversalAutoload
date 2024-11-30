local UpdateActionEvents = {}
UniversalAutoload.UpdateActionEvents = UpdateActionEvents

local UpdateActionEvents_mt = Class(UpdateActionEvents, Event)
InitEventClass(UpdateActionEvents, "UpdateActionEvents")
-- print("  UniversalAutoload - UpdateActionEvents")

function UpdateActionEvents.emptyNew()
	local self = Event.new(UpdateActionEvents_mt)
	return self
end

function UpdateActionEvents.new(vehicle, loadCount, unloadCount)
	local self = UpdateActionEvents.emptyNew()
	self.vehicle = vehicle
	self.loadCount = loadCount or 0
	self.unloadCount = unloadCount or 0
	return self
end

function UpdateActionEvents:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	--if connection:getIsServer() then
		self.loadCount = streamReadInt32(streamId)
		self.unloadCount = streamReadInt32(streamId)
	--end
	self:run(connection)
end

function UpdateActionEvents:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
	--if not connection:getIsServer() then
		streamWriteInt32(streamId, self.loadCount)
		streamWriteInt32(streamId, self.unloadCount)
	--end
end

function UpdateActionEvents:run(connection)
	if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
		UniversalAutoload.updateActionEventText(self.vehicle, self.loadCount, self.unloadCount, true)
	end
end

function UpdateActionEvents.sendEvent(vehicle, loadCount, unloadCount, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			--print("server: Update Action Events")
			g_server:broadcastEvent(UpdateActionEvents.new(vehicle, loadCount, unloadCount), nil, nil, vehicle)
		else
			--print("client: Update Action Events")
			g_client:getServerConnection():sendEvent(UpdateActionEvents.new(vehicle))
		end
	end
end