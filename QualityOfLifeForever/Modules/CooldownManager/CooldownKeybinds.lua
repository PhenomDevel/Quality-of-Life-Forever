-- luacheck: read globals C_ActionBar C_AddOns CreateFrame GetBindingKey GetBindingText GetActionBarPage GetBonusBarOffset NumberFontNormal
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Keybinds",
		NOTE = "Key of the action button on each icon",
		DESC = "Shows the keybind of the action button that holds the spell on the icons of the cooldown manager.",
		ESSENTIAL = "Essential cooldowns",
		UTILITY = "Utility cooldowns",
		SHOW = "Show keybinds",
		SHOW_ESSENTIAL_DESC = "Keybinds on the main bar of the cooldown manager.",
		SHOW_UTILITY_DESC = "Keybinds on the smaller second bar of the cooldown manager.",
		SIZE = "Font size",
		SIZE_DESC = "Size of the keybind text in pixels.",
		POSITION = "Position",
		POSITION_DESC = "Where on the icon the keybind is shown.",
		OFFSET_X = "Horizontal offset",
		OFFSET_X_DESC = "Moves the keybind to the right (positive) or left (negative), in pixels.",
		OFFSET_Y = "Vertical offset",
		OFFSET_Y_DESC = "Moves the keybind up (positive) or down (negative), in pixels.",
		TOPLEFT = "Top left",
		TOP = "Top",
		TOPRIGHT = "Top right",
		LEFT = "Left",
		CENTER = "Center",
		RIGHT = "Right",
		BOTTOMLEFT = "Bottom left",
		BOTTOM = "Bottom",
		BOTTOMRIGHT = "Bottom right",
	},
	deDE = {
		TITLE = "Tastenbelegung",
		NOTE = "Taste der Aktionsleiste auf jedem Symbol",
		DESC = "Zeigt auf den Symbolen des Cooldown-Managers die Tastenbelegung der Aktionstaste, auf der der Zauber liegt.",
		ESSENTIAL = "Wichtige Abklingzeiten",
		UTILITY = "Nützliche Abklingzeiten",
		SHOW = "Tastenbelegung anzeigen",
		SHOW_ESSENTIAL_DESC = "Tasten auf der Hauptleiste des Cooldown-Managers.",
		SHOW_UTILITY_DESC = "Tasten auf der kleineren zweiten Leiste des Cooldown-Managers.",
		SIZE = "Schriftgröße",
		SIZE_DESC = "Größe des Tastentexts in Pixeln.",
		POSITION = "Position",
		POSITION_DESC = "Wo auf dem Symbol die Taste angezeigt wird.",
		OFFSET_X = "Horizontaler Versatz",
		OFFSET_X_DESC = "Verschiebt die Taste nach rechts (positiv) oder links (negativ), in Pixeln.",
		OFFSET_Y = "Vertikaler Versatz",
		OFFSET_Y_DESC = "Verschiebt die Taste nach oben (positiv) oder unten (negativ), in Pixeln.",
		TOPLEFT = "Oben links",
		TOP = "Oben",
		TOPRIGHT = "Oben rechts",
		LEFT = "Links",
		CENTER = "Mitte",
		RIGHT = "Rechts",
		BOTTOMLEFT = "Unten links",
		BOTTOM = "Unten",
		BOTTOMRIGHT = "Unten rechts",
	},
})

local POSITIONS = {
	"TOPLEFT", "TOP", "TOPRIGHT",
	"LEFT", "CENTER", "RIGHT",
	"BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT",
}

