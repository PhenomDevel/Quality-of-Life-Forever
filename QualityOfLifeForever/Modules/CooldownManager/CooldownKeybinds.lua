-- luacheck: read globals C_ActionBar C_AddOns C_Spell CreateFrame GetActionButtonForID GetBindingKey GetBindingText GetActionBarPage GetBonusBarOffset NumberFontNormal
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Keybinds",
		NOTE = "Key of the action button on each icon",
		DESC = "Shows the keybind of the action button that holds the spell on the icons of the cooldown manager and lights the icon up while the key is held.",
		ESSENTIAL = "Essential cooldowns",
		UTILITY = "Utility cooldowns",
		SHOW = "Show keybinds",
		SHOW_ESSENTIAL_DESC = "Keybinds on the main bar of the cooldown manager.",
		SHOW_UTILITY_DESC = "Keybinds on the smaller second bar of the cooldown manager.",
		SIZE = "Text size",
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
		PRESS = "Key press",
		PRESS_HIGHLIGHT = "Highlight on key press",
		PRESS_HIGHLIGHT_DESC = "Lights up the icon while you hold down the key of the action button that holds the spell.",
		RANGE = "Range",
		RANGE_INDICATOR = "Out of range indicator",
		RANGE_INDICATOR_DESC = "Like on the action bars: the keybind turns red and the icon gray while your target is out of range of the spell.",
	},
	deDE = {
		TITLE = "Tastenbelegung",
		NOTE = "Taste der Aktionsleiste auf jedem Symbol",
		DESC = "Zeigt auf den Symbolen des Cooldown-Managers die Tastenbelegung der Aktionstaste, auf der der Zauber liegt, und lässt das Symbol aufleuchten, solange die Taste gedrückt ist.",
		ESSENTIAL = "Wichtige Abklingzeiten",
		UTILITY = "Nützliche Abklingzeiten",
		SHOW = "Tastenbelegung anzeigen",
		SHOW_ESSENTIAL_DESC = "Tasten auf der Hauptleiste des Cooldown-Managers.",
		SHOW_UTILITY_DESC = "Tasten auf der kleineren zweiten Leiste des Cooldown-Managers.",
		SIZE = "Textgröße",
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
		PRESS = "Tastendruck",
		PRESS_HIGHLIGHT = "Bei Tastendruck aufleuchten",
		PRESS_HIGHLIGHT_DESC = "Lässt das Symbol aufleuchten, solange die Taste der Aktionstaste mit dem Zauber gedrückt ist.",
		RANGE = "Reichweite",
		RANGE_INDICATOR = "Außer-Reichweite-Anzeige",
		RANGE_INDICATOR_DESC = "Wie auf den Aktionsleisten: Die Taste wird rot und das Symbol grau, solange dein Ziel außerhalb der Reichweite des Zaubers ist.",
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
defaults.pressHighlight = true
options[#options + 1] = { type = "header", label = L.PRESS }
options[#options + 1] = { key = "pressHighlight", type = "checkbox", label = L.PRESS_HIGHLIGHT, tooltip = L.PRESS_HIGHLIGHT_DESC }
defaults.rangeIndicator = true
options[#options + 1] = { type = "header", label = L.RANGE }
options[#options + 1] = { key = "rangeIndicator", type = "checkbox", label = L.RANGE_INDICATOR, tooltip = L.RANGE_INDICATOR_DESC }

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

-- spellID -> { key = text ("" when unbound), slots = { [slot] = true } };
-- cleared when bindings or bars change.
local spellCache = {}

local function GetSpellInfo(spellID)
	local cached = spellCache[spellID]
	if cached then
		return cached
	end
	cached = { key = "", slots = {} }
	local slots = C_ActionBar.FindSpellActionButtons(spellID)
	if slots then
		local mainFirst = MainBarFirstSlot()
		for _, slot in ipairs(slots) do
			cached.slots[slot] = true
			local command = GetSlotCommand(slot, mainFirst)
			local binding = cached.key == "" and command and GetBindingKey(command)
			if binding then
				cached.key = GetBindingText(binding, true)
			end
		end
	end
	spellCache[spellID] = cached
	return cached
end

-- item frame -> slots of the spell shown on it, for the key press highlight
local itemSlots = {}

-- item frame -> spell ID shown on it, for the range indicator
local itemSpells = {}

-- Only reads the item's cooldown info; Blizzard's item fields stay untouched.
local function GetItemKey(item)
	itemSpells[item] = nil
	local info = item.GetCooldownInfo and item:GetCooldownInfo()
	if not info then
		return ""
	end
	local spell
	if info.overrideSpellID and not IsSecret(info.overrideSpellID) then
		spell = GetSpellInfo(info.overrideSpellID)
		itemSpells[item] = info.overrideSpellID
	elseif info.spellID and not IsSecret(info.spellID) then
		itemSpells[item] = info.spellID
	end
	if (not spell or spell.key == "") and info.spellID and not IsSecret(info.spellID) then
		local base = GetSpellInfo(info.spellID)
		if not spell or next(base.slots) then
			spell = base
		end
	end
	itemSlots[item] = spell and spell.slots
	return spell and spell.key or ""
end

-- item frame -> own frame above the cooldown swipe, holding the key text
-- (.text) and the press highlight (.highlight)
local overlays = {}

local function GetOverlay(item)
	local overlay = overlays[item]
	if not overlay then
		overlay = CreateFrame("Frame", nil, item)
		overlay:SetAllPoints()
		overlay:SetFrameLevel(item:GetFrameLevel() + 10)
		overlay.text = overlay:CreateFontString(nil, "OVERLAY")
		overlay.highlight = overlay:CreateTexture(nil, "ARTWORK")
		overlay.highlight:SetColorTexture(1, 1, 1, 0.35)
		overlay.highlight:SetBlendMode("ADD")
		local icon = item.Icon or item
		overlay.highlight:SetAllPoints(icon)
		-- Same rounded corners as the icon.
		local mask = icon.GetMaskTexture and icon:GetMaskTexture(1)
		if mask then
			overlay.highlight:AddMaskTexture(mask)
		end
		overlay.highlight:Hide()
		-- Gray tint while out of range, below the key text.
		overlay.range = overlay:CreateTexture(nil, "BORDER")
		overlay.range:SetColorTexture(0.3, 0.3, 0.3, 0.65)
		overlay.range:SetAllPoints(icon)
		if mask then
			overlay.range:AddMaskTexture(mask)
		end
		overlay.range:Hide()
		overlays[item] = overlay
	end
	return overlay
end

-- spell ID -> true while its range check is enabled / it is out of range
local rangeChecks, outOfRange = {}, {}

local function UpdateRange(item)
	local spellID = itemSpells[item]
	local out = module.enabled and module.db.rangeIndicator and spellID and outOfRange[spellID]
	if not out and not overlays[item] then
		return
	end
	local overlay = GetOverlay(item)
	overlay.range:SetShown(out)
	if out then
		overlay.text:SetTextColor(1, 0.1, 0.1)
	else
		overlay.text:SetTextColor(1, 1, 1)
	end
end

local function WatchRange(item)
	local spellID = itemSpells[item]
	if spellID and module.db.rangeIndicator and not rangeChecks[spellID] then
		rangeChecks[spellID] = true
		C_Spell.EnableSpellRangeCheck(spellID, true)
	end
end

local function UpdateItem(item, enabled, p)
	local key = GetItemKey(item)
	if module.enabled then
		WatchRange(item)
	end
	UpdateRange(item)
	if not enabled or key == "" then
		if overlays[item] then
			overlays[item].text:Hide()
		end
		return
	end
	local text = GetOverlay(item).text
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
	wipe(spellCache)
	self:UpdateAll()
end

-- action button -> overlays it lit up; released by the same button even if
-- the bar paged (form change) while the key was held.
local pressedOverlays = {}

-- Bound keys run ActionButtonDown/Up or MultiActionButtonDown/Up; both get
-- the pressed button, whose current action slot identifies the spell.
function module:SetPressed(button, pressed)
	if not button then
		return
	end
	local lit = pressedOverlays[button]
	if lit then
		for _, overlay in ipairs(lit) do
			overlay.highlight:Hide()
		end
		pressedOverlays[button] = nil
	end
	local slot = button.action
	if not pressed or not slot or not self.db.pressHighlight then
		return
	end
	lit = {}
	for item, slots in pairs(itemSlots) do
		if slots[slot] then
			local overlay = GetOverlay(item)
			overlay.highlight:Show()
			lit[#lit + 1] = overlay
		end
	end
	pressedOverlays[button] = lit
end

local function MultiBarButton(barName, id)
	local bar = _G[barName]
	return bar and bar.actionButtons and bar.actionButtons[id]
end

function module:HookPresses()
	self:SecureHook("ActionButtonDown", function(_, id)
		self:SetPressed(GetActionButtonForID(id), true)
	end)
	self:SecureHook("ActionButtonUp", function(_, id)
		self:SetPressed(GetActionButtonForID(id), false)
	end)
	self:SecureHook("MultiActionButtonDown", function(_, barName, id)
		self:SetPressed(MultiBarButton(barName, id), true)
	end)
	self:SecureHook("MultiActionButtonUp", function(_, barName, id)
		self:SetPressed(MultiBarButton(barName, id), false)
	end)
end

function module:ClearPressed()
	wipe(pressedOverlays)
	for _, overlay in pairs(overlays) do
		overlay.highlight:Hide()
	end
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

function module:SPELL_RANGE_CHECK_UPDATE(spellID, inRange, checksRange)
	if IsSecret(inRange) or IsSecret(checksRange) then
		return
	end
	outOfRange[spellID] = (checksRange and not inRange) or nil
	for item, id in pairs(itemSpells) do
		if id == spellID then
			UpdateRange(item)
		end
	end
end

function module:StopRangeChecks()
	for spellID in pairs(rangeChecks) do
		C_Spell.EnableSpellRangeCheck(spellID, false)
	end
	wipe(rangeChecks)
	wipe(outOfRange)
	for item in pairs(overlays) do
		UpdateRange(item)
	end
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
	self:RegisterEvent("SPELL_RANGE_CHECK_UPDATE")
	self:HookPresses()
	if C_AddOns.IsAddOnLoaded("Blizzard_CooldownViewer") then
		self:HookViewers()
	else
		self:RegisterEvent("ADDON_LOADED")
	end
end

function module:OnDisable()
	self:ClearPressed()
	self:StopRangeChecks()
	for _, overlay in pairs(overlays) do
		overlay.text:Hide()
	end
end

function module:OnOptionChanged(key)
	if key == "pressHighlight" then
		self:ClearPressed()
	elseif key == "rangeIndicator" and not self.db.rangeIndicator then
		self:StopRangeChecks()
	end
	self:UpdateAll()
end
