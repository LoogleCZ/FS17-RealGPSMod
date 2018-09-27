--
-- Author: Martin Fabík
-- Email: mar.fabik@gmail.com
--
-- GitHub project: https://github.com/LoogleCZ/FS17-RealGPSMod
-- If anyone found errors, please contact me at mar.fabik@gmail.com or report it on GitHub
--
-- version ID   - 1.0.0
-- version date - 2018-09-26 16:15
--

RealPDAMapSpec = {};

---
--	Helper function for calculation object's rotation against pure Y axis
--
--	@param object - object to calculate rotation
--	@return float angle in radians along Y axis
--
local calculateWorldYAxisRotation = function(object)
	local alpha, beta, gamma = getRotation(object);
	local yAxis = math.cos(gamma)*math.sin(beta)*math.cos(alpha) + math.sin(gamma)*math.sin(alpha);
	local xAxis = math.cos(beta)*math.cos(alpha);
	return(math.atan2(yAxis, xAxis));
end;

---
--	Helper function for calculate limit values on map - map center and
--		player positon
--
--	@param highLimit Limit high values
--	@param lowLimit  Limit low values
--	@param value     Value to compare
--	@param zoom      Map zoom value
--
--	@return float map position in range [0;1]
--	@return float player position in range [0;1]
--
local calculateMapAndPlayerPosition = function(highLimit, lowLimit, value, zoom)
	if value < lowLimit then
		return lowLimit, value*zoom;
	elseif value > highLimit then
		return highLimit, (0.5 + (value - highLimit)*zoom);
	else
		return value, 0.5;
	end;
end;

---
--	Test if all prerequisites are fulfilled
--  support mod not preset is not considered fatal error that should cause
--	error in vehicleType. Instead specialization will not set flag isInitialized
--	thus user can still use mod, but without map
--
--	@param specializations Table of all specilizations
--	@return true
--
function RealPDAMapSpec.prerequisitesPresent(specializations)
	return true;
end;

---
--	Preload of the specilization. Prepare spec. namespace
--
--	@param int savegame File descriptor for savegame
--
function RealPDAMapSpec:preLoad(savegame)
	self.LRM = {};
	self.LRM.isInitialized = false;
end;


