-- luacheck: read globals CreateFont STANDARD_TEXT_FONT C_Item Enum UnitClass UnitGUID GetInventoryItemCount GetInventoryItemID GetInventoryItemTexture INVSLOT_AMMO INVSLOT_RANGED
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Ammo & reagents widget",
		NOTE = "Ammo and class reagents left",
		DESC = "A small movable display of your ammo and the reagents your class uses, e.g. Soul Shard, Arcane Powder or Ankh. A reagent appears once you carried it and stays visible at 0, so you notice when you run out. Drag it to move it; scale it in {Edit Mode}.",
		EDIT_MODE_NAME = "QoL Forever: Ammo & reagents",
		SECTION_SHOW = "Show",
		SECTION_WARN = "Warning",
		SECTION_LOOK = "Appearance",
		SHOW_AMMO = "Ammo",
		SHOW_AMMO_DESC = "Ammo in your bags of the type in your ammo slot, while a bow, gun or crossbow is equipped.",
		SHOW_REAGENTS = "Reagents",
		SHOW_REAGENTS_DESC = "Reagents of your class you carried at least once on this character.",
		AMMO_WARN = "Ammo warning",
		AMMO_WARN_DESC = "The ammo count turns red at or below this amount.",
		REAGENT_WARN = "Reagent warning",
		REAGENT_WARN_DESC = "A reagent count turns red at or below this amount.",
		LAYOUT = "Layout",
		LAYOUT_DESC = "Horizontal: all entries in one line. Vertical: stacked.",
		LAYOUT_HORIZONTAL = "Horizontal",
		LAYOUT_VERTICAL = "Vertical",
		FONT_SIZE = "Text size",
		FONT_SIZE_DESC = "Size of the widget's text and icons. The widget grows with it.",
		BG_OPACITY = "Background opacity",
		BG_OPACITY_DESC = "Opacity of the widget's background and border, 0 % (transparent) to 100 %.",
		FORGET = "Remembered reagents",
		FORGET_DESC = "Forgets the reagents of this character; only those in your bags stay visible.",
		FORGET_BUTTON = "Forget",
		FORGET_DONE = "Remembered reagents of this character forgotten.",
	},
	deDE = {
		TITLE = "Munitions- & Reagenzien-Widget",
		NOTE = "Verbleibende Munition und Klassenreagenzien",
		DESC = "Eine kleine verschiebbare Anzeige deiner Munition und der Reagenzien deiner Klasse, z. B. Seelensplitter, Arkanes Pulver oder Ankh. Ein Reagenz erscheint, sobald du es einmal dabei hattest, und bleibt bei 0 sichtbar, damit du merkst, wenn es ausgeht. Zum Verschieben ziehen; skalieren im {Bearbeitungsmodus}.",
		EDIT_MODE_NAME = "QoL Forever: Munition & Reagenzien",
		SECTION_SHOW = "Anzeigen",
		SECTION_WARN = "Warnung",
		SECTION_LOOK = "Darstellung",
		SHOW_AMMO = "Munition",
		SHOW_AMMO_DESC = "Munition in den Taschen vom Typ im Munitionsplatz, solange ein Bogen, Gewehr oder eine Armbrust angelegt ist.",
		SHOW_REAGENTS = "Reagenzien",
		SHOW_REAGENTS_DESC = "Reagenzien deiner Klasse, die du auf diesem Charakter mindestens einmal dabei hattest.",
		AMMO_WARN = "Munitionswarnung",
		AMMO_WARN_DESC = "Die Munitionsanzahl wird bei dieser Menge oder weniger rot.",
		REAGENT_WARN = "Reagenzienwarnung",
		REAGENT_WARN_DESC = "Eine Reagenzienanzahl wird bei dieser Menge oder weniger rot.",
		LAYOUT = "Ausrichtung",
		LAYOUT_DESC = "Horizontal: alle Einträge in einer Zeile. Vertikal: untereinander.",
		LAYOUT_HORIZONTAL = "Horizontal",
		LAYOUT_VERTICAL = "Vertikal",
		FONT_SIZE = "Textgröße",
		FONT_SIZE_DESC = "Größe von Text und Symbolen des Widgets. Das Widget wächst mit.",
		BG_OPACITY = "Hintergrund-Deckkraft",
		BG_OPACITY_DESC = "Deckkraft von Hintergrund und Rahmen des Widgets, von 0 % (durchsichtig) bis 100 %.",
		FORGET = "Gemerkte Reagenzien",
		FORGET_DESC = "Vergisst die Reagenzien dieses Charakters; nur die in deinen Taschen bleiben sichtbar.",
		FORGET_BUTTON = "Vergessen",
		FORGET_DONE = "Gemerkte Reagenzien dieses Charakters vergessen.",
	},
})

local function FormatPercent(value)
	return ("%d%%"):format(value)
end

