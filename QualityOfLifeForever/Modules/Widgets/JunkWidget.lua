-- luacheck: read globals CreateFrame CreateFont STANDARD_TEXT_FONT C_Container C_Item C_Timer Enum NUM_BAG_SLOTS GameTooltip GetCursorInfo ClearCursor DeleteCursorItem
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Junk widget",
		NOTE = "Cheapest gray items, click to delete",
		DESC = "A small movable list of the cheapest gray (junk) items in your bags, cheapest first by vendor value of the whole stack. Click an item to delete it and free a bag slot out in the world, where you can't sell; right-click it to never list it again. Hidden while you carry no gray items. Drag the widget's edge to move it; scale it in {Edit Mode}.",
		NOTICE = "A click deletes the item right away, without asking. Only gray items are listed, plus white ones if you turn that on.",
		EDIT_MODE_NAME = "QoL Forever: Junk widget",
		SECTION_SHOW = "Show",
		SECTION_LOOK = "Appearance",
		COUNT = "Items shown",
		COUNT_DESC = "How many of the cheapest items are listed.",
		INCLUDE_COMMON = "Include white items",
		INCLUDE_COMMON_DESC = "Also lists white (common) items that sell to a vendor, e.g. cloth, food or white gear. Never listed: quest items, items without a vendor value (like your Hearthstone), fishing poles, profession tools, bags, ammo and reagents.",
		IGNORED = "Ignored items",
		IGNORED_DESC = "Right-click an item in the widget to never list it again. This forgets all of them.",
		IGNORED_RESET = "Reset",
		IGNORED_RESET_DONE = "Ignored items reset.",
		RIGHT_CLICK_TO_IGNORE = "Right-click to never list this item",
		IGNORE_ADDED = "No longer listed: %s",
		FONT_SIZE = "Text size",
		FONT_SIZE_DESC = "Size of the widget's text and icons. The widget grows with it.",
		BG_OPACITY = "Background opacity",
		BG_OPACITY_DESC = "Opacity of the widget's background and border, 0 % (transparent) to 100 %.",
		CLICK_TO_DELETE = "Click to delete",
		NO_VALUE = "no value",
		DELETED = "Deleted: %s",
	},
	deDE = {
		TITLE = "Plunder-Widget",
		NOTE = "Günstigste graue Gegenstände, Klick löscht",
		DESC = "Eine kleine verschiebbare Liste der günstigsten grauen Gegenstände (Plunder) in deinen Taschen, aufsteigend nach Händlerwert des ganzen Stapels. Ein Klick löscht den Gegenstand und macht unterwegs, wo du nichts verkaufen kannst, einen Taschenplatz frei, ein Rechtsklick blendet ihn dauerhaft aus. Ausgeblendet, solange du keine grauen Gegenstände dabei hast. Zum Verschieben am Rand ziehen; skalieren im {Bearbeitungsmodus}.",
		NOTICE = "Ein Klick löscht den Gegenstand sofort und ohne Nachfrage. Es werden nur graue Gegenstände angezeigt, auf Wunsch auch weiße.",
		EDIT_MODE_NAME = "QoL Forever: Plunder-Widget",
		SECTION_SHOW = "Anzeigen",
		SECTION_LOOK = "Darstellung",
		COUNT = "Angezeigte Gegenstände",
		COUNT_DESC = "Wie viele der günstigsten Gegenstände aufgelistet werden.",
		INCLUDE_COMMON = "Weiße Gegenstände einbeziehen",
		INCLUDE_COMMON_DESC = "Listet auch weiße (gewöhnliche) Gegenstände, die ein Händler ankauft, z. B. Stoff, Essen oder weiße Ausrüstung. Nie aufgelistet: Questgegenstände, Gegenstände ohne Händlerwert (wie dein Ruhestein), Angelruten, Berufswerkzeuge, Taschen, Munition und Reagenzien.",
		IGNORED = "Ignorierte Gegenstände",
		IGNORED_DESC = "Rechtsklick auf einen Gegenstand im Widget blendet ihn dauerhaft aus. Hiermit werden alle wieder angezeigt.",
		IGNORED_RESET = "Zurücksetzen",
		IGNORED_RESET_DONE = "Ignorierte Gegenstände zurückgesetzt.",
		RIGHT_CLICK_TO_IGNORE = "Rechtsklick, um diesen Gegenstand nie mehr anzuzeigen",
		IGNORE_ADDED = "Wird nicht mehr angezeigt: %s",
		FONT_SIZE = "Textgröße",
		FONT_SIZE_DESC = "Größe von Text und Symbolen des Widgets. Das Widget wächst mit.",
		BG_OPACITY = "Hintergrund-Deckkraft",
		BG_OPACITY_DESC = "Deckkraft von Hintergrund und Rahmen des Widgets, von 0 % (durchsichtig) bis 100 %.",
		CLICK_TO_DELETE = "Klicken zum Löschen",
		NO_VALUE = "kein Wert",
		DELETED = "Gelöscht: %s",
	},
})

