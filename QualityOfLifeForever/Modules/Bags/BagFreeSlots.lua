-- luacheck: read globals C_Container MainMenuBarBackpackButton BACKPACK_CONTAINER NUM_BAG_SLOTS RED_FONT_COLOR HIGHLIGHT_FONT_COLOR
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Free bag slots",
		NOTE = "Free / total slots on the backpack button",
		DESC = "Shows free and total slots of your bags as \"free/total\" on the backpack button. Profession bags, quivers and ammo pouches are not counted. Red when your bags are full.",
		NOTICE = "Turns off the game's own free slot count on the backpack button (setting `displayFreeBagSlots`), which would overlap. Disabling restores your previous setting.",
		FONT_SIZE = "Text size",
		FONT_SIZE_DESC = "Size of the free/total text on the backpack button.",
	},
	deDE = {
		TITLE = "Freie Taschenplätze",
		NOTE = "Freie / gesamte Plätze am Rucksack-Button",
		DESC = "Zeigt freie und gesamte Plätze deiner Taschen als „frei/gesamt“ auf dem Rucksack-Button. Berufstaschen, Köcher und Munitionsbeutel werden nicht mitgezählt. Rot, wenn deine Taschen voll sind.",
		NOTICE = "Schaltet die spieleigene Anzeige freier Plätze auf dem Rucksack-Button aus (Einstellung `displayFreeBagSlots`), die sich sonst überlagern würde. Beim Deaktivieren wird deine vorherige Einstellung wiederhergestellt.",
		FONT_SIZE = "Textgröße",
		FONT_SIZE_DESC = "Größe des Textes frei/gesamt auf dem Rucksack-Button.",
	},
})

local module = ns:NewModule("BagFreeSlots", {
	title = L.TITLE,
	description = L.DESC,
	note = L.NOTE,
	notice = L.NOTICE,
	category = "BAGS",
	order = 20,
	defaults = {
		fontSize = 14,
	},
	options = {
		{ key = "fontSize", type = "slider", label = L.FONT_SIZE, tooltip = L.FONT_SIZE_DESC, min = 8, max = 24, step = 1 },
	},
})

local text, fontPath, fontFlags

-- Only general-purpose bags (bag family 0) can hold any item.
local function CountSlots()
	local free, total = 0, 0
	for bag = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
		local numFree, family = C_Container.GetContainerNumFreeSlots(bag)
		if family == 0 then
			free = free + numFree
			total = total + C_Container.GetContainerNumSlots(bag)
		end
	end
	return free, total
end

function module:Update()
	if not text then
		return
	end
	local free, total = CountSlots()
	local color = free == 0 and RED_FONT_COLOR or HIGHLIGHT_FONT_COLOR
	text:SetFormattedText("%d/%d", free, total)
	text:SetTextColor(color:GetRGB())
	text:Show()
end

function module:OnEnable()
	if not MainMenuBarBackpackButton then
		return
	end
	if not text then
		-- Same spot as the game's own count, which is turned off below.
		text = MainMenuBarBackpackButton:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
		text:SetPoint("CENTER", 0, -10)
		fontPath, _, fontFlags = text:GetFont()
	end
	self:ApplyFontSize()
	self:SetCVar("displayFreeBagSlots", 0)
	self:RegisterEvent("BAG_UPDATE_DELAYED", self.Update)
	self:RegisterEvent("BAG_CONTAINER_UPDATE", self.Update)
	self:RegisterEvent("PLAYER_ENTERING_WORLD", self.Update)
	self:Update()
end

function module:ApplyFontSize()
	if text and fontPath then
		text:SetFont(fontPath, self.db.fontSize, fontFlags)
	end
end

function module:OnOptionChanged(key)
	if key == "fontSize" then
		self:ApplyFontSize()
	end
end

function module:OnDisable()
	if text then
		text:Hide()
	end
end
