local addonName, ns = ...

local L = ns.L
local Utils = ns.Utils

-- Loaded last (see the .toc), so every module has been registered by now.

local function OnAddonLoaded(event, loadedName)
	if loadedName ~= addonName then
		return
	end
	ns:UnregisterEvent(event, OnAddonLoaded)

	ns:InitializeDatabase()
	ns:InitializeModules()
	Utils.SafeCall(ns.BuildSettings, ns)
end

local function OnPlayerLogin(event)
	ns:UnregisterEvent(event, OnPlayerLogin)

	ns:EnableModules()
	Utils.SafeCall(ns.UpdateMinimapButton, ns)
	ns:Debug(L.ADDON_LOADED:format(ns.version))
end

ns:RegisterEvent("ADDON_LOADED", OnAddonLoaded)
ns:RegisterEvent("PLAYER_LOGIN", OnPlayerLogin)

--------------------------------------------------------------------------------
-- Addon compartment (the addon button next to the minimap)
--------------------------------------------------------------------------------

function QualityOfLifeForever_OnAddonCompartmentClick()
	ns:OpenSettings()
end

function QualityOfLifeForever_OnAddonCompartmentEnter(_, menuButtonFrame)
	GameTooltip:SetOwner(menuButtonFrame or UIParent, "ANCHOR_LEFT")
	GameTooltip:SetText(ns.title, 1, 1, 1)
	GameTooltip:AddLine(ns.version, 0.6, 0.6, 0.6)
	GameTooltip:AddLine(L.COMPARTMENT_HINT)
	GameTooltip:Show()
end

function QualityOfLifeForever_OnAddonCompartmentLeave()
	GameTooltip:Hide()
end
