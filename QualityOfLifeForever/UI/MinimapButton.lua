-- luacheck: read globals LibStub
local _, ns = ...

local L = ns.L

--[[
	Minimap button via LibDBIcon, so minimap addons (SexyMap, Leatrix Plus,
	button collectors …) can hide, fade or collect it like other addons'
	buttons. Left-click opens the options, right-click Edit Mode (to move
	overlays), drag moves it around the rim. The angle (degrees, 0 = right,
	counterclockwise) and visibility are stored account-wide in ns.db.global.
]]

local NAME = "QualityOfLifeForever"
local ICON = "Interface\\AddOns\\QualityOfLifeForever\\Media\\Logo"

local LibDBIcon = LibStub("LibDBIcon-1.0")

local function ShowTooltip(self)
	local version = "|cffb8b8bc" .. L.OPTIONS_VERSION:format(ns.version) .. "|r"
	local body = table.concat({ version, "", L.MINIMAP_HINT_OPTIONS, L.MINIMAP_HINT_EDIT_MODE, L.MINIMAP_HINT_DRAG }, "\n")
	ns.OptionsWidgets.ShowTooltipAt(self, "TOPRIGHT", "BOTTOMLEFT", 0, 0, ns.title, body)
end

-- LibDBIcon's db, mapped onto the existing saved settings.
local db = setmetatable({}, {
	__index = function(_, key)
		if key == "minimapPos" then
			return ns.db.global.minimapAngle
		elseif key == "hide" then
			return not ns.db.global.minimapButton
		end
	end,
	__newindex = function(store, key, value)
		if key == "minimapPos" then
			ns.db.global.minimapAngle = value
		elseif key == "hide" then
			ns.db.global.minimapButton = not value
		else
			rawset(store, key, value)
		end
	end,
})

local function Register()
	local object = LibStub("LibDataBroker-1.1"):NewDataObject(NAME, {
		type = "launcher",
		icon = ICON,
		OnClick = function(_, mouseButton)
			if mouseButton == "RightButton" then
				ns:OpenEditMode()
			else
				ns:ToggleSettings()
			end
		end,
		OnEnter = ShowTooltip,
		OnLeave = function()
			ns.OptionsWidgets.HideTooltip()
		end,
	})
	LibDBIcon:Register(NAME, object, db)
end

function ns:UpdateMinimapButton()
	if not LibDBIcon:IsRegistered(NAME) then
		Register()
	end
	if ns.db.global.minimapButton then
		LibDBIcon:Show(NAME)
	else
		LibDBIcon:Hide(NAME)
	end
end
