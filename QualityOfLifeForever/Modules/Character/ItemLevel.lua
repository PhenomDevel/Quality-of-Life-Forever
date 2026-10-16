-- luacheck: read globals C_Item C_AddOns ItemLocation Enum ITEM_QUALITY_COLORS InspectFrame GetInventoryItemLink GetInventoryItemQuality INVSLOT_BODY INVSLOT_TABARD
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Item level",
		NOTE = "On equipment and in bags",
		DESC = "Shows the item level on equipped items, equipment in your bags and on inspected players.",
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
	},
	deDE = {
		TITLE = "Gegenstandsstufe",
		NOTE = "An Ausrüstung und in Taschen",
		DESC = "Zeigt die Gegenstandsstufe auf angelegten Gegenständen, Ausrüstung in den Taschen und bei betrachteten Spielern.",
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
	},
})

local module = ns:NewModule("ItemLevel", {
	title = L.TITLE,
	description = L.DESC,
	note = L.NOTE,
	category = "CHARACTER",
	defaults = {
		character = true,
		bags = true,
		inspect = true,
		qualityColor = true,
	},
	options = {
		{ type = "header", label = L.SECTION_SHOW },
		{ key = "character", type = "checkbox", label = L.CHARACTER, tooltip = L.CHARACTER_DESC },
		{ key = "bags", type = "checkbox", label = L.BAGS, tooltip = L.BAGS_DESC },
		{ key = "inspect", type = "checkbox", label = L.INSPECT, tooltip = L.INSPECT_DESC },
		{ type = "header", label = L.SECTION_DISPLAY },
		{ key = "qualityColor", type = "checkbox", label = L.QUALITY_COLOR, tooltip = L.QUALITY_COLOR_DESC },
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

local function UpdateCharacterButton(button)
	local slot = button:GetID()
	if SKIPPED_SLOTS[slot] then
		return
	end
	updaters[button] = UpdateCharacterButton
	UpdateLocation(button, ItemLocation:CreateFromEquipmentSlot(slot), module.db.character)
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
	local link = module.db.inspect and GetInventoryItemLink(unit, slot)
	if link then
		-- Not cached yet: INSPECT_READY updates the slots again.
		SetText(button, C_Item.GetDetailedItemLevelInfo(link), GetInventoryItemQuality(unit, slot))
	else
		SetText(button)
	end
end

-- Bag item buttons pass through this global on every bag update; other item
-- buttons (loot, merchant, …) don't have a bag ID and are ignored.
function module:OnSetItemButtonQuality(button)
	if type(button.GetBagID) == "function" and button:GetBagID() then
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
end

function module:OnOptionChanged()
	self:RefreshAll()
end