local function FormatPercent(value)
	return ("%d%%"):format(value)
end

local module = ns:NewModule("JunkWidget", {
	title = L.TITLE,
	description = L.DESC,
	note = L.NOTE,
	notice = L.NOTICE,
	category = "WIDGETS",
	order = 60,
	defaults = {
		count = 3,
		includeCommon = false,
		ignored = {},
		fontSize = 11,
		backgroundOpacity = 92,
		textOutline = "NONE",
		textShadow = true,
		showTitle = false,
	},
	options = {
		{ type = "header", label = L.SECTION_SHOW },
		{ key = "count", type = "slider", label = L.COUNT, tooltip = L.COUNT_DESC, min = 1, max = 5, step = 1 },
		{ key = "includeCommon", type = "checkbox", label = L.INCLUDE_COMMON, tooltip = L.INCLUDE_COMMON_DESC },
		{
			type = "button",
			label = L.IGNORED,
			buttonText = L.IGNORED_RESET,
			tooltip = L.IGNORED_DESC,
			onClick = function(self)
				self.db.ignored = {}
				self:Update()
				self:Print(L.IGNORED_RESET_DONE)
			end,
		},
		{ type = "header", label = L.SECTION_LOOK },
		{ key = "fontSize", type = "slider", label = L.FONT_SIZE, tooltip = L.FONT_SIZE_DESC, min = 8, max = 20, step = 1 },
		ns:TextOutlineOption(),
		ns:TextShadowOption(),
		{ key = "backgroundOpacity", type = "slider", label = L.BG_OPACITY, tooltip = L.BG_OPACITY_DESC, min = 0, max = 100, step = 1, format = FormatPercent },
		ns:TitleOption(),
	},
})

-- Sizes at the default text size of 11; they scale with the text size.
local BASE_FONT_SIZE = 11
local BASE_WIDTH = 220
local PADDING = 6
local ICON_GAP = 4
local ROW_GAP = 3
local NAME_COLORS = {
	[Enum.ItemQuality.Poor] = { 0.62, 0.62, 0.62 },
	[Enum.ItemQuality.Common] = { 1, 1, 1 },
}
local PRICE_COLOR = { 0.9, 0.9, 0.9 }

local IsSecret = ns.Utils.IsSecret
local frame
local rows = {}
-- Shown empty while Edit Mode or the options window is open, so the widget
-- can be placed without junk in the bags.
local editing, optionsShown = false, false

local function Scaled(value)
	return math.floor(value * module.db.fontSize / BASE_FONT_SIZE + 0.5)
end

-- White items of these classes are useful even though they sell.
local PROTECTED_CLASSES = {
	[Enum.ItemClass.Container] = true,
	[Enum.ItemClass.Reagent] = true,
	[Enum.ItemClass.Projectile] = true,
	[Enum.ItemClass.Quiver] = true,
	[Enum.ItemClass.Questitem] = true,
	[Enum.ItemClass.Key] = true,
	[Enum.ItemClass.Profession] = true,
}

-- Profession tools that are plain trade goods (item IDs from wowhead.com/classic).
local PROTECTED_ITEMS = {
	[2901] = true, -- Mining Pick
	[5956] = true, -- Blacksmith Hammer
	[6218] = true, -- Runed Copper Rod
	[6219] = true, -- Arclight Spanner
	[6339] = true, -- Runed Silver Rod
	[7005] = true, -- Skinning Knife
	[10498] = true, -- Gyromatic Micro-Adjustor
	[11130] = true, -- Runed Golden Rod
	[11145] = true, -- Runed Truesilver Rod
	[16207] = true, -- Runed Arcanite Rod
}