local positionValues = {}
for _, point in ipairs(POSITIONS) do
	positionValues[#positionValues + 1] = { value = point, label = L[point] }
end

local function FormatPixels(value)
	return ("%d px"):format(value)
end

-- Each viewer has its own settings, stored as <prefix>, <prefix>Size, …
local VIEWERS = {
	{ prefix = "essential", frame = "EssentialCooldownViewer", label = L.ESSENTIAL, showDesc = L.SHOW_ESSENTIAL_DESC, size = 12 },
	{ prefix = "utility", frame = "UtilityCooldownViewer", label = L.UTILITY, showDesc = L.SHOW_UTILITY_DESC, size = 10 },
}

local defaults, options = {}, {}
for _, viewer in ipairs(VIEWERS) do
	local p = viewer.prefix
	defaults[p] = true
	defaults[p .. "Size"] = viewer.size
	defaults[p .. "Position"] = "TOPRIGHT"
	defaults[p .. "X"] = 0
	defaults[p .. "Y"] = 0
	for _, option in ipairs({
		{ type = "header", label = viewer.label },
		{ key = p, type = "checkbox", label = L.SHOW, tooltip = viewer.showDesc },
		{ key = p .. "Size", type = "slider", label = L.SIZE, tooltip = L.SIZE_DESC, min = 8, max = 38, step = 2, format = FormatPixels },
		{ key = p .. "Position", type = "dropdown", label = L.POSITION, tooltip = L.POSITION_DESC, values = positionValues },
		{ key = p .. "X", type = "slider", label = L.OFFSET_X, tooltip = L.OFFSET_X_DESC, min = -30, max = 30, step = 1, format = FormatPixels },
		{ key = p .. "Y", type = "slider", label = L.OFFSET_Y, tooltip = L.OFFSET_Y_DESC, min = -30, max = 30, step = 1, format = FormatPixels },
	}) do
		options[#options + 1] = option
	end
end

local module = ns:NewModule("CooldownKeybinds", {
	title = L.TITLE,
	description = L.DESC,
	note = L.NOTE,
	category = "COOLDOWN_MANAGER",
	defaults = defaults,
	options = options,
})

local IsSecret = ns.Utils.IsSecret

-- Binding commands of the fixed action bars by first slot, see
-- https://warcraft.wiki.gg/wiki/Action_slot
local MULTI_BARS = {
	{ first = 25, command = "MULTIACTIONBAR3BUTTON" },
	{ first = 37, command = "MULTIACTIONBAR4BUTTON" },
	{ first = 49, command = "MULTIACTIONBAR2BUTTON" },
	{ first = 61, command = "MULTIACTIONBAR1BUTTON" },
	{ first = 145, command = "MULTIACTIONBAR5BUTTON" },
	{ first = 157, command = "MULTIACTIONBAR6BUTTON" },
	{ first = 169, command = "MULTIACTIONBAR7BUTTON" },
}

-- First slot the main bar currently shows: the bonus bar (forms, stances) or
-- the selected page.
local function MainBarFirstSlot()
	local bonus = GetBonusBarOffset()
	local page = GetActionBarPage()
	if bonus > 0 and page == 1 then
		return 72 + (bonus - 1) * 12 + 1
	end
	return (page - 1) * 12 + 1
end

local function GetSlotCommand(slot, mainFirst)
	if slot >= mainFirst and slot < mainFirst + 12 then
		return "ACTIONBUTTON" .. (slot - mainFirst + 1)
	end
	for _, bar in ipairs(MULTI_BARS) do
		if slot >= bar.first and slot < bar.first + 12 then
			return bar.command .. (slot - bar.first + 1)
		end
	end
end

-- spellID -> key text ("" when unbound); cleared when bindings or bars change.
local keyCache = {}

local function GetSpellKey(spellID)
	local key = keyCache[spellID]
	if key then
		return key
	end
	key = ""
	local slots = C_ActionBar.FindSpellActionButtons(spellID)
	if slots then
		local mainFirst = MainBarFirstSlot()
		for _, slot in ipairs(slots) do
			local command = GetSlotCommand(slot, mainFirst)
			local binding = command and GetBindingKey(command)
			if binding then
				key = GetBindingText(binding, true)
				break
			end
		end
	end
	keyCache[spellID] = key
	return key
end

-- Only reads the item's cooldown info; Blizzard's item fields stay untouched.
local function GetItemKey(item)
	local info = item.GetCooldownInfo and item:GetCooldownInfo()
	if not info then
		return ""
	end
	local key = ""
	if info.overrideSpellID and not IsSecret(info.overrideSpellID) then
		key = GetSpellKey(info.overrideSpellID)
	end
	if key == "" and info.spellID and not IsSecret(info.spellID) then
		key = GetSpellKey(info.spellID)
	end
	return key
end

-- item frame -> font string (on an own frame above the cooldown swipe)
local texts = {}

local function UpdateItem(item, enabled, p)
	local text = texts[item]
	local key = enabled and GetItemKey(item) or ""
	if key == "" then
		if text then
			text:Hide()
		end
		return
	end
	if not text then
		local overlay = CreateFrame("Frame", nil, item)
		overlay:SetAllPoints()
		overlay:SetFrameLevel(item:GetFrameLevel() + 10)
		text = overlay:CreateFontString(nil, "OVERLAY")
		texts[item] = text
	end
	local db = module.db
	local font, _, flags = NumberFontNormal:GetFont()
	text:SetFont(font, db[p .. "Size"], flags ~= "" and flags or "OUTLINE")
	local point = db[p .. "Position"]
	text:ClearAllPoints()
	text:SetPoint(point, item, point, db[p .. "X"], db[p .. "Y"])
	text:SetText(key)
	text:Show()
end

function module:UpdateViewer(viewer)
	local frame = _G[viewer.frame]
	if not frame or not frame.GetItemFrames then
		return
	end
	local enabled = self.enabled and self.db[viewer.prefix]
	for _, item in ipairs(frame:GetItemFrames()) do
		UpdateItem(item, enabled, viewer.prefix)
	end
end

function module:UpdateAll()
	for _, viewer in ipairs(VIEWERS) do
		self:UpdateViewer(viewer)
	end
end

function module:Invalidate()
	wipe(keyCache)
	self:UpdateAll()
end

function module:HookViewers()
	for _, viewer in ipairs(VIEWERS) do
		local frame = _G[viewer.frame]
		if frame then
			local function Update()
				self:UpdateViewer(viewer)
			end
			self:SecureHook(frame, "RefreshLayout", Update)
			self:SecureHook(frame, "RefreshData", Update)
		end
	end
	self:UpdateAll()
end

function module:ADDON_LOADED(name)
	if name == "Blizzard_CooldownViewer" then
		self:UnregisterEvent("ADDON_LOADED")
		self:HookViewers()
	end
end

-- Size and position used to be shared by both viewers.
function module:OnInitialize()
	local db = self.db
	if db.size ~= nil then
		db.essentialSize, db.utilitySize = db.size, db.size
		db.size = nil
	end
	if db.position ~= nil then
		db.essentialPosition, db.utilityPosition = db.position, db.position
		db.position = nil
	end
end

function module:OnEnable()
	for _, event in ipairs({
		"UPDATE_BINDINGS", "ACTIONBAR_SLOT_CHANGED", "ACTIONBAR_PAGE_CHANGED",
		"UPDATE_BONUS_ACTIONBAR", "PLAYER_ENTERING_WORLD", "SPELLS_CHANGED",
	}) do
		self:RegisterEvent(event, self.Invalidate)
	end
	if C_AddOns.IsAddOnLoaded("Blizzard_CooldownViewer") then
		self:HookViewers()
	else
		self:RegisterEvent("ADDON_LOADED")
	end
end

function module:OnDisable()
	for _, text in pairs(texts) do
		text:Hide()
	end
end

function module:OnOptionChanged()
	self:UpdateAll()
end
