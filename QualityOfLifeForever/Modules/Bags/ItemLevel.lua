-- luacheck: read globals C_Item C_AddOns C_Timer CreateFrame ItemLocation Enum ITEM_QUALITY_COLORS InspectFrame InspectPaperDollFrame InspectModelFrame InspectModelScene PaperDollFrame CharacterModelScene CharacterModelFrame GetInventoryItemLink GetInventoryItemQuality INVSLOT_BODY INVSLOT_TABARD INVSLOT_MAINHAND INVSLOT_OFFHAND INVSLOT_FIRST_EQUIPPED INVSLOT_LAST_EQUIPPED
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Item level",
		NOTE = "On equipment and in bags",
		DESC = "Shows the item level on equipped items, equipment in your bags and on inspected players, plus the average item level in the character and inspect frame.",
		SECTION_SHOW = "Show on",
		SECTION_DISPLAY = "Display",
		CHARACTER = "Character frame",
		CHARACTER_DESC = "Item level on each equipment slot.",
		BAGS = "Bags",
		BAGS_DESC = "Item level on weapons and armor in your bags.",
		INSPECT = "Inspect frame",
		INSPECT_DESC = "Item level on the equipment of inspected players.",
		QUALITY_COLOR = "Color by quality",
		QUALITY_COLOR_DESC = "Colors the number like the item's quality instead of white.",
		AVERAGE = "Average item level",
		AVERAGE_DESC = "Shows the average item level of all equipment slots above the model in the character and inspect frame. Empty slots count as 0, a two-handed weapon counts twice while the off hand is empty.",
		AVERAGE_TEXT = "Item level %.1f",
	},
	deDE = {
		TITLE = "Gegenstandsstufe",
		NOTE = "An Ausrüstung und in Taschen",
		DESC = "Zeigt die Gegenstandsstufe auf angelegten Gegenständen, Ausrüstung in den Taschen und bei betrachteten Spielern, dazu die durchschnittliche Gegenstandsstufe im Charakter- und Betrachten-Fenster.",
		SECTION_SHOW = "Anzeigen bei",
		SECTION_DISPLAY = "Darstellung",
		CHARACTER = "Charakterfenster",
		CHARACTER_DESC = "Gegenstandsstufe auf jedem Ausrüstungsplatz.",
		BAGS = "Taschen",
		BAGS_DESC = "Gegenstandsstufe auf Waffen und Rüstung in den Taschen.",
		INSPECT = "Betrachten-Fenster",
		INSPECT_DESC = "Gegenstandsstufe auf der Ausrüstung betrachteter Spieler.",
		QUALITY_COLOR = "Nach Qualität färben",
		QUALITY_COLOR_DESC = "Färbt die Zahl in der Qualitätsfarbe des Gegenstands statt weiß.",
		AVERAGE = "Durchschnittliche Gegenstandsstufe",
		AVERAGE_DESC = "Zeigt die durchschnittliche Gegenstandsstufe aller Ausrüstungsplätze über dem Modell im Charakter- und Betrachten-Fenster. Leere Plätze zählen als 0, eine Zweihandwaffe zählt doppelt, solange die Nebenhand leer ist.",
		AVERAGE_TEXT = "Gegenstandsstufe %.1f",
	},
})

local module = ns:NewModule("ItemLevel", {
	title = L.TITLE,
	description = L.DESC,
	note = L.NOTE,
	category = "BAGS",
	order = 10,
	defaults = {
		character = true,
		bags = true,
		inspect = true,
		qualityColor = true,
		average = true,
	},
	options = {
		{ type = "header", label = L.SECTION_SHOW },
		{ key = "character", type = "checkbox", label = L.CHARACTER, tooltip = L.CHARACTER_DESC },
		{ key = "bags", type = "checkbox", label = L.BAGS, tooltip = L.BAGS_DESC },
		{ key = "inspect", type = "checkbox", label = L.INSPECT, tooltip = L.INSPECT_DESC },
		{ type = "header", label = L.SECTION_DISPLAY },
		{ key = "qualityColor", type = "checkbox", label = L.QUALITY_COLOR, tooltip = L.QUALITY_COLOR_DESC },
		{ key = "average", type = "checkbox", label = L.AVERAGE, tooltip = L.AVERAGE_DESC },
	},
})

