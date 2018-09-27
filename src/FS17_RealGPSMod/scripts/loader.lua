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

RealGPSMod = {};

do
	for k, v in pairs(g_i18n.texts) do 
		g_i18n.globalI18N.texts[k] = v;
	end;

	RealGPSMod.directory = g_currentModDirectory;
	local path = g_currentModDirectory:reverse();
	local _,e = path:find("/", 2);
	RealGPSMod.modDirectoryName = path:sub(2, e-1):reverse();
	RealGPSMod.pdaMapDirectory = RealGPSMod.directory .. "../";
	RealGPSMod.pdaMapFile = RealGPSMod.pdaMapDirectory .. "pdaMap.i3d";
end;

function RealGPSMod.load()

	local pdaMapFile = g_currentMission.ingameMap.mapOverlay.filename;
	-- need abs path to file...
	if not g_currentMission.missionInfo.map.isModMap then
		-- if map is mod, we already have absolute path to file in filename
		--	but if map is default, we need to figure out where the game is located
		local currentGamePath = g_inputBindingPathTemplate;
		currentGamePath = currentGamePath:reverse();
		local _, e = currentGamePath:find("/");
		currentGamePath = currentGamePath:sub(e+1);
		_, e = currentGamePath:find("/");
		currentGamePath = currentGamePath:sub(e):reverse();
		pdaMapFile = currentGamePath .. pdaMapFile;
	end;
	
	local i3dFile = [[
<?xml version="1.0" encoding="iso-8859-1"?>
<i3D name="pdaMap" version="1.6">
  <Files>
    <File fileId="1" filename="]] .. pdaMapFile .. [[" relativePath="false"/>
    <File fileId="2" filename="]] .. RealGPSMod.directory .. [[shaders/realGPSMapShader.xml" relativePath="false"/>
	<File fileId="3" filename="]] .. RealGPSMod.directory .. [[textures/playerIcon.png" relativePath="false"/>
  </Files>
  <Materials>
    <Material name="pdaMap" materialId="1" ambientColor="1 1 1" customShaderId="2" customShaderVariation="PDA_PROJECTION_FLAT">
      <Custommap name="pdaMap" fileId="1" />
	  <Custommap name="playerIcon" fileId="3" />
    </Material>
  </Materials>
  <Shapes externalShapesFile="]] .. RealGPSMod.modDirectoryName .. [[/shapes_data/common.i3d.shapes"/>
  <Scene>
    <Shape shapeId="1" name="pdaMap" nodeId="1" materialIds="1" receiveShadows="true"/>
  </Scene>
</i3D>
]];
	
	local file = io.open(RealGPSMod.pdaMapFile, "w");
	if file ~= nil then
		file:write(i3dFile);
		file:close();
		
		-- Icons for mouse control
		RealGPSMod.icons = {};
		
		local uiScale = g_gameSettings:getValue("uiScale");
		
		local iconFilename = RealGPSMod.directory .. "textures/mouseHelpMapZoom.dds";
		local iconWidth, iconHeight = getNormalizedScreenValues(40*uiScale, 40*uiScale);
		RealGPSMod.icons.mapZoom = Overlay:new("mapZoomIcon", iconFilename, 0, 0, iconWidth, iconHeight);
		RealGPSMod.icons.mapZoom:setAlignment(Overlay.ALIGN_VERTICAL_MIDDLE, Overlay.ALIGN_HORIZONTAL_LEFT);
		
		iconFilename = RealGPSMod.directory .. "textures/mouseHelpPlayerSize.dds";
		iconWidth, iconHeight = getNormalizedScreenValues(40*uiScale, 40*uiScale);
		RealGPSMod.icons.playerSize = Overlay:new("playerSizeIcon", iconFilename, 0, 0, iconWidth, iconHeight);
		RealGPSMod.icons.playerSize:setAlignment(Overlay.ALIGN_VERTICAL_MIDDLE, Overlay.ALIGN_HORIZONTAL_LEFT);
		-- \Icons
		
		RealGPSMod.isModLoaded = true;
	end;
	
	g_currentMission.FS17_RealGPSMod = RealGPSMod;
end;

function RealGPSMod.delete()
	if RealGPSMod.isModLoaded then
		RealGPSMod.icons.mapZoom:delete();
		RealGPSMod.icons.playerSize:delete();
	end;
	RealGPSMod.isModLoaded = false;
end;

FSBaseMission.loadMapFinished = Utils.appendedFunction(FSBaseMission.loadMapFinished, RealGPSMod.load);
FSBaseMission.delete = Utils.prependedFunction(FSBaseMission.delete, RealGPSMod.delete);

