ShopConfigMenuUALSettings = {}
local ShopConfigMenuUALSettings_mt = Class(ShopConfigMenuUALSettings, TabbedMenuFrameElement)
-- TabbedMenuFrameElement ScreenElement FrameElement OptionToggleElement SmoothListElement

ShopConfigMenuUALSettings.TRAILER_TYPES = {
	TEXTS = {
		g_i18n:getText("configuration_valueDefault"),
		g_i18n:getText("ui_option_isBaleTrailer"),
		g_i18n:getText("ui_option_isLogTrailer"),
		g_i18n:getText("ui_option_isBoxTrailer"),
		g_i18n:getText("ui_option_isCurtainTrailer"),
	},
}

ShopConfigMenuUALSettings.UNLOADING_TYPES = {
	TEXTS = {
		g_i18n:getText("configuration_valueDefault"),
		g_i18n:getText("ui_option_rearOnly"),
		g_i18n:getText("ui_option_frontOnly")
	},
}


local function NO_CALLBACK()
end

function ShopConfigMenuUALSettings.new(vehicle, subclass_mt)
	
	local self = ShopConfigMenuUALSettings:superClass().new(nil, subclass_mt or ShopConfigMenuUALSettings_mt)

    self.name = "ShopConfigMenuUALSettings"
	self.vehicle = vehicle and vehicle.spec_universalAutoload
    self.i18n = l18n or g_i18n
    self.inputBinding = inputBinding or g_inputBinding
    self.messageCenter = messageCenter or g_messageCenter
	
	return self
end

function ShopConfigMenuUALSettings:setNewVehicle(vehicle)
	self.vehicle = vehicle and vehicle.spec_universalAutoload
	self:updateSettings()
end

function ShopConfigMenuUALSettings:updateSettings()
	
	local vehicle = self.vehicle
	local settings = self.ualShopConfigSettingsLayout
	
	local isValid = vehicle ~= nil
	local isEnabled = vehicle and vehicle.isAutoloadAvailable == true
	for _, item in pairs(settings.elements) do
		if item.name == nil then
			item:setVisible(isEnabled)
		end
	end

	local function setChecked(controlId, checked)
		local control = self[controlId]
		if control then
			control:setIsChecked(checked or false, true)
		end
	end
	local function setValue(controlId, value)
		local control = self[controlId]
		if control then
			control:setState(value or 1, true)
		end
	end
	
	if isValid then
		print("SET ALL")
		setChecked('enableAutoloadCheckBox', vehicle.isAutoloadAvailable)
		setChecked('horizontalLoadingCheckBox', vehicle.horizontalLoading)
		setChecked('enableSideLoadingCheckBox', vehicle.enableSideLoading)
		setChecked('enableRearLoadingCheckBox', vehicle.enableRearLoading)
		
		if vehicle.isBaleTrailer then
			setValue('trailerTypeListBox', 2)
		elseif vehicle.isLogTrailer then
			setValue('trailerTypeListBox', 3)
		elseif vehicle.isBoxTrailer then
			setValue('trailerTypeListBox', 4)
		elseif vehicle.isCurtainTrailer then
			setValue('trailerTypeListBox', 5)
		else
			setValue('trailerTypeListBox', 1)
		end
		
		if vehicle.rearUnloadingOnly then
			setValue('unloadingTypeListBox', 2)
		elseif vehicle.frontUnloadingOnly then
			setValue('unloadingTypeListBox', 3)
		else
			setValue('unloadingTypeListBox', 1)
		end
		
	end
	
end

function ShopConfigMenuUALSettings:onCreate()
	print("ShopConfigMenu: onCreate")
	
	local settings = self.ualShopConfigSettingsLayout
	-- for _, item in pairs(settings.elements) do
		-- if item.name ~= "sectionHeader" and item:getIsVisible() then
			-- local c = InGameMenuSettingsFrame.COLOR_ALTERNATING[true]
			-- item:setImageColor(GuiOverlay.STATE_NORMAL, c[1], c[2], c[3], 0)
		-- end
	-- end
	
    local toggle = true
	for _, item in pairs(settings.elements) do
		if item.name == "sectionHeader" then
			toggle = true
		elseif item:getIsVisible() then
			local c = InGameMenuSettingsFrame.COLOR_ALTERNATING[toggle]
			item:setImageColor(GuiOverlay.STATE_NORMAL, unpack(c))
			toggle = not toggle
		end
	end

end

function ShopConfigMenuUALSettings:onCreateTrailerType(control)
	control.texts = ShopConfigMenuUALSettings.TRAILER_TYPES.TEXTS
end
function ShopConfigMenuUALSettings:onClickTrailerType(id, control, state)
	print("CLICKED " .. tostring(control.id) .. " = " .. tostring(not state) .. " (" .. tostring(id) .. ")")
		
	local vehicle = self.vehicle
	if not vehicle then
		return
	end
	
	if control == self.trailerTypeListBox then
		vehicle.isBaleTrailer = false
		vehicle.isLogTrailer = false
		vehicle.isBoxTrailer = false
		vehicle.isCurtainTrailer = false
		if id == 2 then
			vehicle.isBaleTrailer = true
		elseif id == 3 then
			vehicle.isLogTrailer = true
		elseif id == 4 then
			vehicle.isBoxTrailer = true
		elseif id == 5 then
			vehicle.isCurtainTrailer = true
		end
	end
end

function ShopConfigMenuUALSettings:onCreateUnloadingType(control)
	control.texts = ShopConfigMenuUALSettings.UNLOADING_TYPES.TEXTS
end
function ShopConfigMenuUALSettings:onClickUnloadingType(id, control, state)
	print("CLICKED " .. tostring(control.id) .. " = " .. tostring(not state) .. " (" .. tostring(id) .. ")")
		
	local vehicle = self.vehicle
	if not vehicle then
		return
	end
	
	if control == self.unloadingTypeListBox then
		vehicle.rearUnloadingOnly = false
		vehicle.frontUnloadingOnly = false
		if id == 2 then
			vehicle.rearUnloadingOnly = true
		elseif id == 3 then
			vehicle.frontUnloadingOnly = true
		end
	end

end

function ShopConfigMenuUALSettings:onOpen()
	print("ShopConfigMenu: onOpen")
	self:updateSettings()
end

function ShopConfigMenuUALSettings:onClose()
	print("ShopConfigMenu: onClose")
end


function ShopConfigMenuUALSettings:onClickOk()
	print("CLICKED OK")
	g_gui:closeDialogByName("ShopConfigMenuUALSettings")
end

function ShopConfigMenuUALSettings:onClickBack()
	print("CLICKED BACK")
	g_gui:closeDialogByName("ShopConfigMenuUALSettings")
end

function ShopConfigMenuUALSettings:onClickBinaryOption(id, control, state)
	print("CLICKED " .. tostring(control.id) .. " = " .. tostring(not state) .. " (" .. tostring(id) .. ")")
	
	local vehicle = self.vehicle
	if not vehicle then
		return
	end
	
	if control == self.enableAutoloadCheckBox then
		vehicle.isAutoloadAvailable = not state
		self:updateSettings()
	elseif control == self.horizontalLoadingCheckBox then
		vehicle.horizontalLoading = not state
	elseif control == self.enableSideLoadingCheckBox then
		vehicle.enableSideLoading = not state
	elseif control == self.enableRearLoadingCheckBox then
		vehicle.enableRearLoading = not state
	end

end
