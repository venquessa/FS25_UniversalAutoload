InGameMenuUALSettings = {}
local InGameMenuUALSettings_mt = Class(InGameMenuUALSettings, TabbedMenuFrameElement)
InGameMenuUALSettings.CONTROLS = {
	"settingsContainer",
	"boxLayout",
	"checkEnabled",
}

local function NO_CALLBACK()
end

function InGameMenuUALSettings.new(i18n, messageCenter, subclass_mt)
	local self = InGameMenuUALSettings:superClass().new(nil, subclass_mt or InGameMenuUALSettings_mt)

    self.name = "InGameMenuUALSettings"
    self.i18n = i18n
    self.messageCenter = messageCenter
    
	self.dataBindings = {}
	
    self.backButtonInfo = {
		inputAction = InputAction.MENU_BACK
	}
	
	self:setMenuButtonInfo({
        self.backButtonInfo
    })
	
	return self
end

InGameMenuSettingsFrame.setHasMasterRights = Utils.appendedFunction(
InGameMenuSettingsFrame.setHasMasterRights, function(self, hasMasterRights)
	print("InGameMenuUALSettings:setHasMasterRights: " .. tostring(hasMasterRights))
	self.hasMasterRights = hasMasterRights

	if g_currentMission ~= nil then
		self:updateButtons()
	end
end)

function InGameMenuUALSettings:onFrameOpen()
	print("InGameMenuUALSettings:onFrameOpen")
	InGameMenuUALSettings:superClass().onFrameOpen(self)

	self:updateUALSettings()
	
	-- self.boxLayout:invalidateLayout()
	
	-- if FocusManager:getFocusedElement() == nil then
		-- self:setSoundSuppressed(true)
		-- FocusManager:setFocus(self.boxLayout)
		-- self:setSoundSuppressed(false)
	-- end
end

function InGameMenuUALSettings:updateButtons()
	print("InGameMenuUALSettings:updateButtons")

	if self.hasMasterRights and g_currentMission.missionDynamicInfo.isMultiplayer then
		table.insert(self.menuButtonInfo, self.serverSettingsButton)
	end

	self:setMenuButtonInfoDirty()
end

function InGameMenuUALSettings:updateUALSettings()
	print("InGameMenuUALSettings:updateUALSettings")
	-- self.savegameName = self.missionInfo.savegameName

	-- self.textSavegameName:setText(self.missionInfo.savegameName)
	-- self.multiTimeScale:setState(Utils.getTimeScaleIndex(self.missionInfo.timeScale))
	-- self.economicDifficulty:setState(self.missionInfo.economicDifficulty)
	-- self.checkSnowEnabled:setIsChecked(self.missionInfo.isSnowEnabled)
	-- self.multiGrowthMode:setState(self.missionInfo.growthMode)
end

function InGameMenuUALSettings:onClickBinaryOption(state)
	print("CLICKED " .. tostring(self) .. " = " .. tostring(state))
	if self.hasMasterRights then
		print("hasMasterRights")
	end
end
