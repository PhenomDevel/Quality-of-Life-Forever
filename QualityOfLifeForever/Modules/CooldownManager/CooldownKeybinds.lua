-- luacheck: read globals EssentialCooldownViewer UtilityCooldownViewer C_ActionBar C_AddOns CreateFrame GetBindingKey GetBindingText GetActionBarPage GetBonusBarOffset NumberFontNormal
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Keybinds",
		NOTE = "Key of the action button on each icon",
		DESC = "Shows the keybind of the action button that holds the spell on the icons of the cooldown manager.",
		SECTION_SHOW = "Show on",
		SECTION_DISPLAY = "Display",
		ESSENTIAL = "Essential cooldowns",
		ESSENTIAL_DESC = "The main bar of the cooldown manager.",
		UTILITY = "Utility cooldowns",
		UTILITY_DESC = "The smaller second bar of the cooldown manager.",
		SIZE = "Font size",
		SIZE_DESC = "Size of the keybind text in pixels.",
		POSITION = "Position",
		POSITION_DESC = "Where on the icon the keybind is shown.",
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
		SECTION_SHOW = "Anzeigen bei",
		SECTION_DISPLAY = "Darstellung",
		ESSENTIAL = "Wichtige Abklingzeiten",
		ESSENTIAL_DESC = "Die Hauptleiste des Cooldown-Managers.",
		UTILITY = "Nützliche Abklingzeiten",
		UTILITY_DESC = "Die kleinere zweite Leiste des Cooldown-Managers.",
		SIZE = "Schriftgröße",
		SIZE_DESC = "Größe des Tastentexts in Pixeln.",
		POSITION = "Position",
		POSITION_DESC = "Wo auf dem Symbol die Taste angezeigt wird.",
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

local module = ns:NewModule("CooldownKeybinds", {
	title = L.TITLE,
	description = L.DESC,
	note = L.NOTE,
	category = "COOLDOWN_MANAGER",
	defaults = {
		essential = true,
		utility = true,
		size = 12,
		position = "TOPRIGHT",
	},
	options = {
		{ type = "header", label = L.SECTION_SHOW },
		{ key = "essential", type = "checkbox", label = L.ESSENTIAL, tooltip = L.ESSENTIAL_DESC },
		{ key = "utility", type = "checkbox", label = L.UTILITY, tooltip = L.UTILITY_DESC },
		{ type = "header", label = L.SECTION_DISPLAY },
		{ key = "size", type = "slider", label = L.SIZE, tooltip = L.SIZE_DESC, min = 8, max = 38, step = 2, format = FormatPixels },
		{ key = "position", type = "dropdown", label = L.POSITION, tooltip = L.POSITION_DESC, values = positionValues },
	},
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

local function UpdateItem(item, enabled)
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
	local font, _, flags = NumberFontNormal:GetFont()
	text:SetFont(font, module.db.size, flags ~= "" and flags or "OUTLINE")
	-- Small inset so the text doesn't touch the icon border.
	local point = module.db.position
	local x = point:find("LEFT") and 2 or point:find("RIGHT") and -2 or 0
	local y = point:find("TOP") and -2 or point:find("BOTTOM") and 2 or 0
	text:ClearAllPoints()
	text:SetPoint(point, item, point, x, y)
	text:SetText(key)
	text:Show()
end

local function GetViewers()
	return {
		{ frame = EssentialCooldownViewer, key = "essential" },
		{ frame = UtilityCooldownViewer, key = "utility" },
	}
end

function module:UpdateViewer(viewer, enabled)
	if not viewer or not viewer.GetItemFrames then
		return
	end
	for _, item in ipairs(viewer:GetItemFrames()) do
		UpdateItem(item, enabled)
	end
end

function module:UpdateAll()
	for _, viewer in ipairs(GetViewers()) do
		self:UpdateViewer(viewer.frame, self.enabled and self.db[viewer.key])
	end
end

function module:Invalidate()
	wipe(keyCache)
	self:UpdateAll()
end

function module:HookViewers()
	for _, viewer in ipairs(GetViewers()) do
		local frame, key = viewer.frame, viewer.key
		if frame then
			local function Update()
				self:UpdateViewer(frame, self.db[key])
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
