-- ============================================================= --
-- Universal Autoload MOD - MANAGER
-- ============================================================= --

-- manager
UniversalAutoloadManager = {}
addModEventListener(UniversalAutoloadManager)

UniversalAutoloadManager.DEBUG_STEPS = nil

-- specialisation
g_specializationManager:addSpecialization('universalAutoload', 'UniversalAutoload', Utils.getFilename('UniversalAutoload.lua', g_currentModDirectory), "")

TypeManager.validateTypes = Utils.appendedFunction(TypeManager.validateTypes, function(self)
	if self.typeName == "vehicle" then
		print("UAL - VALIDATE TYPES")
		UniversalAutoloadManager.injectSpecialisation()
	end
end)

-- Create a new store pack to group all UAL supported vehicles
g_storeManager:addModStorePack("UNIVERSALAUTOLOAD", g_i18n:getText("configuration_universalAutoload", g_currentModName), "icons/storePack_ual.dds", g_currentModDirectory)

-- external classes
source(UniversalAutoload.path .. "scripts/BoundingBox.lua")
source(UniversalAutoload.path .. "scripts/LoadingVolume.lua")
source(UniversalAutoload.path .. "gui/InGameMenuUALSettings.lua")

-- class variables
UniversalAutoload.userSettingsFile = "modSettings/UniversalAutoload.xml"
UniversalAutoload.SHOP_ICON = UniversalAutoload.path .. "icons/shop_icon.dds"

-- class tables
UniversalAutoload.ACTIONS = {
	["TOGGLE_LOADING"]		 = "UNIVERSALAUTOLOAD_TOGGLE_LOADING",
	["UNLOAD_ALL"]			 = "UNIVERSALAUTOLOAD_UNLOAD_ALL",
	["TOGGLE_TIPSIDE"]		 = "UNIVERSALAUTOLOAD_TOGGLE_TIPSIDE",
	["TOGGLE_FILTER"]		  = "UNIVERSALAUTOLOAD_TOGGLE_FILTER",
	["TOGGLE_HORIZONTAL"]	  = "UNIVERSALAUTOLOAD_TOGGLE_HORIZONTAL",
	["CYCLE_MATERIAL_FW"]	  = "UNIVERSALAUTOLOAD_CYCLE_MATERIAL_FW",
	["CYCLE_MATERIAL_BW"]	  = "UNIVERSALAUTOLOAD_CYCLE_MATERIAL_BW",
	["SELECT_ALL_MATERIALS"]   = "UNIVERSALAUTOLOAD_SELECT_ALL_MATERIALS",
	["CYCLE_CONTAINER_FW"]	 = "UNIVERSALAUTOLOAD_CYCLE_CONTAINER_FW",
	["CYCLE_CONTAINER_BW"]	 = "UNIVERSALAUTOLOAD_CYCLE_CONTAINER_BW",
	["SELECT_ALL_CONTAINERS"]  = "UNIVERSALAUTOLOAD_SELECT_ALL_CONTAINERS",
	-- ["TOGGLE_BELTS"]		   = "UNIVERSALAUTOLOAD_TOGGLE_BELTS",
	-- ["TOGGLE_DOOR"]			= "UNIVERSALAUTOLOAD_TOGGLE_DOOR",
	-- ["TOGGLE_CURTAIN"]		   = "UNIVERSALAUTOLOAD_TOGGLE_CURTAIN",
	["TOGGLE_SHOW_DEBUG"]	   = "UNIVERSALAUTOLOAD_TOGGLE_SHOW_DEBUG",
	["TOGGLE_SHOW_LOADING"]	   = "UNIVERSALAUTOLOAD_TOGGLE_SHOW_LOADING",
	["TOGGLE_BALE_COLLECTION"] = "UNIVERSALAUTOLOAD_TOGGLE_BALE_COLLECTION"
}

UniversalAutoload.WARNINGS = {
	[1] = "warning_UNIVERSALAUTOLOAD_CLEAR_UNLOADING_AREA",
	[2] = "warning_UNIVERSALAUTOLOAD_NO_OBJECTS_FOUND",
	[3] = "warning_UNIVERSALAUTOLOAD_UNABLE_TO_LOAD_OBJECT",
	[4] = "warning_UNIVERSALAUTOLOAD_NO_LOADING_UNLESS_STATIONARY"
}

UniversalAutoload.CONTAINERS = {
	[1] = "ALL",
	[2] = "EURO_PALLET",
	[3] = "BIGBAG_PALLET",
	[4] = "LIQUID_TANK",
	[5] = "BIGBAG",
	[6] = "BALE",
	[7] = "LOGS"
}

-- DEFINE DEFAULTS FOR CONTAINER TYPES
-- UniversalAutoload.ALL			= { sizeX = 1.250, sizeY = 0.850, sizeZ = 0.850 }
-- UniversalAutoload.EURO_PALLET	= { sizeX = 1.250, sizeY = 0.790, sizeZ = 0.850 }
-- UniversalAutoload.BIGBAG_PALLET  = { sizeX = 1.525, sizeY = 1.075, sizeZ = 1.200 }
-- UniversalAutoload.LIQUID_TANK	= { sizeX = 1.433, sizeY = 1.500, sizeZ = 1.415 }
-- UniversalAutoload.BIGBAG		 = { sizeX = 1.050, sizeY = 1.666, sizeZ = 0.866, neverStack=true }
-- UniversalAutoload.BALE		   = { isBale=true }

UniversalAutoload.VEHICLES = {} -- actual vehicles currently in game
UniversalAutoload.VEHICLE_CONFIGURATIONS = {} -- settings for each vehicle configuration

UniversalAutoload.VEHICLE_TYPES = {} -- vehicleTypes with autoload spec
UniversalAutoload.LOADING_TYPES = {} -- known container object types
UniversalAutoload.INVALID_OBJECTS = {} -- objects that cannot be loaded

UniversalAutoload.GLOBAL_DEFAULTS = {
	{id="showDebug", default=false, valueType="BOOL", key="#showDebug", description="Show the full graphical debugging display for all vehicles in game"},
	{id="highPriority", default=true, valueType="BOOL", key="#highPriority", description="Apply high priority to all UAL key bindings in the F1 menu"},
	{id="manualLoadingOnly", default=false, valueType="BOOL", key="#manualLoadingOnly", description="Prevent autoloading (automatic unloading is allowed)"},
	{id="disableManualLoading", default=false, valueType="BOOL", key="#disableManualLoading", description="Prevent use of manual loading triggers"},
	{id="disableAutoStrap", default=false, valueType="BOOL", key="#disableAutoStrap", description="Disable the automatic application of tension belts"},
	{id="pricePerLog", default=0, valueType="FLOAT", key="#pricePerLog", description="The price charged for each auto-loaded log (default is zero)"},
	{id="pricePerBale", default=0, valueType="FLOAT", key="#pricePerBale", description="The price charged for each auto-loaded bale (default is zero)"},
	{id="pricePerPallet", default=0, valueType="FLOAT", key="#pricePerPallet", description="The price charged for each auto-loaded pallet (default is zero)"},
	{id="minLogLength", default=0, valueType="FLOAT", key="#minLogLength", description="The global minimum length for logs that will be autoloaded (default is zero)"},
}

UniversalAutoload.OPTIONS_DEFAULTS = {
	{id="isBoxTrailer", default=false, valueType="BOOL", key="#isBoxTrailer", description="If trailer is enclosed with a rear door"},
	{id="isLogTrailer", default=false, valueType="BOOL", key="#isLogTrailer", description="If trailer is a logging trailer - will load only logs, dropped from above"},
	{id="isBaleTrailer", default=false, valueType="BOOL", key="#isBaleTrailer", description="If trailer should use an automatic bale collection mode"},
	{id="isCurtainTrailer", default=false, valueType="BOOL", key="#isCurtainTrailer", description="Automatically detect the available load side (if the trailer has curtain sides)"},
	{id="enableRearLoading", default=false, valueType="BOOL", key="#enableRearLoading", description="Use the automatic rear loading trigger"},
	{id="enableSideLoading", default=false, valueType="BOOL", key="#enableSideLoading", description="Use the automatic side loading triggers"},
	{id="noLoadingIfFolded", default=false, valueType="BOOL", key="#noLoadingIfFolded", description="Prevent loading when folded"},
	{id="noLoadingIfUnfolded", default=false, valueType="BOOL", key="#noLoadingIfUnfolded", description="Prevent loading when unfolded"},
	{id="noLoadingIfCovered", default=false, valueType="BOOL", key="#noLoadingIfCovered", description="Prevent loading when covered"},
	{id="noLoadingIfUncovered", default=false, valueType="BOOL", key="#noLoadingIfUncovered", description="Prevent loading when uncovered"},
	{id="rearUnloadingOnly", default=false, valueType="BOOL", key="#rearUnloadingOnly", description="Use rear unloading zone only (not side zones)"},
	{id="frontUnloadingOnly", default=false, valueType="BOOL", key="#frontUnloadingOnly", description="Use front unloading zone only (not side zones)"},
	{id="horizontalLoading", default=false, valueType="BOOL", key="#horizontalLoading", description="Start with horizontal loading enabled (can be toggled if key is bound)"},
	{id="disableAutoStrap", default=false, valueType="BOOL", key="#disableAutoStrap", description="Disable the automatic application of tension belts"},
	{id="disableHeightLimit", default=false, valueType="BOOL", key="#disableHeightLimit", description="Disable the density based stacking height limit"},
	{id="zonesOverlap", default=false, valueType="BOOL", key="#zonesOverlap", description="Flag to identify when the loading areas overlap each other"},
	{id="offsetRoot", default=nil, valueType="STRING", key="#offsetRoot", description="Vehicle i3d node that area offsets are relative to"},
	{id="minLogLength", default=0, valueType="FLOAT", key="#minLogLength", description="The minimum length for logs that will be autoloaded (default is zero)"},
	{id="showDebug", default=false, valueType="BOOL", key="#showDebug", description="Show the full graphical debugging display for this vehicle"},
}

UniversalAutoload.LOADING_AREA_DEFAULTS = {
	{id="offset", default="0 0 0", valueType="VECTOR_TRANS", key="#offset", description="Offset to the centre of the loading area"},
	{id="offsetRoot", default=nil, valueType="STRING", key="#offsetRoot", description="Vehicle i3d node that this area offset is relative to"},
	{id="width", default=0, valueType="FLOAT", key="#width", description="Width of the loading area"},
	{id="length", default=0, valueType="FLOAT", key="#length", description="Length of the loading area"},
	{id="height", default=0, valueType="FLOAT", key="#height", description="Height of the loading area"},
	{id="baleHeight", default=nil, valueType="FLOAT", key="#baleHeight", description="Height of the loading area for BALES only"},
	{id="widthAxis", default=nil, valueType="STRING", key="#widthAxis", description="Axis name to extend width of the loading area"},
	{id="lengthAxis", default=nil, valueType="STRING", key="#lengthAxis", description="Axis name to extend length of the loading area"},
	{id="heightAxis", default=nil, valueType="STRING", key="#heightAxis", description="Axis name to extend height of the loading area"},
	{id="offsetFrontAxis", default=nil, valueType="STRING", key="#offsetFrontAxis", description="Axis name to adjust the front position of the loading area"},
	{id="offsetRearAxis", default=nil, valueType="STRING", key="#offsetRearAxis", description="Axis name to adjust the rear position of the loading area"},
	{id="reverseWidthAxis", default=false, valueType="BOOL", key="#reverseWidthAxis", description="Reverses direction of width extension if true"},
	{id="reverseLengthAxis", default=false, valueType="BOOL", key="#reverseLengthAxis", description="Reverses direction of length extension if true"},
	{id="reverseHeightAxis", default=false, valueType="BOOL", key="#reverseHeightAxis", description="Reverses direction of height extension if true"},
	{id="noLoadingIfFolded", default=false, valueType="BOOL", key="#noLoadingIfFolded", description="Prevent loading when folded (for this area only)"},
	{id="noLoadingIfUnfolded", default=false, valueType="BOOL", key="#noLoadingIfUnfolded", description="Prevent loading when unfolded (for this area only)"},
	{id="noLoadingIfCovered", default=false, valueType="BOOL", key="#noLoadingIfCovered", description="Prevent loading when covered (for this area only)"},
	{id="noLoadingIfUncovered", default=false, valueType="BOOL", key="#noLoadingIfUncovered", description="Prevent loading when uncovered (for this area only)"},
}

