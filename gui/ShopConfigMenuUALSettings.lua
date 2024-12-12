ShopConfigMenuUALSettings = {}
local ShopConfigMenuUALSettings_mt = Class(ShopConfigMenuUALSettings, TabbedMenuFrameElement)
-- TabbedMenuFrameElement ScreenElement FrameElement OptionToggleElement SmoothListElement

local function NO_CALLBACK()
end

function ShopConfigMenuUALSettings.new(l18n, inputBinding, messageCenter, subclass_mt)
	
	local self = ShopConfigMenuUALSettings:superClass().new(nil, subclass_mt or ShopConfigMenuUALSettings_mt)

    self.name = "ShopConfigMenuUALSettings"
    self.i18n = l18n or g_i18n
    self.inputBinding = inputBinding or g_inputBinding
    self.messageCenter = messageCenter or g_messageCenter
	
	return self
end

function ShopConfigMenuUALSettings:onOpen()
	print("ShopConfigMenu:onOpen")
end

function ShopConfigMenuUALSettings:onClose()
	print("ShopConfigMenu:onClose")
end

function ShopConfigMenuUALSettings:onCreate()
	print("ShopConfigMenu:onCreate")
end

function ShopConfigMenuUALSettings:onClickOk()
	print("CLICKED OK")
	g_gui:closeDialogByName("ShopConfigMenuUALSettings")
end

function ShopConfigMenuUALSettings:onClickBack()
	print("CLICKED BACK")
	g_gui:closeDialogByName("ShopConfigMenuUALSettings")
end

function ShopConfigMenuUALSettings:onClickBinaryOption(state)
	print("CLICKED " .. tostring(self) .. " = " .. tostring(state))
end