---
--	Load specialization data. Also check if support mod is present and if not
--	keep flag isInitialized in false state
--
function RealPDAMapSpec:load(savegame)
	if g_currentMission.FS17_RealGPSMod ~= nil and g_currentMission.FS17_RealGPSMod.isModLoaded then
		
		local insertRootNode = getXMLString(self.xmlFile,"vehicle.indoorHud.map.linkNode#index");
		
		if insertRootNode ~= nil then
			
			self.lrm_setMapZoom    = SpecializationUtil.callSpecializationsFunction("lrm_setMapZoom");
			self.lrm_setPlayerSize = SpecializationUtil.callSpecializationsFunction("lrm_setPlayerSize");
			self.lrm_setRotateMap  = SpecializationUtil.callSpecializationsFunction("lrm_setRotateMap");
			
			self.LRM.rotatingMap = ( Utils.getNoNil(getXMLString(self.xmlFile, "vehicle.indoorHud.map.projection#rotate"), "player") == "map");
			self.LRM.player = {};
			self.LRM.player.size = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.indoorHud.map.projection.player#size"), 0.125);
			self.LRM.map = {};
			self.LRM.map.zoom = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.indoorHud.map.projection.background#zoom"), 2);
			
			self.LRM.isDedicatedServer = g_currentMission:getIsServer() and (g_dedicatedServerInfo ~= nil);
			
			if not self.LRM.isDedicatedServer then
				self.LRM.rootObject = Utils.indexToObject(self.components, insertRootNode);

				self.LRM.mapObject = loadI3DFile(g_currentMission.FS17_RealGPSMod.pdaMapFile);
				link(self.LRM.rootObject, self.LRM.mapObject);
				self.LRM.shaderObject = getChildAt(self.LRM.mapObject, 0);
			
				RealPDAMapSpec:setupI3D(self);
		
				self.LRM.mapWidth  = g_currentMission.ingameMap.worldSizeX;
				self.LRM.mapHeight = g_currentMission.ingameMap.worldSizeZ;
				
				self.LRM.player.minSize = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.indoorHud.map.controls.playerSize.limit#min"), 0.001);
				self.LRM.player.maxSize = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.indoorHud.map.controls.playerSize.limit#max"), 1);
				
				self.LRM.map.minZoom = math.max(Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.indoorHud.map.controls.mapZoom.limit#min"), 1), 1);
				self.LRM.map.maxZoom = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.indoorHud.map.controls.mapZoom.limit#max"), 20);
				self.LRM.map.aspectRatio = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.indoorHud.map.projection.background#aspectRatio"), 1);
				
				self.LRM.controls = {};
				self.LRM.controls.allow = Utils.getNoNil(getXMLBool(self.xmlFile, "vehicle.indoorHud.map.controls#allow"), true);
				self.LRM.controls.isInSetupMode = false;
				
				self.LRM.controls.rotateComponent = {};
				self.LRM.controls.rotateComponent.allow = Utils.getNoNil(getXMLBool(self.xmlFile, "vehicle.indoorHud.map.controls.rotateComponent#allow"), self.LRM.controls.allow);
				
				self.LRM.controls.mapZoom = {};
				self.LRM.controls.mapZoom.allow = Utils.getNoNil(getXMLBool(self.xmlFile, "vehicle.indoorHud.map.controls.mapZoom#allow"), self.LRM.controls.allow);
				self.LRM.controls.mapZoom.speed = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.indoorHud.map.controls.mapZoom#speed"), 1);
				self.LRM.controls.mapZoom.invertMouseAxis = Utils.getNoNil(getXMLBool(self.xmlFile, "vehicle.indoorHud.map.controls.mapZoom#invertMouseAxis"), false);
							
				self.LRM.controls.playerSize = {};
				self.LRM.controls.playerSize.allow = Utils.getNoNil(getXMLBool(self.xmlFile, "vehicle.indoorHud.map.controls.playerSize#allow"), self.LRM.controls.allow);
				self.LRM.controls.playerSize.speed = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.indoorHud.map.controls.playerSize#speed"), 1);
				self.LRM.controls.playerSize.invertMouseAxis = Utils.getNoNil(getXMLBool(self.xmlFile, "vehicle.indoorHud.map.controls.playerSize#invertMouseAxis"), false);
				
				self.LRM.cylindered = {};
				self.LRM.cylindered.isPresent = SpecializationUtil.hasSpecialization(Cylindered, self.specializations);
			
				self.LRM.sendValue = {};
				self.LRM.sendValue.mapZoom     = nil;
				self.LRM.sendValue.playerSize  = nil;
				self.LRM.sendValue.rotatingMap = nil;
			end;
			
			self.LRM.isInitialized = true;
		else
			print("[ERROR]: You're using real pda map specialization, but you have not set the linkNode. See https://github.com/LoogleCZ/FS17-RealGPSMod for more informations.");
		end;
		
	end;
end;

--
--
--
function RealPDAMapSpec:postLoad(savegame)
	if self.LRM.isInitialized then
		local zoom       = self.LRM.map.zoom   ;
		local playerSize = self.LRM.player.size;
		local rotateMap  = self.LRM.rotatingMap;
		if savegame ~= nil then
			zoom       = Utils.getNoNil(getXMLFloat(savegame.xmlFile, savegame.key..".interactiveMap#mapZoom"),    zoom       );
			playerSize = Utils.getNoNil(getXMLFloat(savegame.xmlFile, savegame.key..".interactiveMap#playerSize"), playerSize );
			rotateMap  = Utils.getNoNil(getXMLBool(savegame.xmlFile, savegame.key..".interactiveMap#rotateMap"),   rotateMap  );
		end;
		self:lrm_setMapZoom(zoom, true);
		self:lrm_setPlayerSize(playerSize, true);
		self:lrm_setRotateMap(rotateMap, true);
		
		if not self.LRM.isDedicatedServer then
			setShaderParameter(self.LRM.shaderObject , "mapProps"    , 0.5, 0.5, self.LRM.map.zoom, 0, false);
			local aspectX = 1;
			local aspectY = 1;
			if self.LRM.map.aspectRatio > 1 then
				aspectX = 1/self.LRM.map.aspectRatio;
			else
				aspectY = self.LRM.map.aspectRatio;
			end;
			setShaderParameter(self.LRM.shaderObject , "screenProps" , aspectX, aspectY, 0, 0, false);
		end;
	end;
end;

--
--
--
function RealPDAMapSpec:getSaveAttributesAndNodes(nodeIdent)
	if self.LRM.isInitialized then
		local nodes = nodeIdent .. "<interactiveMap mapZoom=\"" .. tostring(self.LRM.map.zoom) .. "\" playerSize=\"" .. tostring(self.LRM.player.size) .. "\" rotateMap=\"" .. tostring(self.LRM.rotatingMap) .. "\" />";
		return nil, nodes;
	end;
	return nil, nil;
end

--
--
--
function RealPDAMapSpec:delete() end;

--
--
--
function RealPDAMapSpec:readStream(streamId, connection)
	if self.LRM.isInitialized then
		self:lrm_setMapZoom(streamReadFloat32(streamId), true);
		self:lrm_setPlayerSize(streamReadFloat32(streamId), true);
		self:lrm_setRotateMap(streamReadBool(streamId), true);
	end;
end;

--
--
--
function RealPDAMapSpec:writeStream(streamId, connection)
	if self.LRM.isInitialized then
		streamWriteFloat32(streamId, self.LRM.map.zoom   );
		streamWriteFloat32(streamId, self.LRM.player.size);
		streamWriteBool(streamId, self.LRM.rotatingMap);
	end;
end;

--
--
--
function RealPDAMapSpec:mouseEvent(posX, posY, isDown, isUp, button) end;
function RealPDAMapSpec:keyEvent(unicode, sym, modifier, isDown) end;

--
--
--
function RealPDAMapSpec:update(dt)
	if not self.LRM.isDedicatedServer and self:getIsActive() then
		if self.LRM.isInitialized and self.rootNode ~= nil then
			local x , _ , z = getWorldTranslation(self.rootNode);
			if self.LRM.rotatingMap then
				setShaderParameter(self.LRM.shaderObject , "mapProps", ((x + self.LRM.mapWidth/2)/self.LRM.mapWidth), 1 - ((z + self.LRM.mapHeight/2)/self.LRM.mapHeight), self.LRM.map.zoom, math.pi*2 - g_currentMission.ingameMap.playerRotation, false );
			else
				local mapX, playerX = calculateMapAndPlayerPosition(self.LRM.mapHighLimit, self.LRM.mapLowLimit, ((x + self.LRM.mapWidth/2)/self.LRM.mapWidth), self.LRM.map.zoom);
				local mapY, playerY = calculateMapAndPlayerPosition(self.LRM.mapHighLimit, self.LRM.mapLowLimit, ((z + self.LRM.mapHeight/2)/self.LRM.mapHeight), self.LRM.map.zoom);
				local rotation = calculateWorldYAxisRotation(self.rootNode);
				
				setShaderParameter(self.LRM.shaderObject , "playerProps", playerX, 1 - playerY, rotation, self.LRM.player.size, false);
				setShaderParameter(self.LRM.shaderObject , "mapProps", mapX, 1 - mapY, self.LRM.map.zoom, 0, false );	
			end;
		end;
		
		if self.LRM.isInitialized then
			if self.LRM.controls.allow and not self:hasInputConflictWithSelection() and self:getIsActiveForInput() then
				if InputBinding.hasEvent(InputBinding.LRM_SETUP_MODE) then
					self.LRM.controls.isInSetupMode = not self.LRM.controls.isInSetupMode;
					if self.LRM.cylindered.isPresent then
						if self.LRM.controls.isInSetupMode then
							self.LRM.cylindered.numControlGroups        = self.numControlGroups;
							self.LRM.cylindered.activeControlGroupIndex = self.activeControlGroupIndex;
							self.numControlGroups                       = 0;
							self.activeControlGroupIndex                = 0;
							for _, v in pairs(self.movingTools) do
								v.isActive = false;
							end;
						else
							self.numControlGroups                       = self.LRM.cylindered.numControlGroups;
							self:setActiveControlGroup(self.LRM.cylindered.activeControlGroupIndex);
							self.LRM.cylindered.numControlGroups        = nil;
							self.LRM.cylindered.activeControlGroupIndex = nil;
						end;
					end;
				end;
				if self.LRM.controls.isInSetupMode then
					if self.LRM.controls.rotateComponent.allow then
						if InputBinding.hasEvent(InputBinding.LRM_TOGGLE_ROTATE_MODE) then
							self:lrm_setRotateMap(not self.LRM.rotatingMap);
						end;
					end;
					if self.LRM.controls.mapZoom.allow then
						local move, axisType = InputBinding.getInputAxis(InputBinding.AXIS_LRM_MAP_ZOOM);
						if axisType == InputBinding.INPUTTYPE_MOUSE_AXIS and self.LRM.controls.mapZoom.invertMouseAxis then
							move = -move;
						end;
						if move ~= 0 then
							local new = Utils.clamp(self.LRM.map.zoom + self.LRM.controls.mapZoom.speed*move*dt*self.LRM.map.zoom/1000, self.LRM.map.minZoom, self.LRM.map.maxZoom);
							self:lrm_setMapZoom(new);
						end;
					end;
					if self.LRM.controls.playerSize.allow then
						local move, axisType = InputBinding.getInputAxis(InputBinding.AXIS_LRM_PLAYER_SIZE);
						if axisType == InputBinding.INPUTTYPE_MOUSE_AXIS and self.LRM.controls.playerSize.invertMouseAxis then
							move = -move;
						end;
						if move ~= 0 then
							local new = Utils.clamp(self.LRM.player.size + self.LRM.controls.playerSize.speed*move*dt/1000, self.LRM.player.minSize, self.LRM.player.maxSize);
							self:lrm_setPlayerSize(new);
						end;
					end;
				end;
			end;
		end;
	end;
end;

--
--
--
function RealPDAMapSpec:updateTick(dt)
	if self.LRM.isInitialized and not self.LRM.isDedicatedServer and self:getIsActive() then
		if self.LRM.sendValue.mapZoom ~= nil then
			if g_server ~= nil then
				g_server:broadcastEvent(RealPDAMapEvent:new(self, RealPDAMapEvent.VALUE_TYPE_MAP_ZOOM, self.LRM.sendValue.mapZoom), nil, nil, self);
			else
				g_client:getServerConnection():sendEvent(RealPDAMapEvent:new(self, RealPDAMapEvent.VALUE_TYPE_MAP_ZOOM, self.LRM.sendValue.mapZoom));
			end;
			self.LRM.sendValue.mapZoom = nil;
		end;
		if self.LRM.sendValue.playerSize ~= nil then
			if g_server ~= nil then
				g_server:broadcastEvent(RealPDAMapEvent:new(self, RealPDAMapEvent.VALUE_TYPE_PLAYER_SIZE, self.LRM.sendValue.playerSize), nil, nil, self);
			else
				g_client:getServerConnection():sendEvent(RealPDAMapEvent:new(self, RealPDAMapEvent.VALUE_TYPE_PLAYER_SIZE, self.LRM.sendValue.playerSize));
			end;
			self.LRM.sendValue.playerSize = nil;
		end;
		if self.LRM.sendValue.rotatingMap ~= nil then
			if g_server ~= nil then
				g_server:broadcastEvent(RealPDAMapEvent:new(self, RealPDAMapEvent.VALUE_TYPE_ROTATING_MAP, self.LRM.sendValue.rotatingMap), nil, nil, self);
			else
				g_client:getServerConnection():sendEvent(RealPDAMapEvent:new(self, RealPDAMapEvent.VALUE_TYPE_ROTATING_MAP, self.LRM.sendValue.rotatingMap));
			end;
			self.LRM.sendValue.rotatingMap = nil;
		end;
	end;
end;

--
--
--
function RealPDAMapSpec:draw()
	if self.LRM.isInitialized and not self.LRM.isDedicatedServer and self:getIsActive() and self:getIsActiveForInput() then
		if self.LRM.controls.allow and not self:hasInputConflictWithSelection() then
			if self.LRM.controls.isInSetupMode then
				g_currentMission:addHelpButtonText(g_i18n:getText("action_lrm_exitSetupMode"), InputBinding.LRM_SETUP_MODE, nil, GS_PRIO_VERY_HIGH);
				if self.LRM.controls.rotateComponent.allow then
					local additionalInfo = "";
					if self.LRM.rotatingMap then
						additionalInfo = g_i18n:getText("status_lrm_map");
					else
						additionalInfo = g_i18n:getText("status_lrm_player");
					end;
					g_currentMission:addHelpButtonText(g_i18n:getText("input_LRM_TOGGLE_ROTATE_MODE") .. " (".. additionalInfo ..")", InputBinding.LRM_TOGGLE_ROTATE_MODE, nil, GS_PRIO_VERY_HIGH);
				end;
				if self.LRM.controls.mapZoom.allow then
					g_currentMission:addHelpAxis(InputBinding.AXIS_LRM_MAP_ZOOM, g_currentMission.FS17_RealGPSMod.icons.mapZoom);
					g_currentMission:addExtraPrintText(string.format(g_i18n:getText("status_lrm_mapZoom"), self.LRM.map.zoom));
				end;
				if self.LRM.controls.playerSize.allow then
					g_currentMission:addHelpAxis(InputBinding.AXIS_LRM_PLAYER_SIZE, g_currentMission.FS17_RealGPSMod.icons.playerSize);
					g_currentMission:addExtraPrintText(string.format(g_i18n:getText("status_lrm_playerSize"), self.LRM.player.size));
				end;
			else
				g_currentMission:addHelpButtonText(g_i18n:getText("action_lrm_enterSetupMode"), InputBinding.LRM_SETUP_MODE);
			end;
		end;
	end;
end;

--
--
--
function RealPDAMapSpec:onEnter() end;
function RealPDAMapSpec:onLeave() end;

-- non public helper
function RealPDAMapSpec:setupI3D(self)
	if not self.LRM.isDedicatedServer then
		local xmlValue = getXMLString(self.xmlFile,"vehicle.indoorHud.map.linkNode#rotation");
		if xmlValue ~= nil then
			local vector = Utils.getVectorNFromString(xmlValue, 3);
			vector[1] = math.rad(vector[1]);
			vector[2] = math.rad(vector[2]);
			vector[3] = math.rad(vector[3]);
			setRotation(self.LRM.mapObject, unpack(vector));
		end;
		
		xmlValue = getXMLString(self.xmlFile,"vehicle.indoorHud.map.linkNode#scale");
		if xmlValue ~= nil then
			local vector = Utils.getVectorNFromString(xmlValue, 3);
			setScale(self.LRM.mapObject, unpack(vector));
		end;
		
		xmlValue = getXMLString(self.xmlFile,"vehicle.indoorHud.map.linkNode#translation");
		if xmlValue ~= nil then
			local vector = Utils.getVectorNFromString(xmlValue, 3);
			setTranslation(self.LRM.mapObject, unpack(vector));
		end;
	end;
end;

--
--
--
function RealPDAMapSpec:lrm_setMapZoom(value, noEventSend)
	if self.LRM.isInitialized then
		self.LRM.map.zoom = value;
		
		if not self.LRM.isDedicatedServer then
			if noEventSend == nil or noEventSend == false then
				self.LRM.sendValue.mapZoom = value;
			end;
			self.LRM.mapLowLimit  = 0.5/self.LRM.map.zoom;
			self.LRM.mapHighLimit = 1 - self.LRM.mapLowLimit;
		end;
	else
		print("[WARN]: Some script is trying to call lrm_setMapZoom, but specialization is not initialized");
	end;
end;

--
--
--
function RealPDAMapSpec:lrm_setPlayerSize(value, noEventSend)
	if self.LRM.isInitialized then
		self.LRM.player.size = value;
		
		if not self.LRM.isDedicatedServer then
			if noEventSend == nil or noEventSend == false then
				self.LRM.sendValue.playerSize = value;
			end;
			if self.LRM.rotatingMap then
				setShaderParameter(self.LRM.shaderObject , "playerProps", 0.5, 0.5, math.pi, self.LRM.player.size, false);
			end;
		end;
	else
		print("[WARN]: Some script is trying to call lrm_setPlayerSize, but specialization is not initialized");
	end;
end;

--
--
--
function RealPDAMapSpec:lrm_setRotateMap(value, noEventSend)
	if self.LRM.isInitialized then
		self.LRM.rotatingMap = value;
		
		if not self.LRM.isDedicatedServer then
			if noEventSend == nil or noEventSend == false then
				self.LRM.sendValue.rotatingMap = value;
			end;
			if self.LRM.rotatingMap then
				setShaderParameter(self.LRM.shaderObject , "playerProps", 0.5, 0.5, math.pi, self.LRM.player.size, false);
			end;
		end;
	else
		print("[WARN]: Some script is trying to call lrm_setRotateMap, but specialization is not initialized");
	end;
end;