UniversalAutoload.CONFIG_DEFAULTS = {
	{id="selectedConfigs", default="ALL", valueType="STRING", key="#selectedConfigs", description="Selected Configuration Names"},
	{id="useConfigName", default=nil, valueType="STRING", key="#useConfigName", description="Specific configuration to be used for selected configs"},
	{
		key = ".loadingArea(?)",
		name = "loadingArea",
		data = UniversalAutoload.LOADING_AREA_DEFAULTS,
	},
	{
		key = ".options",
		name = "options",
		data = UniversalAutoload.OPTIONS_DEFAULTS,
	},
}
	
UniversalAutoload.VEHICLE_DEFAULTS = {
	{id="configFileName", default=nil, valueType="STRING", key="#configFileName", description="Vehicle config file xml full path - used to identify supported vehicles"},
	{
		key = ".configuration(?)",
		name = "spec",
		data = UniversalAutoload.CONFIG_DEFAULTS,
	},
}

UniversalAutoload.CONTAINER_DEFAULTS = {
	{id="configFileName", default="UNKNOWN", valueType="STRING", key="#configFileName", description="Pallet Configuration Filename"},
	{id="containerType", default="ANY", valueType="STRING", key="#containerType", description="The loading type category to group under in the menu)"},
	{id="isBale", default=false, valueType="BOOL", key="#isBale", description="If the object is either a round bale or square bale"},
	{id="flipYZ", default=false, valueType="BOOL", key="#flipYZ", description="Should always rotate 90 degrees to stack on end - e.g. for round bales"},
	{id="neverStack", default=false, valueType="BOOL", key="#neverStack", description="Should never load another pallet on top of this one when loading"},
	{id="neverRotate", default=false, valueType="BOOL", key="#neverRotate", description="Should never rotate object when loading"},
	{id="alwaysRotate", default=false, valueType="BOOL", key="#alwaysRotate", description="Should always rotate to face outwards for manual unloading"},
	{id="frontOffset", default=0, valueType="FLOAT", key="#frontOffset", description="Offset from the front of trailer (only when loaded first)"},
}

UniversalAutoload.SAVEGAME_STATE_DEFAULTS = {
	{id="tipside", default="none", valueType="STRING", key="#tipside", description="Last used tip side"},
	{id="loadside", default="both", valueType="STRING", key="#loadside", description="Last used load side"},
	{id="loadWidth", default=0, valueType="FLOAT", key="#loadWidth", description="Last used load width"},
	{id="loadLength", default=0, valueType="FLOAT", key="#loadLength", description="Last used load length"},
	{id="loadHeight", default=0, valueType="FLOAT", key="#loadHeight", description="Last used load height"},
	{id="actualWidth", default=0, valueType="FLOAT", key="#actualWidth", description="Last used expected load width"},
	{id="actualLength", default=0, valueType="FLOAT", key="#actualLength", description="Last used complete load length"},
	{id="layerCount", default=0, valueType="INT", key="#layerCount", description="Number of layers that are currently loaded"},
	{id="layerHeight", default=0, valueType="FLOAT", key="#layerHeight", description="Total height of the currently loaded layers"},
	{id="nextLayerHeight", default=0, valueType="FLOAT", key="#nextLayerHeight", description="Height for the next layer (highest point in previous layer)"},
	{id="loadAreaIndex", default=1, valueType="INT", key="#loadAreaIndex", description="Last used load area"},
	{id="materialIndex", default=1, valueType="INT", key="#materialIndex", description="Last used material type"},
	{id="containerIndex", default=1, valueType="INT", key="#containerIndex", description="Last used container type"},
	{id="loadingFilter", default=false, valueType="BOOL", key="#loadingFilter", description="TRUE=Load full pallets only; FALSE=Load any pallets"},
	{id="useHorizontalLoading", default=false, valueType="BOOL", key="#useHorizontalLoading", description="Last used horizontal loading state"},
	{id="baleCollectionMode", default=false, valueType="BOOL", key="#baleCollectionMode", description="Enable manual toggling of the automatic bale collection mode"},
}

function iterateDefaultsTable(tbl, parentKey, currentKey, currentValue, action)
    parentKey = parentKey or ""
    currentKey = currentKey or ""
    action = action or function(k, v, parentKey, currentKey, finalValue) 
        if debugSchema then print("  " .. currentKey .. ": " .. tostring(finalValue)) end
    end

    for k, v in pairs(tbl) do
        if type(v) == "table" then
            local newCurrentKey = currentKey
            if v.key then
                newCurrentKey = newCurrentKey .. v.key
            end
            local newCurrentValue = currentValue
            if v.id ~= nil then
                local finalValue = newCurrentValue and newCurrentValue[v.id] or v.default
                action(k, v, parentKey, newCurrentKey, finalValue)
            end
            if v.data then
                iterateDefaultsTable(v.data, parentKey, newCurrentKey, newCurrentValue, action)
            end
        end
    end
end
print("GLOBAL_DEFAULTS") iterateDefaultsTable(UniversalAutoload.GLOBAL_DEFAULTS)
print("VEHICLE_DEFAULTS") iterateDefaultsTable(UniversalAutoload.VEHICLE_DEFAULTS)
print("CONTAINER_DEFAULTS") iterateDefaultsTable(UniversalAutoload.CONTAINER_DEFAULTS)
print("SAVEGAME_STATE_DEFAULTS") iterateDefaultsTable(UniversalAutoload.SAVEGAME_STATE_DEFAULTS)

function UniversalAutoloadManager.openUserSettingsXMLFile(xmlFilename)
	
	local xmlFilename = xmlFilename or Utils.getFilename(UniversalAutoload.userSettingsFile, getUserProfileAppPath())
	local xmlFile = XMLFile.loadIfExists("settings", xmlFilename, UniversalAutoload.xmlSchema)
	if not xmlFile then
		print("Creating NEW user settings file " .. xmlFilename)
		xmlFile = XMLFile.create("settings", xmlFilename, "universalAutoload", UniversalAutoload.xmlSchema)
	end
	
	return xmlFile
end
--
function UniversalAutoloadManager.getVehicleConfigFromSettingsXML(configKey, xmlFile)
	
	if not configKey then
		print("configuration key required for getVehicleConfigFromSettingsXML")
		return
	end

	local shouldCloseFile = not xmlFile and true
	local xmlFile = xmlFile or UniversalAutoloadManager.openUserSettingsXMLFile()
	
	if xmlFile then
		
		local configuration = {}
		local selectedConfigs = xmlFile:getValue(configKey.."#selectedConfigs", "ALL")
		local useConfigName = xmlFile:getValue(configKey.."#useConfigName", nil)

		local j = 1
		local hasBaleHeight = false
		local loadingArea = {}
		while true do
			local loadAreaKey = string.format("%s.loadingArea(%d)", configKey, j-1)
			if not xmlFile:hasProperty(loadAreaKey) then
				break
			end
			loadingArea[j] = {}
			loadingArea[j].width  = xmlFile:getValue(loadAreaKey.."#width", nil)
			loadingArea[j].length = xmlFile:getValue(loadAreaKey.."#length", nil)
			loadingArea[j].height = xmlFile:getValue(loadAreaKey.."#height", nil)
			loadingArea[j].baleHeight = xmlFile:getValue(loadAreaKey.."#baleHeight", nil)
			loadingArea[j].widthAxis  = xmlFile:getValue(loadAreaKey.."#widthAxis", nil)
			loadingArea[j].lengthAxis = xmlFile:getValue(loadAreaKey.."#lengthAxis", nil)
			loadingArea[j].heightAxis = xmlFile:getValue(loadAreaKey.."#heightAxis", nil)
			loadingArea[j].offsetFrontAxis = xmlFile:getValue(loadAreaKey.."#offsetFrontAxis", nil)
			loadingArea[j].offsetRearAxis  = xmlFile:getValue(loadAreaKey.."#offsetRearAxis", nil)
			loadingArea[j].reverseWidthAxis  = xmlFile:getValue(loadAreaKey.."#reverseWidthAxis", false)
			loadingArea[j].reverseLengthAxis = xmlFile:getValue(loadAreaKey.."#reverseLengthAxis", false)
			loadingArea[j].reverseHeightAxis = xmlFile:getValue(loadAreaKey.."#reverseHeightAxis", false)
			loadingArea[j].offset = xmlFile:getValue(loadAreaKey.."#offset", "0 0 0", true)
			loadingArea[j].offsetRoot = xmlFile:getValue(loadAreaKey.."#offsetRoot", nil)
			loadingArea[j].noLoadingIfFolded = xmlFile:getValue(loadAreaKey.."#noLoadingIfFolded", false)
			loadingArea[j].noLoadingIfUnfolded = xmlFile:getValue(loadAreaKey.."#noLoadingIfUnfolded", false)
			loadingArea[j].noLoadingIfCovered = xmlFile:getValue(loadAreaKey.."#noLoadingIfCovered", false)
			loadingArea[j].noLoadingIfUncovered = xmlFile:getValue(loadAreaKey.."#noLoadingIfUncovered", false)
			hasBaleHeight = hasBaleHeight or type(loadingArea[j].baleHeight) == 'number'
			j = j + 1
		end
		configuration['loadArea'] = loadingArea
		
		local isBaleTrailer = xmlFile:getValue(configKey..".options#isBaleTrailer", nil)
		local horizontalLoading = xmlFile:getValue(configKey..".options#horizontalLoading", nil)
		
		configuration['horizontalLoading'] = horizontalLoading or isBaleTrailer or false
		configuration['isBaleTrailer'] = isBaleTrailer or hasBaleHeight
			
		configuration['isBoxTrailer'] = xmlFile:getValue(configKey..".options#isBoxTrailer", false)
		configuration['isLogTrailer'] = xmlFile:getValue(configKey..".options#isLogTrailer", false)
		configuration['isCurtainTrailer'] = xmlFile:getValue(configKey..".options#isCurtainTrailer", false)
		configuration['enableRearLoading'] = xmlFile:getValue(configKey..".options#enableRearLoading", false)
		configuration['enableSideLoading'] = xmlFile:getValue(configKey..".options#enableSideLoading", false)
		configuration['noLoadingIfFolded'] = xmlFile:getValue(configKey..".options#noLoadingIfFolded", false)
		configuration['noLoadingIfUnfolded'] = xmlFile:getValue(configKey..".options#noLoadingIfUnfolded", false)
		configuration['noLoadingIfCovered'] = xmlFile:getValue(configKey..".options#noLoadingIfCovered", false)
		configuration['noLoadingIfUncovered'] = xmlFile:getValue(configKey..".options#noLoadingIfUncovered", false)
		configuration['rearUnloadingOnly'] = xmlFile:getValue(configKey..".options#rearUnloadingOnly", false)
		configuration['frontUnloadingOnly'] = xmlFile:getValue(configKey..".options#frontUnloadingOnly", false)
		configuration['disableAutoStrap'] = xmlFile:getValue(configKey..".options#disableAutoStrap", false)
		configuration['disableHeightLimit'] = xmlFile:getValue(configKey..".options#disableHeightLimit", false)
		configuration['zonesOverlap'] = xmlFile:getValue(configKey..".options#zonesOverlap", false)
		configuration['offsetRoot'] = xmlFile:getValue(configKey..".options#offsetRoot", nil)
		configuration['minLogLength'] = xmlFile:getValue(configKey..".options#minLogLength", UniversalAutoload.minLogLength)
		configuration['showDebug'] = xmlFile:getValue(configKey..".options#showDebug", debugAll)

		if shouldCloseFile then
			xmlFile:delete()
		end
		
		return configuration
	else
		print("ERROR: no settings file " .. tostring(xmlFile))
	end
