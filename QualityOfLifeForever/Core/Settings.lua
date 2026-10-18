-- luacheck: read globals GameFontHighlightHuge GameFontHighlight
local _, ns = ...

local L = ns.L

--[[
	Entry in Blizzard's settings (Options > AddOns). The options live in our
	own window (OptionsWindow.lua); this page only points there.
]]

local function CreatePanel()
	local panel = CreateFrame("Frame")

	local logo = panel:CreateTexture(nil, "ARTWORK")
	logo:SetSize(48, 48)
	logo:SetPoint("TOPLEFT", 16, -16)
	logo:SetTexture("Interface\\AddOns\\QualityOfLifeForever\\Media\\Logo")

	local title = panel:CreateFontString(nil, "OVERLAY")
	title:SetFontObject(GameFontHighlightHuge)
	title:SetPoint("LEFT", logo, "RIGHT", 12, 0)
	title:SetText(ns.title)

	local text = panel:CreateFontString(nil, "OVERLAY")
	text:SetFontObject(GameFontHighlight)
	text:SetPoint("TOPLEFT", logo, "BOTTOMLEFT", 0, -16)
	text:SetPoint("RIGHT", -16, 0)
	text:SetJustifyH("LEFT")
	text:SetText(L.SETTINGS_PAGE_TEXT)

	local button = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
	button:SetSize(180, 26)
	button:SetPoint("TOPLEFT", text, "BOTTOMLEFT", 0, -12)
	button:SetText(L.SETTINGS_PAGE_BUTTON)
	button:SetScript("OnClick", function()
		ns:OpenSettings()
	end)
	return panel
end

function ns:BuildSettings()
	if not (Settings and Settings.RegisterCanvasLayoutCategory) then
		ns:Debug("Settings API not available")
		return false
	end
	local category = Settings.RegisterCanvasLayoutCategory(CreatePanel(), ns.title)
	Settings.RegisterAddOnCategory(category)
	ns.settingsCategory = category
	return true
end