local function IsProtected(itemID, bag, slot)
	if PROTECTED_ITEMS[itemID] then
		return true
	end
	local _, _, _, _, _, classID, subclassID = C_Item.GetItemInfoInstant(itemID)
	if PROTECTED_CLASSES[classID] or (classID == Enum.ItemClass.Weapon and subclassID == Enum.ItemWeaponSubclass.Fishingpole) then
		return true
	end
	local questInfo = C_Container.GetContainerItemQuestInfo(bag, slot)
	return questInfo and (questInfo.isQuestItem or questInfo.questID) and true or false
end

-- Gray items, and optionally white ones that sell to a vendor and aren't
-- protected (Hearthstone, tools, bags, ammo …); never items the player ignored.
local function IsListed(info, bag, slot)
	if module.db.ignored[info.itemID] then
		return false
	end
	if info.quality == Enum.ItemQuality.Poor then
		return true
	end
	if not module.db.includeCommon or info.quality ~= Enum.ItemQuality.Common or info.hasNoValue then
		return false
	end
	return not IsProtected(info.itemID, bag, slot)
end

-- Listed items in the bags with the vendor value of the whole stack, cheapest
-- first: { bag, slot, itemID, link, icon, quality, value }.
local function CollectJunk()
	local junk = {}
	for bag = 0, NUM_BAG_SLOTS do
		for slot = 1, C_Container.GetContainerNumSlots(bag) do
			local info = C_Container.GetContainerItemInfo(bag, slot)
			if info and not IsSecret(info.itemID) and IsListed(info, bag, slot) then
				local sellPrice = not info.hasNoValue and select(11, C_Item.GetItemInfo(info.itemID)) or 0
				junk[#junk + 1] = {
					bag = bag,
					slot = slot,
					itemID = info.itemID,
					link = info.hyperlink,
					icon = info.iconFileID,
					quality = info.quality,
					value = (sellPrice or 0) * info.stackCount,
				}
			end
		end
	end
	table.sort(junk, function(a, b)
		if a.value ~= b.value then
			return a.value < b.value
		end
		return a.itemID < b.itemID
	end)
	return junk
end

-- Deletes only if the slot still holds the listed item and the cursor is free.
function module:Delete(entry)
	if GetCursorInfo() then
		return
	end
	local info = C_Container.GetContainerItemInfo(entry.bag, entry.slot)
	if not info or info.itemID ~= entry.itemID or info.isLocked or not IsListed(info, entry.bag, entry.slot) then
		self:Update()
		return
	end
	C_Container.PickupContainerItem(entry.bag, entry.slot)
	local cursorType, cursorItemID = GetCursorInfo()
	if cursorType == "item" and cursorItemID == entry.itemID then
		DeleteCursorItem()
		self:Print(L.DELETED:format(entry.link or ""))
	else
		ClearCursor()
	end
end

function module:Ignore(entry)
	self.db.ignored[entry.itemID] = true
	self:Print(L.IGNORE_ADDED:format(entry.link or ""))
	GameTooltip:Hide()
	self:Update()
end

local function OnRowClick(row, button)
	if not row.entry then
		return
	end
	if button == "RightButton" then
		module:Ignore(row.entry)
	else
		module:Delete(row.entry)
	end
end

local function OnRowEnter(row)
	if not row.entry then
		return
	end
	GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
	GameTooltip:SetBagItem(row.entry.bag, row.entry.slot)
	GameTooltip:AddLine(L.CLICK_TO_DELETE, 1, 0.45, 0.45)
	GameTooltip:AddLine(L.RIGHT_CLICK_TO_IGNORE, 0.6, 0.6, 0.6)
	GameTooltip:Show()
end

local function OnRowLeave()
	GameTooltip:Hide()
end