end
--
function UniversalAutoloadManager.countConfigsInSettingsXML(xmlFile)

	local shouldCloseFile = not xmlFile and true
	local xmlFile = xmlFile or UniversalAutoloadManager.openUserSettingsXMLFile()
	
	if xmlFile then
		local i = 0
		local counts = {}
		while true do
			local vehicleKey = string.format(UniversalAutoload.vehicleKey, i)
			if not xmlFile:hasProperty(vehicleKey) then
				break
			end
			local j = 0
			while true do
				local configKey = string.format(UniversalAutoload.vehicleConfigKey, i, j)
				if not xmlFile:hasProperty(configKey) then
					break
				end
				j = j + 1
			end
			i = i + 1
			counts[i] = j
		end	
		
		if shouldCloseFile then
			xmlFile:delete()
		end
		
		return i, counts
	end
end
--
function UniversalAutoloadManager.getConfigSettingsPosition(targetFileName, targetConfigId, targetConfigName, xmlFile)

	local targetConfigId = targetConfigId or UniversalAutoload.ALL
	local shouldCloseFile = not xmlFile and true
	local xmlFile = xmlFile or UniversalAutoloadManager.openUserSettingsXMLFile()
	
	if xmlFile then
		local i = 0
		while true do
			local vehicleKey = string.format(UniversalAutoload.vehicleKey, i)
			if not xmlFile:hasProperty(vehicleKey) then
				break
			end
			local configFileName = xmlFile:getValue(vehicleKey .. "#configFileName")
			if tostring(configFileName):lower() == tostring(targetFileName):lower() then
				
				print("targetConfigId: " .. tostring(targetConfigId))
				local j = 0
				while true do
					local configKey = string.format(UniversalAutoload.vehicleConfigKey, i, j)
					if not xmlFile:hasProperty(configKey) then
						break
					end
					local selectedConfigs = xmlFile:getValue(configKey .. "#selectedConfigs")
					print("selectedConfigs: " .. selectedConfigs)
					if selectedConfigs == UniversalAutoload.ALL then
						print("FOUND 'ALL' CONFIG AT #" .. j+1)
						break
					elseif selectedConfigs:find(tostring(targetConfigId)) then
						print("FOUND SELECTED CONFIG AT #" .. j+1)
						break
					end
					j = j + 1
				end
	
				return i, j
			end
			i = i + 1
		end	
		
		if shouldCloseFile then
			xmlFile:delete()
		end
		
		return nil, nil, i
	end
end
--
function UniversalAutoloadManager.getVehicleConfigIndexesForSaving(vehicle, configId, xmlFile)

	local configFileName = vehicle.configFileName
	local index, subIndex, size = UniversalAutoloadManager.getConfigSettingsPosition(configFileName, configId, configName, xmlFile)

	if index then
		local configKey = string.format(UniversalAutoload.vehicleConfigKey, index, subIndex)
		configId = xmlFile:getValue(configKey .. "#selectedConfigs") or configId
		print("UPDATE CONFIG #" .. index + 1 .. " == " .. configId .. " (#" ..subIndex + 1 .. ")")
	else
		index = size or 0
		subIndex = 0
		print("INSERT CONFIG INDEX #" .. index)
		local key = string.format(UniversalAutoload.vehicleKey, index)
		xmlFile:setValue(key.."#configFileName", configFileName)
	end
	
	if not UniversalAutoload.VEHICLE_CONFIGURATIONS[configFileName] then
		UniversalAutoload.VEHICLE_CONFIGURATIONS[configFileName] = {}
	end

	if not UniversalAutoload.VEHICLE_CONFIGURATIONS[configFileName][configId] then
		print("USING CONFIG SUB-INDEX: #" .. subIndex .. " (" .. configId .. ")")
		local key = string.format(UniversalAutoload.vehicleConfigKey, index, subIndex)
		xmlFile:setValue(key.."#selectedConfigs", tostring(configId))
		if configName then
			xmlFile:setValue(key.."#useConfigName", tostring(configName))
		end
		UniversalAutoload.VEHICLE_CONFIGURATIONS[configFileName][configId] = {}
	end
	
	return index, subIndex
end
		
--
function UniversalAutoloadManager.saveVehicleConfigToSettingsXML(vehicle, xmlFile)
	local spec = vehicle and vehicle.spec_universalAutoload
	if not spec or not vehicle.configFileName then
		print("Invalid vehicle supplied: " .. tostring(vehicle))
		return
	end

	local shouldCloseFile = not xmlFile and true
	local xmlFile = xmlFile or UniversalAutoloadManager.openUserSettingsXMLFile()
	
	if xmlFile then
		
		local config, configFileName, configId, configName
		
		if spec.loadedVehicleConfig then
			print("ALREADY SET WITH:")
			config = spec.loadedVehicleConfig
			configId = spec.loadedVehicleConfig['selectedConfigs']
			configFileName = spec.loadedVehicleConfig['configFileName']
			print("configFileName = " .. tostring(configFileName))
			print("selectedConfigs = " .. tostring(configId))
		end
		
		if not configId or not configFileName then
			print("FIND CORRECT SETTINGS FILE POSITION:")
			configFileName = vehicle.configFileName
			configId, configName, _ = UniversalAutoloadManager.getValidConfigurationId(vehicle, useConfigName)
			print("configFileName = " .. tostring(configFileName))
			print("selectedConfigs = " .. tostring(configId))
		end
		
		
		index, subIndex = UniversalAutoloadManager.getVehicleConfigIndexesForSaving(vehicle, configId, xmlFile)

		if config then
			if UniversalAutoload.VEHICLE_CONFIGURATIONS[configFileName][configId] == config then
				print("ALREADY MATCHES")
				return
			end
		end

		print("SAVE TO SETTINGS FILE")
		print("options:")
		local configKey = string.format(UniversalAutoload.vehicleConfigKey, index, subIndex)
		iterateDefaultsTable(UniversalAutoload.OPTIONS_DEFAULTS, configKey, ".options", spec,
		function(k, v, parentKey, currentKey, finalValue)
			if currentKey and finalValue ~= v.default then
				xmlFile:setValue(parentKey..currentKey, finalValue)
			end
			print("  >> " .. tostring(currentKey) .. " = " .. tostring(finalValue))
		end)

		print("loadingAreas:")
		for j, loadArea in pairs (spec.loadArea or {}) do
			local loadAreaKey = string.format(".loadingArea(%d)", j-1)
			iterateDefaultsTable(UniversalAutoload.LOADING_AREA_DEFAULTS, configKey, loadAreaKey, spec.loadArea[j],
			function(k, v, parentKey, currentKey, finalValue)
				if currentKey and finalValue ~= v.default then
					if type(finalValue) == "table" and v.valueType == "VECTOR_TRANS" then
						xmlFile:setValue(parentKey..currentKey, unpack(finalValue))
					else
						xmlFile:setValue(parentKey..currentKey, finalValue)
					end
				end
				print("  >> " .. tostring(currentKey) .. " = " .. tostring(finalValue))
			end)
		end

		xmlFile:save()
		
		if shouldCloseFile then
			xmlFile:delete()
		end
	end
end

function UniversalAutoloadManager.ImportUserConfigurations(userSettingsFile, overwriteExisting)
	print("UAL - IMPORT USER CONFIGS")

	if g_currentMission.isMultiplayer then
		print("Custom configurations are not supported in multiplayer")
		return
	end

	if not fileExists(userSettingsFile) then
		print("CREATING user settings file")
		-- local defaultSettingsFile = Utils.getFilename("config/UniversalAutoload.xml", UniversalAutoload.path)
		-- copyFile(defaultSettingsFile, userSettingsFile, false)
	end

	UniversalAutoloadManager.ImportGlobalSettings(userSettingsFile, overwriteExisting)
	UniversalAutoloadManager.ImportVehicleConfigurations(userSettingsFile, overwriteExisting)
	
end
--
function UniversalAutoloadManager.ImportGlobalSettings(xmlFilename, overwriteExisting)
	print("UAL - IMPORT GLOBAL SETTINGS")

	if g_currentMission:getIsServer() then

		local xmlFile = UniversalAutoloadManager.openUserSettingsXMLFile(xmlFilename)
		
		if xmlFile ~= 0 and xmlFile ~= nil then
		
			if overwriteExisting or not UniversalAutoload.globalSettingsLoaded then
				print("IMPORT Universal Autoload global settings")
				UniversalAutoload.globalSettingsLoaded = true

				iterateDefaultsTable(UniversalAutoload.GLOBAL_DEFAULTS, UniversalAutoload.globalKey, "", UniversalAutoload,
				function(k, v, parentKey, currentKey, finalValue)
					UniversalAutoload[v.id] = xmlFile:getValue(parentKey..currentKey, v.default)
					print("  >> " .. tostring(v.id) .. ": " .. tostring(v.default))
				end)
			end

			xmlFile:delete()
		else
			print("Universal Autoload - could not open global settings file")
		end
	else
		print("Universal Autoload - global settings are only loaded for the server")
	end
end
--
function UniversalAutoloadManager.ImportVehicleConfigurations(xmlFilename, overwriteExisting)
	print("UAL - IMPORT VEHICLE CONFIGS")

	local xmlFile = UniversalAutoloadManager.openUserSettingsXMLFile(xmlFilename)
	
	if xmlFile then
		print("IMPORT user vehicle configurations")
		local i = 0
		while true do
			local vehicleKey = string.format(UniversalAutoload.vehicleKey, i)
			if not xmlFile:hasProperty(vehicleKey) then
				break
			end
			
			local configFileName = xmlFile:getValue(vehicleKey .. "#configFileName")
			if UniversalAutoloadManager.getValidXmlName(configFileName) then
				print(" [" .. i + 1 .. "] " .. configFileName)
				
				local j = 0
				while true do
					local configKey = vehicleKey .. string.format(".configuration(%d)", j)
					if not xmlFile:hasProperty(configKey) then
						break
					end
					
					local configuration = UniversalAutoloadManager.getVehicleConfigFromSettingsXML(configKey, xmlFile)
					if not configuration then
						print("could not load UAL configuration for: " .. configKey)
					end

					if not UniversalAutoload.VEHICLE_CONFIGURATIONS[configFileName] then
						print("ADDING SHOP ITEM " .. configFileName)
						UniversalAutoload.VEHICLE_CONFIGURATIONS[configFileName] = {}
						table.addElement(g_storeManager:getPackItems("UNIVERSALAUTOLOAD"), configFileName)
					end
					
					local configGroup = UniversalAutoload.VEHICLE_CONFIGURATIONS[configFileName]
					local selectedConfigs = xmlFile:getValue(configKey.."#selectedConfigs", UniversalAutoload.ALL)
					local useConfigName = xmlFile:getValue(configKey.."#useConfigName", nil)

					if not configGroup[selectedConfigs] or overwriteExisting then
						configuration.configFileName = configFileName
						configuration.useConfigName = useConfigName
						configuration.selectedConfigs = selectedConfigs
						configGroup[selectedConfigs] = configuration
					else
						if UniversalAutoload.showDebug then print("  ALREADY EXISTS: "..configFileName.." ("..selectedConfigs..")") end
					end

					if not configuration.showDebug then
						print("  >> "..configFileName.." ("..selectedConfigs..")")
					else
						print("  >> "..configFileName.." ("..selectedConfigs..") DEBUG")
					end

					j = j + 1
				end
				
			else
				if UniversalAutoload.showDebug then print("  NOT FOUND: " .. tostring(configFileName)) end
			end

			i = i + 1
		end
		
		xmlFile:delete()
		
		return i
	end