local module = ns:NewModule("ReagentWidget", {
	title = L.TITLE,
	description = L.DESC,
	note = L.NOTE,
	category = "WIDGETS",
	defaults = {
		showAmmo = true,
		showReagents = true,
		ammoWarn = 200,
		reagentWarn = 5,
		layout = "HORIZONTAL",
		fontSize = 11,
		backgroundOpacity = 92,
		textOutline = "NONE",
		textShadow = true,
	},
	options = {
		{ type = "header", label = L.SECTION_SHOW },
		{ key = "showAmmo", type = "checkbox", label = L.SHOW_AMMO, tooltip = L.SHOW_AMMO_DESC },
		{ key = "showReagents", type = "checkbox", label = L.SHOW_REAGENTS, tooltip = L.SHOW_REAGENTS_DESC },
		{ type = "header", label = L.SECTION_WARN },
		{ key = "ammoWarn", type = "slider", label = L.AMMO_WARN, tooltip = L.AMMO_WARN_DESC, min = 0, max = 1000, step = 50 },
		{ key = "reagentWarn", type = "slider", label = L.REAGENT_WARN, tooltip = L.REAGENT_WARN_DESC, min = 0, max = 20, step = 1 },
		{ type = "header", label = L.SECTION_LOOK },
		{
			key = "layout",
			type = "dropdown",
			label = L.LAYOUT,
			tooltip = L.LAYOUT_DESC,
			values = {
				{ value = "HORIZONTAL", label = L.LAYOUT_HORIZONTAL },
				{ value = "VERTICAL", label = L.LAYOUT_VERTICAL },
			},
		},
		{ key = "fontSize", type = "slider", label = L.FONT_SIZE, tooltip = L.FONT_SIZE_DESC, min = 8, max = 20, step = 1 },
		{ key = "backgroundOpacity", type = "slider", label = L.BG_OPACITY, tooltip = L.BG_OPACITY_DESC, min = 0, max = 100, step = 1, format = FormatPercent },
		ns:TextOutlineOption(),
		ns:TextShadowOption(),
		{
			type = "button",
			label = L.FORGET,
			buttonText = L.FORGET_BUTTON,
			tooltip = L.FORGET_DESC,
			onClick = function(self)
				self:ForgetReagents()
				self:Print(L.FORGET_DONE)
			end,
		},
	},
})

-- Class reagents by class file name, item IDs from wowhead.com (Classic).
local REAGENTS = {
	DRUID = {
		17021, -- Wild Berries
		17026, -- Wild Thornroot
		22147, -- Wild Quillvine
		17034, -- Maple Seed
		17035, -- Stranglethorn Seed
		17036, -- Ashwood Seed
		17037, -- Hornbeam Seed
		17038, -- Ironwood Seed
	},
	MAGE = {
		17020, -- Arcane Powder
		17031, -- Rune of Teleportation
		17032, -- Rune of Portals
		17056, -- Light Feather
	},
	PALADIN = {
		17033, -- Symbol of Divinity
		21177, -- Symbol of Kings
	},
	PRIEST = {
		17028, -- Holy Candle
		17029, -- Sacred Candle
		17056, -- Light Feather
	},
	ROGUE = {
		5140, -- Flash Powder
		5530, -- Blinding Powder
	},
	SHAMAN = {
		17030, -- Ankh
		17058, -- Fish Oil
		17057, -- Shiny Fish Scales
	},
	WARLOCK = {
		6265, -- Soul Shard
		5565, -- Infernal Stone
		16583, -- Demonic Figurine
	},
}

-- Sizes at the default text size of 11; they scale with the text size.
local BASE_FONT_SIZE = 11
local PADDING = 6
local ICON_GAP = 4
local ENTRY_GAP = 10
local ROW_GAP = 3
local PLAIN_COLOR = { 0.9, 0.9, 0.9 }
local LOW_COLOR = { 1, 0.45, 0.45 }

local frame
local entries = {}

local function Scaled(value)
	return math.floor(value * module.db.fontSize / BASE_FONT_SIZE + 0.5)
end

local function CreateWidget()
	frame = ns:CreateOverlay("ReagentWidget", {
		title = L.EDIT_MODE_NAME,
		width = 80,
		height = 26,
		default = { point = "TOP", x = 0, y = -280 },
	})
end

local function GetEntry(index)
	local entry = entries[index]
	if not entry then
		entry = {}
		entry.icon = frame:CreateTexture(nil, "ARTWORK")
		entry.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		entry.count = frame:CreateFontString(nil, "OVERLAY")
		entry.count:SetFontObject(module.font)
		entry.count:SetJustifyH("LEFT")
		entry.count:SetWordWrap(false)
		entries[index] = entry
	end
	return entry
end

-- Reagents remembered for this character: { [itemID] = true }.
function module:GetSeen()
	local guid = UnitGUID("player")
	self.db.seen = self.db.seen or {}
	self.db.seen[guid] = self.db.seen[guid] or {}
	return self.db.seen[guid]
end