local function GetRow(index)
	local row = rows[index]
	if not row then
		row = CreateFrame("Button", nil, frame)
		row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
		row:SetScript("OnClick", OnRowClick)
		row:SetScript("OnEnter", OnRowEnter)
		row:SetScript("OnLeave", OnRowLeave)
		row:SetHighlightTexture("Interface\\Buttons\\WHITE8X8")
		row:GetHighlightTexture():SetVertexColor(1, 1, 1, 0.08)
		row.Icon = row:CreateTexture(nil, "ARTWORK")
		row.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		row.Icon:SetPoint("LEFT")
		row.Price = row:CreateFontString(nil, "OVERLAY")
		row.Price:SetFontObject(module.font)
		row.Price:SetJustifyH("RIGHT")
		row.Price:SetPoint("RIGHT")
		row.Price:SetTextColor(unpack(PRICE_COLOR))
		row.Name = row:CreateFontString(nil, "OVERLAY")
		row.Name:SetFontObject(module.font)
		row.Name:SetJustifyH("LEFT")
		row.Name:SetWordWrap(false)
		rows[index] = row
	end
	return row
end

local function CreateWidget()
	frame = ns:CreateOverlay("JunkWidget", {
		title = L.EDIT_MODE_NAME,
		module = module,
		width = BASE_WIDTH,
		height = 40,
		default = { point = "TOP", x = 0, y = -330 },
	})
end

function module:Update()
	if not frame or not self.enabled then
		return
	end
	local junk = CollectJunk()
	local count = math.min(#junk, self.db.count)
	for i = count + 1, #rows do
		rows[i]:Hide()
		rows[i].entry = nil
	end
	if count == 0 then
		frame:SetSize(Scaled(BASE_WIDTH), PADDING * 2 + self.db.fontSize + Scaled(5))
		frame:SetShown(editing or optionsShown)
		return
	end

	local iconSize = self.db.fontSize + Scaled(5)
	local width = Scaled(BASE_WIDTH)
	for i = 1, count do
		local entry, row = junk[i], GetRow(i)
		row.entry = entry
		row:ClearAllPoints()
		row:SetPoint("TOPLEFT", PADDING, -(PADDING + (i - 1) * (iconSize + ROW_GAP)))
		row:SetSize(width - PADDING * 2, iconSize)
		row.Icon:SetSize(iconSize, iconSize)
		row.Icon:SetTexture(entry.icon)
		row.Price:SetText(entry.value > 0 and ns.Utils.FormatMoney(entry.value) or L.NO_VALUE)
		row.Name:ClearAllPoints()
		row.Name:SetPoint("LEFT", row.Icon, "RIGHT", Scaled(ICON_GAP), 0)
		row.Name:SetPoint("RIGHT", row.Price, "LEFT", -Scaled(ICON_GAP), 0)
		row.Name:SetText(C_Item.GetItemNameByID(entry.itemID) or entry.link or "")
		row.Name:SetTextColor(unpack(NAME_COLORS[entry.quality]))
		row:Show()
	end
	frame:SetSize(width, PADDING * 2 + count * iconSize + (count - 1) * ROW_GAP)
	frame:Show()
end

-- Bag updates come in bursts; item info may arrive later for uncached items.
function module:QueueUpdate()
	if not self.updatePending then
		self.updatePending = true
		C_Timer.After(0.2, function()
			self.updatePending = false
			self:Update()
		end)
	end
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
	self.font = CreateFont("QualityOfLifeForeverJunkWidgetFont")
	self.font:SetFont(STANDARD_TEXT_FONT, BASE_FONT_SIZE, "")
	self.font:SetShadowOffset(1, -1)
	self.font:SetShadowColor(0, 0, 0, 0.8)
end

function module:OnEnable()
	if not frame then
		CreateWidget()
	end
	self:ApplyLayout()
	self:RegisterEvent("BAG_UPDATE_DELAYED", self.QueueUpdate)
	self:RegisterEvent("GET_ITEM_INFO_RECEIVED", self.QueueUpdate)
	self:RegisterEvent("PLAYER_ENTERING_WORLD", self.QueueUpdate)
	optionsShown = ns:IsOptionsPreviewShown()
	self:RegisterEditModeCallback("enter", function()
		editing = true
		self:Update()
	end)
	self:RegisterEditModeCallback("exit", function()
		editing = false
		self:Update()
	end)
	self:Update()
end

function module:OnOptionsShown(shown)
	optionsShown = shown
	self:Update()
end

function module:OnDisable()
	frame:Hide()
end