-- Item level is meaningless on shirts and tabards.
local SKIPPED_SLOTS = { [INVSLOT_BODY] = true, [INVSLOT_TABARD] = true }

-- button -> font string, and button -> function(button) that refreshes it.
local texts, updaters = {}, {}

local function SetText(button, itemLevel, quality)
	local text = texts[button]
	if not itemLevel or itemLevel <= 1 then
		if text then
			text:Hide()
		end
		return
	end
	if not text then
		text = button:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
		text:SetPoint("BOTTOM", button, "BOTTOM", 0, 2)
		texts[button] = text
	end
	local color = module.db.qualityColor and quality and ITEM_QUALITY_COLORS[quality]
	if color then
		text:SetTextColor(color.r, color.g, color.b)
	else
		text:SetTextColor(1, 1, 1)
	end
	text:SetText(itemLevel)
	text:Show()
end

local function IsGear(itemLink)
	local _, _, _, equipLoc, _, classID = C_Item.GetItemInfoInstant(itemLink)
	return (classID == Enum.ItemClass.Weapon or classID == Enum.ItemClass.Armor)
		and equipLoc ~= "INVTYPE_BODY" and equipLoc ~= "INVTYPE_TABARD"
end

local function UpdateLocation(button, location, enabled)
	if enabled and C_Item.DoesItemExist(location) then
		SetText(button, C_Item.GetCurrentItemLevel(location), C_Item.GetItemQuality(location))
	else
		SetText(button)
	end
end

-- Average item level per frame ("character"/"inspect"): the slots are the
-- equipment slot buttons that frame actually shows (seen via the update
-- hooks), so the divisor follows the client's layout (e.g. a ranged slot).
local averages = {
	character = { slots = {}, levels = {} },
	inspect = { slots = {}, levels = {} },
}

local function IsTwoHanded(link)
	local equipLoc = link and select(4, C_Item.GetItemInfoInstant(link))
	return equipLoc == "INVTYPE_2HWEAPON"
end

local function GetAverageText(average)
	local holder = average.holder
	if not holder then
		local parent = average.getParent()
		local anchor = average.getAnchor() or parent
		-- Own frame above the model, whose background would cover a font
		-- string on the paper doll frame itself.
		holder = CreateFrame("Frame", nil, parent)
		holder:SetAllPoints(anchor)
		holder:SetFrameLevel(anchor:GetFrameLevel() + 10)
		average.text = holder:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		average.text:SetPoint("TOP", holder, "TOP", 0, -6)
		average.holder = holder
	end
	return average.text
end

local function RefreshAverage(average)
	average.pending = false
	local enabled = module.enabled and module.db.average
	if not enabled then
		if average.text then
			average.text:Hide()
		end
		return
	end
	local unit = average.getUnit()
	local total, count = 0, 0
	for slot in pairs(average.slots) do
		count = count + 1
		local level = average.levels[slot]
		if level == false then
			-- Item not cached yet: the slot update after caching refreshes again.
			if average.text then
				average.text:Hide()
			end
			return
		end
		total = total + (level or 0)
	end
	if unit and average.slots[INVSLOT_MAINHAND] and average.slots[INVSLOT_OFFHAND]
		and not GetInventoryItemLink(unit, INVSLOT_OFFHAND)
		and IsTwoHanded(GetInventoryItemLink(unit, INVSLOT_MAINHAND)) then
		total = total + (average.levels[INVSLOT_MAINHAND] or 0)
	end
	if count == 0 or total == 0 then
		if average.text then
			average.text:Hide()
		end
		return
	end
	local text = GetAverageText(average)
	text:SetFormattedText(L.AVERAGE_TEXT, total / count)
	text:Show()
end

-- Slot updates arrive one button at a time; recompute once per frame.
-- level: number, nil for an empty slot, false while the item isn't cached.
local function SetSlotLevel(average, slot, level)
	average.slots[slot] = true
	average.levels[slot] = level
	if not average.pending then
		average.pending = true
		C_Timer.After(0, function()
			RefreshAverage(average)
		end)
	end