end

function UniversalAutoloadManager.getValidConfigurationId(vehicle, useConfigName)
	-- returns: configId, configName, description
	-- configId = new configId for stored configuration
	-- configName = configuration name to use (or nil)
	-- description = text to use for display
	
	local item = g_storeManager:getItemByXMLFilename(vehicle.configFileName)
	if not item then
		print("could not get store item for " .. tostring(vehicle.configFileName))
		return
	end
	
	local configName = useConfigName or 'design'
	local nConfigs = #(item.configurations or {})
	local nConfigSets = #(item.configurationSets or {})
	-- print("#configurations " .. nConfigs)
	-- print("#configurationSets " .. nConfigSets)

	if useConfigName or nConfigSets == 0 then
		if not vehicle.configurations[configName] or nConfigs == 0 then
			return "ALL", nil, "UNIQUE"
		else
			return vehicle.configurations[configName], configName, "USE CONFIG"
		end
	else
		local best = {
			count = 0
		}
		for i, config in pairs(item.configurationSets) do
			local count = 0
			local match = true
			for k, v in pairs(config.configurations or {}) do
				if vehicle.configurations[k] == v then
					count = count + 1
				else
					match = false
				end
			end
			if match then
				return i, nil, config.name
			else
				if best.count < count then
					best.index = i
					best.count = count
					best.name = config.name
				end
			end
		end
		return best.index, nil, best.name
	end
end

function UniversalAutoloadManager.saveShopConfiguration()
	print("UAL - SAVE SHOP CONFIGURATION")
	
	if UniversalAutoloadManager.shopVehicle and UniversalAutoloadManager.shopConfig then

		local vehicle = UniversalAutoloadManager.shopVehicle
		local spec = UniversalAutoloadManager.shopVehicle.spec_universalAutoload
		
		if g_currentMission:getIsServer() and spec and spec.isInsideShop then
			print("EXPORT SHOP VEHICLE SETTINGS: " .. vehicle:getFullName())
			UniversalAutoloadManager.saveVehicleConfigToSettingsXML(vehicle)
		end
		
		UniversalAutoloadManager.shopConfig = nil
	end
end

function UniversalAutoloadManager:onVehicleBuyEvent(errorCode)
	if errorCode == BuyVehicleEvent.STATE_SUCCESS then
		print("UAL - ON VEHICLE BUY EVENT")
		UniversalAutoloadManager.saveShopConfiguration()
	end
end

function UniversalAutoloadManager.getValidXmlName(ualConfigName)

	if ualConfigName == nil then
		return
	end
	
	local xmlFilename = ualConfigName
	if g_storeManager:getItemByXMLFilename(xmlFilename) then
		return xmlFilename
	end
	
	xmlFilename = g_modsDirectory..ualConfigName
	if g_storeManager:getItemByXMLFilename(xmlFilename) then
		return xmlFilename
	end
	
	for i = 1, #g_dlcsDirectories do
		local dlcsDir = g_dlcsDirectories[i].path
		xmlFilename = dlcsDir..ualConfigName
		if g_storeManager:getItemByXMLFilename(xmlFilename) then
			return xmlFilename
		end
	end

end

function UniversalAutoloadManager.injectSpecialisation()
	print("UAL - INJECT SPEC:")
	for typeName, vehicleType in pairs(g_vehicleTypeManager.types) do
		if SpecializationUtil.hasSpecialization(TensionBelts, vehicleType.specializations)
		and not SpecializationUtil.hasSpecialization(UniversalAutoload, vehicleType.specializations) then
			g_vehicleTypeManager:addSpecialization(typeName, UniversalAutoload.name .. '.universalAutoload')
			UniversalAutoload.VEHICLE_TYPES[typeName] = true
		end
	end
end

function UniversalAutoloadManager.injectMenu()
	print("UAL - INJECT MENU")
	
	local function fixInGameMenu(frame, pageName, position, predicateFunc)
		local inGameMenu = g_gui.screenControllers[InGameMenu] --g_inGameMenu
		local aboveSettings = nil;

		--DebugUtil.printTableRecursively(inGameMenu.pagingElement)

		-- remove all to avoid warnings
		for k, v in pairs({pageName}) do
			inGameMenu.controlIDs[v] = nil
		end

		for i = 1, #inGameMenu.pagingElement.elements do
			local child = inGameMenu.pagingElement.elements[i]
			if child == inGameMenu["pageSettings"] then
				aboveSettings = i;
				print("--- found Settings position - "..tostring(i))
			end
		end
		aboveSettings = aboveSettings or position
		
		inGameMenu[pageName] = frame
		inGameMenu.pagingElement:addElement(inGameMenu[pageName])

		inGameMenu:exposeControlsAsFields(pageName)

		for i = 1, #inGameMenu.pagingElement.elements do
			local child = inGameMenu.pagingElement.elements[i]
			if child == inGameMenu[pageName] then
				table.remove(inGameMenu.pagingElement.elements, i)
				table.insert(inGameMenu.pagingElement.elements, aboveSettings, child)
				break
			end
		end

		for i = 1, #inGameMenu.pagingElement.pages do
			local child = inGameMenu.pagingElement.pages[i]
			if child.element == inGameMenu[pageName] then
				table.remove(inGameMenu.pagingElement.pages, i)
				table.insert(inGameMenu.pagingElement.pages, aboveSettings, child)
				break
			end
		end

		inGameMenu.pagingElement:updateAbsolutePosition()
		inGameMenu.pagingElement:updatePageMapping()
		
		inGameMenu:registerPage(inGameMenu[pageName], position, predicateFunc)
		local iconFileName = Utils.getFilename('gui/menu_modSettings.dds', UniversalAutoload.path)
		inGameMenu:addPageTab(inGameMenu[pageName], iconFileName, GuiUtils.getUVs({0,0,1024,1024}))

		for i = 1, #inGameMenu.pageFrames do
			local child = inGameMenu.pageFrames[i]
			if child == inGameMenu[pageName] then
				table.remove(inGameMenu.pageFrames, i)
				table.insert(inGameMenu.pageFrames, aboveSettings, child)
				break
			end
		end

		inGameMenu:rebuildTabList()
	end

	local guiUALSettings = InGameMenuUALSettings.new(g_i18n)
	g_gui:loadGui(UniversalAutoload.path .. "gui/InGameMenuUALSettings.xml", "inGameMenuUALSettings", guiUALSettings, true)
	
	local function isEnabledPredicate()
		return function () return true end
	end
	fixInGameMenu(guiUALSettings,"inGameMenuUALSettings", 2, isEnabledPredicate())
	
end

function UniversalAutoloadManager:mouseEvent(posX, posY, isDown, isUp, button)
	
	if UniversalAutoloadManager.shopVehicle then

		local spec = UniversalAutoloadManager.shopVehicle.spec_universalAutoload
		if spec and spec.isInsideShop then
			local shopConfig = UniversalAutoloadManager.shopConfig or {}
			
			if button == 2 and isDown then
				UniversalAutoloadManager.pauseOnNextStep = nil
				local ctrl = UniversalAutoloadManager.ctrlHeld
				local shift = UniversalAutoloadManager.shiftHeld
				if shift and ctrl then
					spec.resetToDefault = true
				else
					shopConfig.enableEditing = shopConfig.enableEditing or false
					shopConfig.enableEditing = not shopConfig.enableEditing
				end
			end
			
			if button == 3 and isUp then
				shopConfig.selected = nil
			end

			if spec.loadingVolume and spec.loadingVolume.state == LoadingVolume.STATE.SHOP_CONFIG then
				
				local function isPointSelected(point)
					local sx, sy, _ = project(point[1], point[2], point[3])		
					if math.abs(posX - sx) < 0.005 and math.abs(posY - sy) < 0.005 then
						return true
					end
				end

				
				for n, bb in pairs(spec.loadingVolume.bbs) do
					local centre, points, names = bb:getCubeFaces()
					for i, point in pairs(points or {}) do

						if isPointSelected(point) then
							if button == 3 and isDown then
								shopConfig.selected = {n, i}
								shopConfig.control = UniversalAutoloadManager.ctrlHeld or false
								shopConfig.shift = UniversalAutoloadManager.shiftHeld or false
								shopConfig.alt = UniversalAutoloadManager.altHeld or false
							else
								if not shopConfig.grabbedPoint then
									shopConfig.hovered = {n, i}
								end
							end
						else
							local hovered = shopConfig.hovered
							if hovered and n==hovered[1] and i==hovered[2] then
								shopConfig.hovered = {0, 0}
							end
						end
					end
				end

				shopConfig.mousePos = {posX, posY}

			end
		end
	end
	
end

function UniversalAutoloadManager:keyEvent(unicode, sym, modifier, isDown)

	if UniversalAutoloadManager.shopVehicle and UniversalAutoloadManager.shopConfig then
		
		local spec = UniversalAutoloadManager.shopVehicle.spec_universalAutoload
		if spec and spec.isInsideShop then
			-- print("KEY: " .. tostring(sym) .. " + " .. tostring(modifier))
			if sym == 308 then
				UniversalAutoloadManager.altHeld = isDown
			end
			if sym == 306 then
				UniversalAutoloadManager.ctrlHeld = isDown
			end
			if sym == 304 then
				UniversalAutoloadManager.shiftHeld = isDown
			end
		end
	end

end