function module:ForgetReagents()
	if self.db.seen then
		self.db.seen[UnitGUID("player")] = nil
	end
	self:Update()
end

-- Bows, guns and crossbows shoot ammo; wands and thrown weapons don't.
-- C_PaperDollInfo.AmmoNeeded() returned true for a priest in Forever.
local AMMO_WEAPONS = {
	[Enum.ItemWeaponSubclass.Bows] = true,
	[Enum.ItemWeaponSubclass.Guns] = true,
	[Enum.ItemWeaponSubclass.Crossbow] = true,
}

local function UsesAmmo()
	local itemID = GetInventoryItemID("player", INVSLOT_RANGED)
	if not itemID then
		return false
	end
	local _, _, _, _, _, classID, subclassID = C_Item.GetItemInfoInstant(itemID)
	return classID == Enum.ItemClass.Weapon and AMMO_WEAPONS[subclassID] == true
end

-- { icon, count, warn } for everything to show, ammo first.
function module:Collect()
	local list = {}
	if self.db.showAmmo and UsesAmmo() then
		local ammoID = GetInventoryItemID("player", INVSLOT_AMMO)
		list[#list + 1] = {
			icon = GetInventoryItemTexture("player", INVSLOT_AMMO) or "Interface\\PaperdollInfoFrame\\UI-Character-AmmoSlot",
			count = ammoID and GetInventoryItemCount("player", INVSLOT_AMMO) or 0,
			warn = self.db.ammoWarn,
		}
	end
	local _, class = UnitClass("player")
	if self.db.showReagents and REAGENTS[class] then
		local seen = self:GetSeen()
		for _, itemID in ipairs(REAGENTS[class]) do
			local count = C_Item.GetItemCount(itemID)
			if count > 0 then
				seen[itemID] = true
			end
			if seen[itemID] then
				list[#list + 1] = {
					icon = C_Item.GetItemIconByID(itemID),
					count = count,
					warn = self.db.reagentWarn,
				}
			end
		end
	end
	return list
end

function module:Update()
	if not frame or not self.enabled then
		return
	end
	local list = self:Collect()
	for i = #list + 1, #entries do
		entries[i].icon:Hide()
		entries[i].count:Hide()
	end
	if #list == 0 then
		frame:Hide()
		return
	end

	local size = self.db.fontSize
	local iconSize = size + Scaled(5)
	local vertical = self.db.layout == "VERTICAL"
	local x, y, width, countWidth = PADDING, -PADDING, 0, 0
	for i, data in ipairs(list) do
		local count = GetEntry(i).count
		count:SetText(data.count)
		countWidth = math.max(countWidth, math.ceil(count:GetUnboundedStringWidth()))
	end
	for i, data in ipairs(list) do
		local entry = GetEntry(i)
		entry.icon:SetTexture(data.icon)
		entry.icon:SetSize(iconSize, iconSize)
		entry.icon:ClearAllPoints()
		entry.icon:SetPoint("TOPLEFT", x, y)
		entry.icon:Show()
		entry.count:SetTextColor(unpack(data.count <= data.warn and LOW_COLOR or PLAIN_COLOR))
		entry.count:ClearAllPoints()
		entry.count:SetPoint("LEFT", entry.icon, "RIGHT", Scaled(ICON_GAP), 0)
		entry.count:Show()
		-- Vertical rows share the widest count so the widget keeps its width.
		local entryWidth = iconSize + Scaled(ICON_GAP)
			+ (vertical and countWidth or math.ceil(entry.count:GetUnboundedStringWidth()))
		if vertical then
			width = math.max(width, entryWidth)
			y = y - iconSize - ROW_GAP
		else
			x = x + entryWidth + Scaled(ENTRY_GAP)
			width = x - Scaled(ENTRY_GAP) - PADDING
		end
	end
	local rows = vertical and #list or 1
	frame:SetSize(PADDING * 2 + width, PADDING * 2 + rows * iconSize + (rows - 1) * ROW_GAP)
	frame:Show()
end

function module:ApplyLayout()
	ns:SetOverlayFont(self.font, self.db.fontSize, self.db)
	ns:SetOverlayBackgroundAlpha(frame, self.db.backgroundOpacity / 100)
end

function module:OnOptionChanged()
	self:ApplyLayout()
	self:Update()
end

function module:OnInitialize()
	self.font = CreateFont("QualityOfLifeForeverReagentWidgetFont")
	self.font:SetFont(STANDARD_TEXT_FONT, BASE_FONT_SIZE, "")
	self.font:SetShadowOffset(1, -1)
	self.font:SetShadowColor(0, 0, 0, 0.8)
end

function module:OnEnable()
	if not frame then
		CreateWidget()
	end
	self:ApplyLayout()
	self:RegisterEvent("BAG_UPDATE_DELAYED", self.Update)
	self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED", self.Update)
	self:RegisterEvent("PLAYER_ENTERING_WORLD", self.Update)
	self:Update()
end

function module:OnDisable()
	frame:Hide()
end
