-- luacheck: read globals CreateFrame CreateFont STANDARD_TEXT_FONT C_Container C_Item C_Timer Enum NUM_BAG_SLOTS GameTooltip GetCursorInfo ClearCursor DeleteCursorItem
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Junk widget",
		NOTE = "Cheapest gray items, click to delete",
		DESC = "A small movable list of the cheapest gray (junk) items in your bags, cheapest first by vendor value of the whole stack. Click an item to delete it and free a bag slot out in the world, where you can't sell. Hidden while you carry no gray items. Drag the widget's edge to move it; scale it in {Edit Mode}.",
		NOTICE = "A click deletes the item right away, without asking. Only gray items are listed.",
		EDIT_MODE_NAME = "QoL Forever: Junk",
		SECTION_SHOW = "Show",
		SECTION_LOOK = "Appearance",
		COUNT = "Items shown",
		COUNT_DESC = "How many of the cheapest gray items are listed.",
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
		DESC = "Eine kleine verschiebbare Liste der günstigsten grauen Gegenstände (Plunder) in deinen Taschen, aufsteigend nach Händlerwert des ganzen Stapels. Ein Klick löscht den Gegenstand und macht unterwegs, wo du nichts verkaufen kannst, einen Taschenplatz frei. Ausgeblendet, solange du keine grauen Gegenstände dabei hast. Zum Verschieben am Rand ziehen; skalieren im {Bearbeitungsmodus}.",
		NOTICE = "Ein Klick löscht den Gegenstand sofort und ohne Nachfrage. Es werden nur graue Gegenstände angezeigt.",
		EDIT_MODE_NAME = "QoL Forever: Plunder",
		SECTION_SHOW = "Anzeigen",
		SECTION_LOOK = "Darstellung",
		COUNT = "Angezeigte Gegenstände",
		COUNT_DESC = "Wie viele der günstigsten grauen Gegenstände aufgelistet werden.",
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
		fontSize = 11,
		backgroundOpacity = 92,
		textOutline = "NONE",
		textShadow = true,
		showTitle = false,
	},
	options = {
		{ type = "header", label = L.SECTION_SHOW },
		{ key = "count", type = "slider", label = L.COUNT, tooltip = L.COUNT_DESC, min = 1, max = 5, step = 1 },
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
local NAME_COLOR = { 0.62, 0.62, 0.62 }
local PRICE_COLOR = { 0.9, 0.9, 0.9 }

local IsSecret = ns.Utils.IsSecret
local LibEditMode = ns.LibEditMode
local frame
local rows = {}
-- Shown empty while Edit Mode or the options window is open, so the widget
-- can be placed without junk in the bags.
local editing, optionsShown = false, false

local function Scaled(value)
	return math.floor(value * module.db.fontSize / BASE_FONT_SIZE + 0.5)
end

-- Gray items in the bags with the vendor value of the whole stack, cheapest
-- first: { bag, slot, itemID, link, icon, value }.
local function CollectJunk()
	local junk = {}
	for bag = 0, NUM_BAG_SLOTS do
		for slot = 1, C_Container.GetContainerNumSlots(bag) do
			local info = C_Container.GetContainerItemInfo(bag, slot)
			if info and info.quality == Enum.ItemQuality.Poor and not IsSecret(info.itemID) then
				local sellPrice = not info.hasNoValue and select(11, C_Item.GetItemInfo(info.itemID)) or 0
				junk[#junk + 1] = {
					bag = bag,
					slot = slot,
					itemID = info.itemID,
					link = info.hyperlink,
					icon = info.iconFileID,
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
	if not info or info.itemID ~= entry.itemID or info.quality ~= Enum.ItemQuality.Poor or info.isLocked then
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

local function OnRowClick(row)
	if row.entry then
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
	GameTooltip:Show()
end

local function OnRowLeave()
	GameTooltip:Hide()
end

local function GetRow(index)
	local row = rows[index]
	if not row then
		row = CreateFrame("Button", nil, frame)
		row:RegisterForClicks("LeftButtonUp")
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
		row.Name:SetTextColor(unpack(NAME_COLOR))
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
	optionsShown = ns:IsOptionsShown()
	if not self.editModeHooked then
		self.editModeHooked = true
		LibEditMode:RegisterCallback("enter", function()
			editing = true
			self:Update()
		end)
		LibEditMode:RegisterCallback("exit", function()
			editing = false
			self:Update()
		end)
	end
	self:Update()
end

function module:OnOptionsShown(shown)
	optionsShown = shown
	self:Update()
end

function module:OnDisable()
	frame:Hide()
end