-- AUTO CREATE LOADING VOLUMES
function UniversalAutoloadManager.editLoadingVolumeInsideShop(vehicle)
	local spec = vehicle.spec_universalAutoload
	
	if spec.loadingVolume.state == LoadingVolume.STATE.SHOP_CONFIG then
		
		local shopConfig = UniversalAutoloadManager.shopConfig
		if not shopConfig or not shopConfig.enableEditing then
			return
		end
		
		local selected = shopConfig.selected
		local mousePos = shopConfig.mousePos
		local ctrlHeld = shopConfig.control
		local shiftHeld = shopConfig.shift
		local altHeld = shopConfig.alt

		if selected and mousePos and selected[1] > 0 and selected[2] > 0 then
			local n = selected[1]
			local i = selected[2]
			local X = mousePos[1]
			local Y = mousePos[2]
			
			local bb = spec.loadingVolume.bbs[n]
			local centre, points, names = bb:getCubeFaces()
			
			if UniversalAutoloadManager.shopConfig.grabbedPoint == nil then
				UniversalAutoloadManager.shopConfig.grabbedPoint = points[i]
				UniversalAutoloadManager.shopConfig.originalPoint = {points[i][1], points[i][2], points[i][3]}
				UniversalAutoloadManager.shopConfig.clickOffset = nil
			end

			local function expandAxis(p1, p2, showAxis)
				-- Get camera position and points in world space
				local camX, camY, camZ = getWorldTranslation(getCamera())
				local grabbedPoint = UniversalAutoloadManager.shopConfig.grabbedPoint
				local pX, pY, pZ = unpack(grabbedPoint)
				local lx1, ly1, lz1 = unpack(p1)
				local lx2, ly2, lz2 = unpack(p2)
				
				-- Calculate normalized direction and distance
				local lineDx, lineDy, lineDz = MathUtil.vector3Normalize(lx2-lx1, ly2-ly1, lz2-lz1)
				local distance = MathUtil.vector3Length(pX-camX, pY-camY, pZ-camZ)

				-- Adjust mouse position based on ctrlHeld for finer control
				local mouseX, mouseY, mouseZ = unProject(X, Y, distance / 10)
				if ctrlHeld then
					local scale = 0.35
					local pX0, pY0, pZ0 = unpack(UniversalAutoloadManager.shopConfig.originalPoint)
					mouseX = pX0 + (mouseX - pX0) * scale
					mouseY = pY0 + (mouseY - pY0) * scale
					mouseZ = pZ0 + (mouseZ - pZ0) * scale
				end
				
				-- Calculate normalized mouse direction and camera-to-line vector
				local mouseDx, mouseDy, mouseDz = MathUtil.vector3Normalize(mouseX - camX, mouseY - camY, mouseZ - camZ)
				local camToLineX, camToLineY, camToLineZ = pX - camX, pY - camY, pZ - camZ

				-- Calculate s and t parameters for closest points
				local dotMouseRayLine = mouseDx * lineDx + mouseDy * lineDy + mouseDz * lineDz
				local denom = 1 - dotMouseRayLine ^ 2
				local s = (dotMouseRayLine * (camToLineX * lineDx + camToLineY * lineDy + camToLineZ * lineDz) 
						   - (camToLineX * mouseDx + camToLineY * mouseDy + camToLineZ * mouseDz)) / denom
				local t = dotMouseRayLine * s + (camToLineX * lineDx + camToLineY * lineDy + camToLineZ * lineDz)

				-- Determine new points based on s and t values
				local mouseRayX, mouseRayY, mouseRayZ = camX - s * mouseDx, camY - s * mouseDy, camZ - s * mouseDz
				local newPointX, newPointY, newPointZ = pX - t * lineDx, pY - t * lineDy, pZ - t * lineDz

				-- Visualize axis and debug lines if required
				if showAxis then
					drawDebugLine(p1[1], p1[2], p1[3], 1, 0.5, 1, p2[1], p2[2], p2[3], 1, 0.5, 1)
				end
				if showDebug then
					drawDebugLine(camX, camY-0.02, camZ, 1, 0, 0, p1[1], p1[2], p1[3], 1, 0, 0)
					drawDebugLine(camX, camY-0.02, camZ, 0, 1, 0, newPointX, newPointY, newPointZ, 0, 1, 0)
					drawDebugLine(newPointX, newPointY, newPointZ, 1, 1, 1, mouseRayX, mouseRayY, mouseRayZ, 1, 1, 1)
				end
				
				-- Offset calculation with existing click offset
				if not UniversalAutoloadManager.shopConfig.clickOffset then
					UniversalAutoloadManager.shopConfig.clickOffset = {newPointX-pX, newPointY-pY, newPointZ-pZ}
				end
				local cX, cY, cZ = unpack(UniversalAutoloadManager.shopConfig.clickOffset)
				return newPointX-pX-cX, newPointY-pY-cY, newPointZ-pZ-cZ

			end
			
			local function handleAxisMovement(i, bb, points, altHeld, shiftHeld)
				local axisPairs = {
					{1, 2}, -- left/right
					{2, 1}, -- right/left
					{3, 4}, -- top/bottom
					{4, 3}, -- bottom/top
					{5, 6}, -- front/back
					{6, 5}  -- back/front
				}

				local dx, dy, dz = expandAxis(points[axisPairs[i][1]], points[axisPairs[i][2]], altHeld or shiftHeld)
				local delta = (i <= 2 and dx) or (i <= 4 and dy) or dz
				
				if not shiftHeld and not altHeld then
					bb:moveFace(i, delta)
				elseif shiftHeld and not altHeld then
					bb:moveFace(axisPairs[i][1], delta/2)
					bb:moveFace(axisPairs[i][2], delta/2)
				elseif altHeld and not shiftHeld then
					bb:moveFace(axisPairs[i][1], delta/2)
					bb:moveFace(axisPairs[i][2], -delta/2)
				end
			end
			
			handleAxisMovement(i, bb, points, altHeld, shiftHeld)
			
		else
			if UniversalAutoloadManager.shopConfig.grabbedPoint then
				UniversalAutoloadManager.shopConfig.grabbedPoint = nil
				for n, bb in pairs(spec.loadingVolume.bbs) do
					bb:update()
				end
			end
		end
	end
end

function UniversalAutoloadManager.createLoadingVolumeInsideShop(vehicle)
	local spec = vehicle.spec_universalAutoload
	
	if not spec.skipFirstUpdate then
		spec.skipFirstUpdate = true
		return
	end
	
	if UniversalAutoloadManager.pauseOnNextStep then
		return
	end
	
	if not spec.loadingVolume then
		print("findTensionBelts")
		spec.loadingVolume = LoadingVolume.new(vehicle)
		spec.loadingVolume:findTensionBelts()
		UniversalAutoloadManager.pauseOnNextStep = UniversalAutoloadManager.DEBUG_STEPS
	elseif spec.loadingVolume.state == LoadingVolume.STATE.FOUND_BELTS then
		print("findLoadingSurface")
		spec.loadingVolume:findLoadingSurface()
		UniversalAutoloadManager.pauseOnNextStep = UniversalAutoloadManager.DEBUG_STEPS
	elseif spec.loadingVolume.state == LoadingVolume.STATE.FOUND_SURFACE then
		print("expandLoadingSurface")
		spec.loadingVolume:expandLoadingSurface()
		UniversalAutoloadManager.pauseOnNextStep = UniversalAutoloadManager.DEBUG_STEPS
	elseif spec.loadingVolume.state == LoadingVolume.STATE.EXPANDED then
		print("INIT SHOP CONFIG")
		spec.loadingVolume:initShopConfig()
		UniversalAutoloadManager.pauseOnNextStep = nil
	end
	
end

function UniversalAutoloadManager.importLoadingVolume(vehicle, config)
	local spec = vehicle.spec_universalAutoload
	
	if not spec.skipFirstUpdate then
		spec.skipFirstUpdate = true
		return
	end

	if spec.loadArea and not spec.loadingVolume then
		print("CONVERT IMPORTED LOCAL CONFIG TO LOADING VOLUME")
		spec.loadingVolume = LoadingVolume.new(vehicle)
		
		for i, loadArea in ipairs(spec.loadArea) do
			local width = loadArea.width
			local height = loadArea.height
			local length = loadArea.length
			local offset = loadArea.offset

			local boundingBox = BoundingBox.new(vehicle.rootNode,
				{x=width, y=height, z=length},
				{x=offset[1], y=offset[2] + height/2, z=offset[3]}
			)
			spec.loadingVolume.bbs[i] = boundingBox
		end

		spec.loadingVolume:initShopConfig()
		UniversalAutoloadManager.pauseOnNextStep = nil
	end
	
end

-- IMPORT CONTAINER TYPE DEFINITIONS
function UniversalAutoloadManager.ImportContainerTypeConfigurations(xmlFilename, overwriteExisting)

	local i = 0
	local xmlFile = UniversalAutoloadManager.openUserSettingsXMLFile(xmlFilename)
	if xmlFile ~= 0 then
	
		local containerRootKey = "universalAutoload.containerConfigurations"
		local legacyContainerRootKey = "universalAutoload.containerTypeConfigurations"
		if not xmlFile:hasProperty(containerRootKey) and xmlFile:hasProperty(legacyContainerRootKey) then
			print("*** OLD VERSION OF CONFIG FILE DETECTED - please use <containerConfigurations> ***")
			containerRootKey = legacyContainerRootKey
		end

		while true do
			local configKey = string.format(containerRootKey..".containerConfiguration(%d)", i)
			
			if not xmlFile:hasProperty(configKey) then
				break
			end

			local containerType = xmlFile:getValue(configKey.."#containerType", "ALL")
			if tableContainsValue(UniversalAutoload.CONTAINERS, containerType) then
			
				local default = UniversalAutoload[containerType] or {}

				local name = xmlFile:getValue(configKey.."#name")
				local customEnvironment, _ = name:match( "^(.-):(.+)$" )
				if customEnvironment==nil or g_modIsLoaded[customEnvironment] then
					local config = UniversalAutoload.LOADING_TYPES[name]
					if config == nil or overwriteExisting then
						UniversalAutoload.LOADING_TYPES[name] = {}
						newType = UniversalAutoload.LOADING_TYPES[name]
						newType.name = name
						newType.type = containerType
						newType.containerIndex = UniversalAutoload.CONTAINERS_LOOKUP[containerType] or 1
						newType.sizeX = xmlFile:getValue(configKey.."#sizeX", default.sizeX or 1.5)
						newType.sizeY = xmlFile:getValue(configKey.."#sizeY", default.sizeY or 1.5)
						newType.sizeZ = xmlFile:getValue(configKey.."#sizeZ", default.sizeZ or 1.5)
						newType.isBale = xmlFile:getValue(configKey.."#isBale", default.isBale or false)
						newType.flipYZ = xmlFile:getValue(configKey.."#flipYZ", default.flipYZ or false)
						newType.neverStack = xmlFile:getValue(configKey.."#neverStack", default.neverStack or false)
						newType.neverRotate = xmlFile:getValue(configKey.."#neverRotate", default.neverRotate or false)
						newType.alwaysRotate = xmlFile:getValue(configKey.."#alwaysRotate", default.alwaysRotate or false)
						newType.frontOffset = xmlFile:getValue(configKey.."#frontOffset", default.frontOffset or 0)
						print(string.format("  >> %s %s [%.3f, %.3f, %.3f]", newType.type, newType.name, newType.sizeX, newType.sizeY, newType.sizeZ ))
					end				
				end

			else
				if UniversalAutoload.showDebug then print("  UNKNOWN CONTAINER TYPE: "..tostring(containerType)) end
			end

			i = i + 1
		end

		xmlFile:delete()
	end
	return i

end
--

-- DETECT CONFLICTS/ISSUES
function UniversalAutoloadManager.detectKeybindingConflicts()
	--DETECT 'T' KEYS CONFLICT
	if g_currentMission.missionDynamicInfo.isMultiplayer and not g_dedicatedServer then

		local chatKey = ""
		local containerKey = "KEY_t"
		local xmlFile = loadXMLFile('TempXML', g_inputBinding.settingsPath)	
		local actionBindingCounter = 0
		if xmlFile ~= 0 then
			while true do
				local key = string.format('inputBinding.actionBinding(%d)', actionBindingCounter)
				local actionString = getXMLString(xmlFile, key .. '#action')
				if actionString == nil then
					break
				end
				if actionString == 'CHAT' then
					local i = 0
					while true do
						local bindingKey = key .. string.format('.binding(%d)',i)
						local bindingInput = getXMLString(xmlFile, bindingKey .. '#input')
						if bindingInput == "KEY_t" then
							print("  Using 'KEY_t' for 'CHAT'")
							chatKey = bindingInput
						elseif bindingInput == nil then
							break
						end

						i = i + 1
					end
				end
				
				if actionString == 'UNIVERSALAUTOLOAD_CYCLE_CONTAINER_FW' then
					local i = 0
					while true do
						local bindingKey = key .. string.format('.binding(%d)',i)
						local bindingInput = getXMLString(xmlFile, bindingKey .. '#input')
						if bindingInput ~= nil then
							print("  Using '"..bindingInput.."' for 'CYCLE_CONTAINER'")
							containerKey = bindingInput
						elseif bindingInput == nil then
							break
						end

						i = i + 1
					end
				end
				
				actionBindingCounter = actionBindingCounter + 1
			end
		end
		delete(xmlFile)
		
		if chatKey == containerKey then
			print("**CHAT KEY CONFLICT DETECTED** - Disabling CYCLE_CONTAINER for Multiplayer")
			print("(Please reassign 'CHAT' or 'CYCLE_CONTAINER' to a different key and RESTART the game)")
			UniversalAutoload.chatKeyConflict = true
		end
		
	end