end

averages.character.getUnit = function()
	return "player"
end
averages.character.getParent = function()
	return PaperDollFrame
end
averages.character.getAnchor = function()
	return CharacterModelScene or CharacterModelFrame
end
averages.inspect.getUnit = function()
	return InspectFrame and InspectFrame.unit
end
averages.inspect.getParent = function()
	return InspectPaperDollFrame
end
averages.inspect.getAnchor = function()
	return InspectModelScene or InspectModelFrame
end

-- The bag bar's slot buttons pass through PaperDollItemSlotButton_Update as
-- well; only equipment slots count.
local function UpdateCharacterButton(button)
	local slot = button:GetID()
	if SKIPPED_SLOTS[slot] or slot < INVSLOT_FIRST_EQUIPPED or slot > INVSLOT_LAST_EQUIPPED then
		return
	end
	updaters[button] = UpdateCharacterButton
	local location = ItemLocation:CreateFromEquipmentSlot(slot)
	UpdateLocation(button, location, module.db.character)
	SetSlotLevel(averages.character, slot, C_Item.DoesItemExist(location) and C_Item.GetCurrentItemLevel(location) or nil)
end

local function UpdateBagButton(button)
	updaters[button] = UpdateBagButton
	local location = ItemLocation:CreateFromBagAndSlot(button:GetBagID(), button:GetID())
	local link = C_Item.DoesItemExist(location) and C_Item.GetItemLink(location)
	UpdateLocation(button, location, module.db.bags and link and IsGear(link))
end

local function UpdateInspectButton(button)
	local slot = button:GetID()
	local unit = InspectFrame and InspectFrame.unit
	if SKIPPED_SLOTS[slot] or not unit then
		return
	end
	updaters[button] = UpdateInspectButton
	local link = GetInventoryItemLink(unit, slot)
	-- Not cached yet: INSPECT_READY updates the slots again.
	local level = link and C_Item.GetDetailedItemLevelInfo(link)
	if link and module.db.inspect then
		SetText(button, level, GetInventoryItemQuality(unit, slot))
	else
		SetText(button)
	end
	SetSlotLevel(averages.inspect, slot, link and (level or false) or nil)
end

-- Bag item buttons pass through this global on every bag update. Only
-- buttons inside a bag window count: loot and merchant buttons have no bag ID,
-- and the bag bar's slot buttons do have one but sit on the bag bar.
local function IsContainerItemButton(button)
	if button.isBag or type(button.GetBagID) ~= "function" then
		return false
	end
	local parent = button:GetParent()
	return parent ~= nil and type(parent.IsCombinedBagContainer) == "function" and button:GetBagID() ~= nil
end

function module:OnSetItemButtonQuality(button)
	if IsContainerItemButton(button) then
		UpdateBagButton(button)
	end
end

function module:HookInspect()
	self:SecureHook("InspectPaperDollItemSlotButton_Update", function(_, button)
		UpdateInspectButton(button)
	end)
end

function module:ADDON_LOADED(name)
	if name == "Blizzard_InspectUI" then
		self:HookInspect()
		self:UnregisterEvent("ADDON_LOADED")
	end
end

function module:RefreshAll()
	for button, update in pairs(updaters) do
		update(button)
	end
end

function module:OnEnable()
	self:SecureHook("PaperDollItemSlotButton_Update", function(_, button)
		UpdateCharacterButton(button)
	end)
	self:SecureHook("SetItemButtonQuality", self.OnSetItemButtonQuality)
	if C_AddOns.IsAddOnLoaded("Blizzard_InspectUI") then
		self:HookInspect()
	else
		self:RegisterEvent("ADDON_LOADED")
	end
	self:RefreshAll()
end

function module:OnDisable()
	for _, text in pairs(texts) do
		text:Hide()
	end
	for _, average in pairs(averages) do
		if average.text then
			average.text:Hide()
		end
	end
end

function module:OnOptionChanged()
	self:RefreshAll()
end
