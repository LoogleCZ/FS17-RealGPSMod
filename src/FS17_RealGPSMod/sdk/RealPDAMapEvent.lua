--
-- Author: Martin Fabík
-- Email: mar.fabik@gmail.com
--
-- GitHub project: https://github.com/LoogleCZ/FS17-RealGPSMod
-- If anyone found errors, please contact me at mar.fabik@gmail.com or report it on GitHub
--
-- version ID   - 1.0.0
-- version date - 2018-09-05 18:30
--

RealPDAMapEvent = {};
RealPDAMapEvent_mt = Class(RealPDAMapEvent, Event);

InitEventClass(RealPDAMapEvent, "RealPDAMapEvent");

RealPDAMapEvent.VALUE_TYPE_MAP_ZOOM     = 1;
RealPDAMapEvent.VALUE_TYPE_PLAYER_SIZE  = 2;
RealPDAMapEvent.VALUE_TYPE_ROTATING_MAP = 3;

--
--
--
function RealPDAMapEvent:emptyNew()
    local self = Event:new(RealPDAMapEvent_mt);
    return self;
end;

--
--
--
function RealPDAMapEvent:new(object, settingID, value)
    local self = RealPDAMapEvent:emptyNew()
    self.object = object;
	self.settingID = settingID;
	self.value = value;
    return self;
end;

--
--
--
function RealPDAMapEvent:readStream(streamId, connection)
	self.object = readNetworkNodeObject(streamId);
	self.settingID = streamReadInt8(streamId);
	if 	   self.settingID == RealPDAMapEvent.VALUE_TYPE_MAP_ZOOM
		or self.settingID == RealPDAMapEvent.VALUE_TYPE_PLAYER_SIZE then
		self.value = streamReadFloat32(streamId);
	else
		self.value  = streamReadBool(streamId);
	end;
    self:run(connection);
end;

--
--
--
function RealPDAMapEvent:writeStream(streamId, connection)
	writeNetworkNodeObject(streamId, self.object);
	streamWriteInt8(streamId, self.settingID);
	if 	   self.settingID == RealPDAMapEvent.VALUE_TYPE_MAP_ZOOM
		or self.settingID == RealPDAMapEvent.VALUE_TYPE_PLAYER_SIZE then
		streamWriteFloat32(streamId, self.value)
	else
		streamWriteBool(streamId, self.value);
	end;
end;

--
--
--
function RealPDAMapEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false, connection, self.object);
	end;
	
	if self.settingID == RealPDAMapEvent.VALUE_TYPE_MAP_ZOOM then
		self.object:lrm_setMapZoom(self.value, true);
	elseif self.settingID == RealPDAMapEvent.VALUE_TYPE_PLAYER_SIZE then
		self.object:lrm_setPlayerSize(self.value, true);
	else
		self.object:lrm_setRotateMap(self.value, true);
	end;
end;