end

-- CONSOLE FUNCTIONS
function UniversalAutoloadManager:consoleResetVehicles()

	if g_gui.currentGuiName == "ShopMenu" or g_gui.currentGuiName == "ShopConfigScreen" then
		return "Reset vehicles is not supported while in shop!"
	end
	
	UniversalAutoloadManager.resetList = {}
	UniversalAutoloadManager.resetCount = 1
	g_currentMission.isReloadingVehicles = true
	
	for _, vehicle in pairs(UniversalAutoload.VEHICLES) do
		table.insert(UniversalAutoloadManager.resetList, vehicle)
	end
	UniversalAutoload.VEHICLES = {}
	print(string.format("Resetting %d vehicles now..", #UniversalAutoloadManager.resetList))
	
	UniversalAutoloadManager.resetNextVehicle()
	
end
--
-- function UniversalAutoloadManager:consoleImportUserConfigurations()

	-- local oldVehicleConfigurations = deepCopy(UniversalAutoload.VEHICLE_CONFIGURATIONS)
	-- local oldContainerConfigurations = deepCopy(UniversalAutoload.LOADING_TYPES)
	-- local userSettingsFile = Utils.getFilename(UniversalAutoload.userSettingsFile, getUserProfileAppPath())
	-- local vehicleCount, objectCount = UniversalAutoloadManager.ImportUserConfigurations(userSettingsFile, true)
	
	-- g_currentMission.isReloadingVehicles = true
	-- if vehicleCount > 0 then
		-- vehicleCount = 0
		-- local doResetVehicle = false
		-- for key, configGroup in pairs(UniversalAutoload.VEHICLE_CONFIGURATIONS) do
			-- local foundFirstMatch = false
			-- for index, config in pairs(configGroup) do
				-- if oldVehicleConfigurations[key] and oldVehicleConfigurations[key][index]
				-- and not deepCompare(oldVehicleConfigurations[key][index], config) then
					-- -- FIRST LOOK IF THIS IS THE CURRENT CONTROLLED VECHILE
					-- for _, vehicle in pairs(UniversalAutoload.VEHICLES) do
						-- -- print(vehicle.configFileName .. " - " .. tostring(vehicle.spec_universalAutoload.boughtConfig) .. " / " .. index)
						-- if string.find(vehicle.configFileName, key) and vehicle.spec_universalAutoload.boughtConfig == index then
							-- local rootVehicle = vehicle:getRootVehicle()
							-- if rootVehicle == g_currentMission.controlledVehicle then
								-- foundFirstMatch = true
								-- print("APPLYING UPDATED SETTINGS: " .. vehicle:getFullName())
								-- if not UniversalAutoloadManager.resetVehicle(vehicle) then
									-- print("THIS IS CURRENT CONTROLLED VEHICLE: " .. vehicle:getFullName())
									-- doResetVehicle = true
								-- end
							-- end
						-- end
					-- end
					-- -- THEN CHECK ALL THE OTHERS - but we can only reset one at a time
					-- for _, vehicle in pairs(UniversalAutoload.VEHICLES) do
						-- if string.find(vehicle.configFileName, key) and vehicle.spec_universalAutoload.boughtConfig == index then
							-- if not foundFirstMatch then
								-- foundFirstMatch = true
								-- vehicleCount = vehicleCount + 1
								-- print("APPLYING UPDATED SETTINGS: " .. vehicle:getFullName())
								-- if not UniversalAutoloadManager.resetVehicle(vehicle) then
									-- doResetVehicle = true
								-- end
							-- else
								-- print("ONLY ONE OF EACH VEHICLE CONFIGURATION CAN BE RESET USING THIS COMMAND")
							-- end
						-- end
					-- end
				-- end
			-- end
		-- end
		-- if doResetVehicle then
			-- g_currentMission:consoleCommandReloadVehicle()
		-- else
			-- g_currentMission.isReloadingVehicles = false
		-- end
	-- end
	
	-- if objectCount > 0 then
		-- objectCount = 0
		-- for key, value in pairs(UniversalAutoload.LOADING_TYPES) do
			-- if not deepCompare(oldContainerConfigurations[key], value) then
				-- objectCount = objectCount + 1
			-- end
		-- end
	-- end
	
	-- if vehicleCount > 0 and objectCount == 0 then
		-- return string.format("UPDATED: %d vehicle configurations", vehicleCount)
	-- end
	-- if objectCount > 0 and vehicleCount == 0 then
		-- return string.format("UPDATED: %d container configurations", objectCount)
	-- end
	-- return string.format("UPDATED: %d vehicle configurations, %d container configurations", vehicleCount, objectCount)
-- end
--
-- function UniversalAutoloadManager:consoleAddPallets(palletType)

	-- local pallets = {}
	-- for _, fillType in pairs(g_fillTypeManager:getFillTypes()) do
		-- local xmlName = fillType.palletFilename
		-- if xmlName ~= nil and not xmlName:find("fillablePallet") then
			-- pallets[fillType.name] = xmlName
		-- end
	-- end
		
	-- if palletType then
		-- palletType = string.upper(palletType or "")
		-- local xmlFilename = pallets[palletType]
		-- if xmlFilename == nil then
			-- return "Error: Invalid pallet type. Valid types are " .. table.concatKeys(pallets, ", ")
		-- end

		-- pallets = {}
		-- pallets[palletType] = xmlFilename
	-- end
	
	-- if g_currentMission.controlledVehicle ~= nil then

		-- local vehicles = UniversalAutoloadManager.getAttachedVehicles(g_currentMission.controlledVehicle)
		-- local count = 0
		
		-- if next(vehicles) ~= nil then
			-- for vehicle, hasAutoload in pairs(vehicles) do
				-- if hasAutoload and vehicle:getIsActiveForInput() then
					-- if UniversalAutoload.createPallets(vehicle, pallets) then
						-- count = count + 1
					-- end
				-- end
			-- end
		-- end
	
		-- if count>0 then return "Begin adding pallets now.." end
	-- end
	-- return "Please enter a vehicle with a UAL trailer attached to use this command"
-- end
--
-- function UniversalAutoloadManager:consoleAddLogs(arg1, arg2)

	-- local length = nil
	-- local treeTypeName = "PINE"
	
	-- if tonumber(arg1) then
		-- length = tonumber(arg1)
		-- treeTypeName = arg2
	-- elseif tonumber(arg2) then
		-- length = tonumber(arg2)
		-- treeTypeName = arg1
	-- elseif arg1 ~= nil then
		-- treeTypeName = arg1
	-- end
	
	-- local availableLogTypes

	-- if not g_modIsLoaded["pdlc_forestryPack"] then
		-- availableLogTypes = {
			-- OAK = 3.5,
			-- ELM = 3.5,
			-- PINE = 30,
			-- BIRCH = 5,
			-- MAPLE = 2,
			-- POPLAR = 18,
			-- SPRUCE = 34,
			-- WILLOW = 2.5,
			-- CYPRESS = 2.5,
			-- HICKORY = 4.2,
			-- STONEPINE = 8,
		-- }
	-- else
		-- availableLogTypes = {
			-- OAK = 3.5,
			-- ELM = 3.5,
			-- PINE = 30,
			-- BIRCH = 5,
			-- MAPLE = 2,
			-- POPLAR = 18,
			-- SPRUCE = 34,
			-- WILLOW = 2.5,
			-- CYPRESS = 2.5,
			-- HICKORY = 4.2,
			-- DEADWOOD = 20,
			-- STONEPINE = 8,
			-- GIANTSEQUOIA = 7,
			-- PONDEROSAPINE = 32,
			-- LODGEPOLEPINE = 32
		-- }
	-- end

	-- treeTypeName = string.upper(treeTypeName or "")
	-- if availableLogTypes[treeTypeName]==nil then
		-- return "Error: Invalid lumber type. Valid types are " .. table.concatKeys(availableLogTypes, ", ")
	-- end
	
	-- local maxLength = availableLogTypes[treeTypeName]
	-- if treeTypeName == 'ELM' then treeTypeName = 'AMERICANELM' end
	-- if treeTypeName == 'HICKORY' then treeTypeName = 'SHAGBARKHICKORY' end
	-- if length == nil then length = maxLength end
	-- if length > maxLength then
		-- print("using maximum length " .. maxLength .. "m")
		-- length = maxLength
	-- end
	
	-- if g_currentMission.controlledVehicle ~= nil then

		-- local vehicles = UniversalAutoloadManager.getAttachedVehicles(g_currentMission.controlledVehicle)
		-- local count = 0
		
		-- if next(vehicles) ~= nil then
			-- for vehicle, hasAutoload in pairs(vehicles) do
				-- if hasAutoload and vehicle:getIsActiveForInput() then
					-- local maxSingleLength = UniversalAutoload.getMaxSingleLength(vehicle)
					-- if length > maxSingleLength then
						-- length = maxSingleLength - 0.1
						-- print("resizing to fit trailer " .. length .. "m")
					-- end
					-- if UniversalAutoload.createLogs(vehicle, treeTypeName, length) then
						-- count = count + 1
					-- end
				-- end
			-- end
		-- end
	
		-- if count>0 then return "Begin adding logs now.." end
	-- end
	-- return "Please enter a vehicle with a UAL trailer attached to use this command"
-- end
--
-- function UniversalAutoloadManager:consoleAddBales(fillTypeName, isRoundbale, width, height, length, wrapState, modName)
	-- local usage = "ualAddBales fillTypeName isRoundBale [width] [height/diameter] [length] [wrapState] [modName]"

	-- fillTypeName = Utils.getNoNil(fillTypeName, "STRAW")
	-- isRoundbale = Utils.stringToBoolean(isRoundbale)
	-- width = width ~= nil and tonumber(width) or nil
	-- height = height ~= nil and tonumber(height) or nil
	-- length = length ~= nil and tonumber(length) or nil

	-- if wrapState ~= nil and tonumber(wrapState) == nil then
		-- Logging.error("Invalid wrapState '%s'. Number expected", wrapState, usage)

		-- return
	-- end

	-- wrapState = tonumber(wrapState or 0)
	-- local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeName)

	-- if fillTypeIndex == nil then
		-- Logging.error("Invalid fillTypeName '%s' (e.g. STRAW). Use %s", fillTypeName, usage)

		-- return
	-- end

	-- local xmlFilename, _ = g_baleManager:getBaleXMLFilename(fillTypeIndex, isRoundbale, width, height, length, height, modName)

	-- if xmlFilename == nil then
		-- Logging.error("Could not find bale for given size attributes! (%s)", usage)
		-- g_baleManager:consoleCommandListBales()

		-- return
	-- end
	
	-- bale = {}
	-- bale.xmlFile = xmlFilename
	-- bale.fillTypeIndex = fillTypeIndex
	-- bale.wrapState = wrapState
	
	-- if g_currentMission.controlledVehicle ~= nil then

		-- local vehicles = UniversalAutoloadManager.getAttachedVehicles(g_currentMission.controlledVehicle)
		-- local count = 0
		
		-- if next(vehicles) ~= nil then
			-- for vehicle, hasAutoload in pairs(vehicles) do
				-- if hasAutoload and vehicle:getIsActiveForInput() then
					-- if UniversalAutoload.createBales(vehicle, bale) then
						-- count = count + 1
					-- end
				-- end
			-- end
		-- end

		-- if count>0 then return "Begin adding bales now.." end
	-- end
	-- return "Please enter a vehicle with a UAL trailer attached to use this command"
-- end
-- --
-- function UniversalAutoloadManager:consoleAddRoundBales_125(fillTypeName)
	-- return UniversalAutoloadManager:consoleAddBales(fillTypeName or "DRYGRASS_WINDROW", "true", "1.2", "1.25")
-- end
-- --
-- function UniversalAutoloadManager:consoleAddRoundBales_150(fillTypeName)
	-- return UniversalAutoloadManager:consoleAddBales(fillTypeName or "DRYGRASS_WINDROW", "true", "1.2", "1.5")
-- end
-- --
-- function UniversalAutoloadManager:consoleAddRoundBales_180(fillTypeName)
	-- return UniversalAutoloadManager:consoleAddBales(fillTypeName or "DRYGRASS_WINDROW", "true", "1.2", "1.8")
-- end
-- --
-- function UniversalAutoloadManager:consoleAddSquareBales_180(fillTypeName)
	-- return UniversalAutoloadManager:consoleAddBales(fillTypeName or "STRAW", "false", "1.2", "0.9", "1.8")
-- end
-- --
-- function UniversalAutoloadManager:consoleAddSquareBales_220(fillTypeName)
	-- return UniversalAutoloadManager:consoleAddBales(fillTypeName or "STRAW", "false", "1.2", "0.9", "2.2")
-- end
-- --
-- function UniversalAutoloadManager:consoleAddSquareBales_240(fillTypeName)
	-- return UniversalAutoloadManager:consoleAddBales(fillTypeName or "STRAW", "false", "1.2", "0.9", "2.4")
-- end
-- --
-- function UniversalAutoloadManager:consoleClearLoadedObjects()
	
	-- local palletCount, balesCount, logCount = 0, 0, 0
	-- if g_currentMission.controlledVehicle ~= nil then
		-- local vehicles = UniversalAutoloadManager.getAttachedVehicles(g_currentMission.controlledVehicle)
		-- if next(vehicles) ~= nil then
			-- for vehicle, hasAutoload in pairs(vehicles) do
				-- if hasAutoload and vehicle:getIsActiveForInput() then
					-- P, B, L = UniversalAutoload.clearLoadedObjects(vehicle)
					-- palletCount = palletCount + P
					-- balesCount = balesCount + B
					-- logCount = logCount + L
				-- end
			-- end
		-- end
	-- end

	-- if palletCount > 0 and balesCount == 0 and logCount == 0 then
		-- return string.format("REMOVED: %d pallets", palletCount)
	-- end
	-- if balesCount > 0 and palletCount == 0 and logCount == 0 then
		-- return string.format("REMOVED: %d bales", balesCount)
	-- end
	-- if logCount > 0 and palletCount == 0 and balesCount == 0 then
		-- return string.format("REMOVED: %d logs", logCount)
	-- end
	-- return string.format("REMOVED: %d pallets, %d bales, %d logs", palletCount, balesCount, logCount)
-- end
-- --
-- function UniversalAutoloadManager:consoleCreateBoundingBox()
	-- local usage = "Usage: ualCreateBoundingBox"

	-- for _, vehicle in pairs(UniversalAutoload.VEHICLES) do
		-- if vehicle ~= nil then
			-- print("CREATING BOUNDING BOX: " .. vehicle:getFullName())
			-- UniversalAutoload.createBoundingBox(vehicle)
		-- end
	-- end
	-- return "Bounding box created successfully"
-- end
-- --
-- function UniversalAutoloadManager:consoleSpawnTestPallets()
	-- local usage = "Usage: consoleSpawnTestPallets"
	
	-- if g_currentMission.controlledVehicle ~= nil then
	
		-- local vehicles = UniversalAutoloadManager.getAttachedVehicles(g_currentMission.controlledVehicle)
		
		-- if next(vehicles) ~= nil then
			-- for vehicle, hasAutoload in pairs(vehicles) do
				-- if hasAutoload and vehicle:getIsActiveForInput() then

					-- UniversalAutoload.testPallets = {}
					-- UniversalAutoload.testPalletsCount = 0;
					-- for _, fillType in pairs(g_fillTypeManager:getFillTypes()) do
						-- local xmlName = fillType.palletFilename
						-- if xmlName ~= nil and not xmlName:find("fillablePallet") then
							-- print(string.format("%s - %s", fillType, xmlName))
							-- UniversalAutoload.createPallet(vehicle, xmlName)
						-- end
					-- end
					-- return "Test pallets created successfully"
				-- end
			-- end
		-- end
		
		-- -- if next(UniversalAutoload.testPallets) and isActiveForInputIgnoreSelection then
			-- -- if #UniversalAutoload.testPallets == UniversalAutoload.testPalletsCount then
				-- -- print("TEST PALLETS SPAWNED")
				-- -- print(string.format("%s, %s, %s, %s", "name", "volume", "mass", "density"))
				-- -- for _, pallet in pairs(UniversalAutoload.testPallets) do
					-- -- local config = UniversalAutoload.getContainerType(pallet)
					-- -- local mass = UniversalAutoload.getContainerMass(pallet)
					-- -- local volume = config.sizeX * config.sizeY * config.sizeZ
					-- -- print(string.format("%s, %f, %f, %f", config.name, volume, mass, mass/volume))
					-- -- g_currentMission:removeVehicle(pallet, true)
				-- -- end
				-- -- UniversalAutoload.testPallets = {}
			-- -- end
		-- -- end
	-- end
	-- return "Please enter a vehicle with a UAL trailer attached to use this command"
	
-- end
--
function UniversalAutoloadManager.addAttachedVehicles(vehicle, vehicles)

	if vehicle.getAttachedImplements ~= nil then
		local attachedImplements = vehicle:getAttachedImplements()
		for _, implement in pairs(attachedImplements) do
			local spec = implement.object.spec_universalAutoload
			vehicles[implement.object] = spec ~= nil
			UniversalAutoloadManager.addAttachedVehicles(implement.object, vehicles)
		end
	end
	return vehicles
end
--
function UniversalAutoloadManager.getAttachedVehicles(vehicle)
	local vehicles = {}
	local rootVehicle = vehicle:getRootVehicle()
	local spec = rootVehicle.spec_universalAutoload
	vehicles[rootVehicle] = spec ~= nil
	UniversalAutoloadManager.addAttachedVehicles(rootVehicle, vehicles)
	return vehicles
end

-- 
function UniversalAutoloadManager.resetNextVehicle()

	local resetList = UniversalAutoloadManager.resetList
	if resetList ~= nil and next(resetList) ~= nil then
		local vehicle = resetList[#resetList]
		table.remove(resetList, #resetList)
		if not UniversalAutoloadManager.resetVehicle(vehicle) then
			UniversalAutoloadManager.resetCount = UniversalAutoloadManager.resetCount + 1
			UniversalAutoloadManager.resetControlledVehicle = true
			UniversalAutoloadManager.resetNextVehicle()
		end
	else
		if UniversalAutoloadManager.resetControlledVehicle then
			UniversalAutoloadManager.resetControlledVehicle = false
			g_currentMission:consoleCommandReloadVehicle()
			g_currentMission.isReloadingVehicles = true
		else
			g_currentMission.isReloadingVehicles = false
		end
		UniversalAutoloadManager.resetCount = nil
	end
end
--
function UniversalAutoloadManager.resetVehicle(vehicle)
	print("UAL - RESET vehicle")
	if UniversalAutoloadManager.resetCount then
		print(string.format("RESETTING #%d: %s", UniversalAutoloadManager.resetCount, vehicle:getFullName()))
	else
		print(string.format("RESETTING: %s", vehicle:getFullName()))
	end

	local rootVehicle = vehicle:getRootVehicle()
	if rootVehicle ~= nil then
		print("ROOT VEHICLE: " .. rootVehicle:getFullName())
		if rootVehicle:getFullName():find("Locomotive") then
			print("*** CANNOT RESET TRAIN - terrible things will happen ***")
			if UniversalAutoloadManager.resetCount then
				UniversalAutoloadManager.resetNextVehicle()
			end
			return true
		end
		if rootVehicle == g_currentMission.controlledVehicle then
			print("*** Resetting with standard console command ***")
			UniversalAutoload.clearLoadedObjects(vehicle)
			return false
		end
	end
	
	UniversalAutoload.clearLoadedObjects(vehicle)

	local xmlFile = Vehicle.getReloadXML(vehicle)
	local key = "vehicles.vehicle(0)"

	if xmlFile ~= nil and xmlFile ~= 0 then
		local function asyncCallbackFunction(_, newVehicle, vehicleLoadState, arguments)
			if vehicleLoadState == VehicleLoadingUtil.VEHICLE_LOAD_OK then
				g_messageCenter:publish(MessageType.VEHICLE_RESET, vehicle, newVehicle)
				g_currentMission:removeVehicle(vehicle)
				if UniversalAutoloadManager.resetCount then
					UniversalAutoloadManager.resetCount = UniversalAutoloadManager.resetCount + 1
				end
			else
				if vehicleLoadState == VehicleLoadingUtil.VEHICLE_LOAD_ERROR then
					print(" >> VEHICLE_LOAD_ERROR")
				end
				if vehicleLoadState == VehicleLoadingUtil.VEHICLE_LOAD_DELAYED then
					print(" >> VEHICLE_LOAD_DELAYED")
				end
				if vehicleLoadState == VehicleLoadingUtil.VEHICLE_LOAD_NO_SPACE then
					print(" >> There was no space available at the shop")
				end
				if vehicle ~= nil then
					print("ERROR RESETTING OLD VEHICLE: " .. vehicle:getFullName())
					--g_currentMission:removeVehicle(vehicle)
				end
				if newVehicle ~= nil then
					print("ERROR RESETTING NEW VEHICLE: " .. newVehicle:getFullName())
					--g_currentMission:removeVehicle(newVehicle)
				end
			end
			
			xmlFile:delete()
			UniversalAutoloadManager.resetNextVehicle()
		end
		
		VehicleLoadingUtil.loadVehicleFromSavegameXML(xmlFile, key, true, true, nil, true, asyncCallbackFunction, nil, {})
		--(xmlFile, key, resetVehicle, allowDelayed, xmlFilename, keepPosition, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)

	end
	return true
end
--

function UniversalAutoloadManager.consoleFullTest()

	UniversalAutoloadManager.runFullTest = true

end

-- MAIN LOAD MAP FUNCTION
function UniversalAutoloadManager:loadMap(name)
	print("UAL - LOADMAP")
	-- UniversalAutoloadManager.injectMenu()
	UniversalAutoloadManager.injectSpecialisation()
	
	g_messageCenter:subscribe(BuyVehicleEvent, UniversalAutoloadManager.onVehicleBuyEvent, UniversalAutoloadManager)

	UniversalAutoload.CONTAINERS_LOOKUP = {}
	for i, key in ipairs(UniversalAutoload.CONTAINERS) do
		UniversalAutoload.CONTAINERS_LOOKUP[key] = i
	end
	
	UniversalAutoload.MATERIALS = {}
	table.insert(UniversalAutoload.MATERIALS, UniversalAutoload.ALL )
	UniversalAutoload.MATERIALS_FILLTYPE = {}
	table.insert( UniversalAutoload.MATERIALS_FILLTYPE, {["title"]= g_i18n:getText("universalAutoload_ALL")} )
	for index, fillType in ipairs(g_fillTypeManager.fillTypes) do
		if fillType.name ~= "UNKNOWN" then
			table.insert(UniversalAutoload.MATERIALS, fillType.name )
			table.insert(UniversalAutoload.MATERIALS_FILLTYPE, fillType )
		end
	end
	
	UniversalAutoload.MATERIALS_INDEX = {}
	for i, key in ipairs(UniversalAutoload.MATERIALS) do
		-- print("  - "..i..": "..key.." = "..UniversalAutoload.MATERIALS_FILLTYPE[i].title)
		UniversalAutoload.MATERIALS_INDEX[key] = i
	end

	-- USER SETTINGS FIRST
	print("IMPORT user vehicle configurations")
	local userSettingsFile = Utils.getFilename(UniversalAutoload.userSettingsFile, getUserProfileAppPath())
	UniversalAutoloadManager.ImportUserConfigurations(userSettingsFile)

	UniversalAutoloadManager.detectKeybindingConflicts()
	
	if g_currentMission:getIsServer() and not g_currentMission.missionDynamicInfo.isMultiplayer then
		-- addConsoleCommand("ualAddBales", "Fill current vehicle with specified bales", "consoleAddBales", UniversalAutoloadManager)
		-- addConsoleCommand("ualAddRoundBales_125", "Fill current vehicle with small round bales", "consoleAddRoundBales_125", UniversalAutoloadManager)
		-- addConsoleCommand("ualAddRoundBales_150", "Fill current vehicle with medium round bales", "consoleAddRoundBales_150", UniversalAutoloadManager)
		-- addConsoleCommand("ualAddRoundBales_180", "Fill current vehicle with large round bales", "consoleAddRoundBales_180", UniversalAutoloadManager)
		-- addConsoleCommand("ualAddSquareBales_180", "Fill current vehicle with small square bales", "consoleAddSquareBales_180", UniversalAutoloadManager)
		-- addConsoleCommand("ualAddSquareBales_220", "Fill current vehicle with medium square bales", "consoleAddSquareBales_220", UniversalAutoloadManager)
		-- addConsoleCommand("ualAddSquareBales_240", "Fill current vehicle with large square bales", "consoleAddSquareBales_240", UniversalAutoloadManager)
		-- addConsoleCommand("ualAddPallets", "Fill current vehicle with specified pallets (fill type)", "consoleAddPallets", UniversalAutoloadManager)
		-- addConsoleCommand("ualAddLogs", "Fill current vehicle with specified logs (length / fill type)", "consoleAddLogs", UniversalAutoloadManager)
		-- addConsoleCommand("ualClearLoadedObjects", "Remove all loaded objects from current vehicle", "consoleClearLoadedObjects", UniversalAutoloadManager)
		-- addConsoleCommand("ualResetVehicles", "Reset all vehicles with autoload (and any attached) to the shop", "consoleResetVehicles", UniversalAutoloadManager)
		-- addConsoleCommand("ualImportUserConfigurations", "Force reload configurations from mod settings", "consoleImportUserConfigurations", UniversalAutoloadManager)
		-- addConsoleCommand("ualCreateBoundingBox", "Create a bounding box around all loaded pallets", "consoleCreateBoundingBox", UniversalAutoloadManager)
		-- addConsoleCommand("ualSpawnTestPallets", "Create one of each pallet type (not loaded)", "consoleSpawnTestPallets", UniversalAutoloadManager)
		-- addConsoleCommand("ualFullTest", "Test all the different loading types", "consoleFullTest", UniversalAutoloadManager)
		
		-- local oldCleanUp = getmetatable(_G).__index.cleanUp
		-- getmetatable(_G).__index.cleanUp = function()
			-- print("UNIVERSAL AUTOLOAD: CLEAN UP")
			-- removeConsoleCommand("ualAddBales")
			-- removeConsoleCommand("ualAddRoundBales_125")
			-- removeConsoleCommand("ualAddRoundBales_150")
			-- removeConsoleCommand("ualAddRoundBales_180")
			-- removeConsoleCommand("ualAddSquareBales_180")
			-- removeConsoleCommand("ualAddSquareBales_220")
			-- removeConsoleCommand("ualAddSquareBales_240")
			-- removeConsoleCommand("ualAddPallets")
			-- removeConsoleCommand("ualAddLogs")
			-- removeConsoleCommand("ualClearLoadedObjects")
			-- removeConsoleCommand("ualResetVehicles")
			-- removeConsoleCommand("ualImportUserConfigurations")
			-- removeConsoleCommand("ualCreateBoundingBox")
			-- removeConsoleCommand("ualSpawnTestPallets")
			-- removeConsoleCommand("ualFullTest")
			-- oldCleanUp()
		-- end
	end
end

-- SYNC SETTINGS:
Player.readStream = Utils.overwrittenFunction(Player.readStream,
	function(self, superFunc, streamId, connection, objectId)
		superFunc(self, streamId, connection, objectId)
		print("UAL Player.readStream")
		UniversalAutoload.disableAutoStrap = streamReadBool(streamId)
		UniversalAutoload.manualLoadingOnly = streamReadBool(streamId)
		UniversalAutoload.disableManualLoading = streamReadBool(streamId)
	end
)
Player.writeStream = Utils.overwrittenFunction(Player.writeStream,
	function(self, superFunc, streamId, connection)
		superFunc(self, streamId, connection)
		print("UAL Player.writeStream")
		streamWriteBool(streamId, UniversalAutoload.disableAutoStrap or false)
		streamWriteBool(streamId, UniversalAutoload.manualLoadingOnly or false)
		streamWriteBool(streamId, UniversalAutoload.disableManualLoading or false)
	end
)

-- SEND SETTINGS TO CLIENT:
FSBaseMission.sendInitialClientState = Utils.overwrittenFunction(FSBaseMission.sendInitialClientState,
	function(self, superFunc, connection, user, farm)
		superFunc(self, connection, user, farm)
		
		if debugMultiplayer then print("  user: " .. tostring(user.nickname) .. " " .. tostring(farm.name)) end
		print("connectedToDedicatedServer: " .. tostring(g_currentMission.connectedToDedicatedServer))

		-- UniversalAutoload.disableAutoStrap = UniversalAutoload.disableAutoStrap or false
		-- UniversalAutoload.manualLoadingOnly = UniversalAutoload.manualLoadingOnly or false
		-- UniversalAutoload.disableManualLoading = UniversalAutoload.disableManualLoading or false
		-- UniversalAutoload.pricePerLog = UniversalAutoload.pricePerLog or 0
		-- UniversalAutoload.pricePerBale = UniversalAutoload.pricePerBale or 0
		-- UniversalAutoload.pricePerPallet = UniversalAutoload.pricePerPallet or 0
		
		-- streamWriteBool(streamId, UniversalAutoload.disableAutoStrap)
		-- streamWriteBool(streamId, UniversalAutoload.manualLoadingOnly)
		-- streamWriteBool(streamId, UniversalAutoload.disableManualLoading)
		-- streamWriteInt32(streamId, spec.pricePerLog)
		-- streamWriteInt32(streamId, spec.pricePerBale)
		-- streamWriteInt32(streamId, spec.pricePerPallet)
		-- streamWriteInt32(streamId, spec.minLogLength)

		-- UniversalAutoload.disableAutoStrap = streamReadBool(streamId)
		-- UniversalAutoload.manualLoadingOnly = streamReadBool(streamId)
		-- UniversalAutoload.disableManualLoading = streamReadBool(streamId)
		-- spec.pricePerLog = streamReadInt32(streamId)
		-- spec.pricePerBale = streamReadInt32(streamId)
		-- spec.pricePerPallet = streamReadInt32(streamId)
		-- spec.minLogLength = streamReadInt32(streamId)
	end
)


function UniversalAutoloadManager:deleteMap()
end

function tableContainsValue(container, value)
	for k, v in pairs(container) do
		if v == value then
			return true
		end
	end
	return false
end

function deepCopy(original, copies)
	copies = copies or {}
	if copies[original] then
		return copies[original]
	end
	
	local copy = {}
	copies[original] = copy
	for k, v in pairs(original) do
		if type(v) == "table" then
			v = deepCopy(v, copies)
		end
		copy[k] = v
	end
	return copy
end

function deepCompare(tbl1, tbl2)
	if tbl1==nil or tbl2==nil then
		return false
	end
	if tbl1 == tbl2 then
		return true
	elseif type(tbl1) == "table" and type(tbl2) == "table" then
		for key1, value1 in pairs(tbl1) do
			local value2 = tbl2[key1]
			if value2 == nil then
				return false
			elseif value1 ~= value2 then
				if type(value1) == "table" and type(value2) == "table" then
					if not deepCompare(value1, value2) then
						return false
					end
				else
					return false
				end
			end
		end
		for key2, _ in pairs(tbl2) do
			if tbl1[key2] == nil then
				return false
			end
		end
		return true
	end
	return false
end

ShopConfigScreen.processAttributeData = Utils.overwrittenFunction(ShopConfigScreen.processAttributeData,
	function(self, superFunc, storeItem, vehicle, saleItem)

		superFunc(self, storeItem, vehicle, saleItem)
		
		if vehicle.spec_universalAutoload ~= nil and vehicle.spec_universalAutoload.isAutoloadAvailable then
			
			local itemElement = self.attributeItem:clone(self.attributesLayout)
			local iconElement = itemElement:getDescendantByName("icon")
			local textElement = itemElement:getDescendantByName("text")

			itemElement:reloadFocusHandling(true)
			iconElement:applyProfile(ShopConfigScreen.GUI_PROFILE.CAPACITY)
			iconElement:setImageFilename(UniversalAutoload.SHOP_ICON)
			iconElement:setImageUVs(nil, 0, 0, 0, 1, 1, 0, 1, 1)
			iconElement:setVisible(true)
			textElement:setText(g_i18n:getText("shop_configuration_text"))
			
			if vehicle.spec_universalAutoload.isLogTrailer then
				local maxSingleLengthString
				local maxSingleLength = UniversalAutoload.getMaxSingleLength(vehicle)
				local nearestHalfValue = math.floor(2*maxSingleLength)/2
				if nearestHalfValue % 1 < 0.1 then
					maxSingleLengthString = string.format("  %dm", nearestHalfValue)
				else
					maxSingleLengthString = string.format("  %.1fm", nearestHalfValue)
				end

				local itemElement2 = self.attributeItem:clone(self.attributesLayout)
				local iconElement2 = itemElement2:getDescendantByName("icon")
				local textElement2 = itemElement2:getDescendantByName("text")

				itemElement2:reloadFocusHandling(true)
				iconElement2:applyProfile(ShopConfigScreen.GUI_PROFILE.WORKING_WIDTH)
				textElement2:setText(g_i18n:getText("infohud_length") .. maxSingleLengthString)
			end
			
			self.attributesLayout:invalidateLayout()

		end

	end
)

-- Add valid store items to the 'UNIVERSALAUTOLOAD' store pack if it exists.
-- StoreManager.loadItem = Utils.overwrittenFunction(StoreManager.loadItem, function(self, superFunc, ...)
	-- local storeItem = superFunc(self, ...)

	-- if storeItem and storeItem.species == 1 then
		-- local xmlFile = XMLFile.load("loadItemXml", storeItem.xmlFilename, storeItem.xmlSchema)
		-- local typeName = xmlFile:getString("vehicle#type")
		
		-- local tensionBeltKey = "vehicle.tensionBelts.tensionBeltsConfigurations"
		-- local firstConfigKey = tensionBeltKey .. ".tensionBeltsConfiguration(0).tensionBelts"
		-- local hasTensionBelts = xmlFile:hasProperty(firstConfigKey)

		-- if typeName and UniversalAutoload.VEHICLE_TYPES[typeName] and hasTensionBelts then
			-- table.addElement(g_storeManager:getPackItems("UNIVERSALAUTOLOAD"), storeItem.xmlFilename)
		-- end
	-- end

	-- return storeItem
-- end)

