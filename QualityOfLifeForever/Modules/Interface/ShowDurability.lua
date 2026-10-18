-- luacheck: read globals GetInventoryItemDurability INVSLOT_FIRST_EQUIPPED INVSLOT_LAST_EQUIPPED
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Durability",
		NOTE = "In percent on the character frame",
		DESC = "Shows the durability of each equipped item in percent on the character frame.",
		HIDE_FULL = "Hide at 100%",
		HIDE_FULL_DESC = "Shows only damaged items.",
	},
	deDE = {
		TITLE = "Haltbarkeit",
		NOTE = "In Prozent im Charakterfenster",
		DESC = "Zeigt die Haltbarkeit jedes angelegten Gegenstands in Prozent im Charakterfenster an.",
		HIDE_FULL = "Bei 100 % ausblenden",
		HIDE_FULL_DESC = "Zeigt nur beschädigte Gegenstände.",
	},
})

local module = ns:NewModule("ShowDurability", {
	title = L.TITLE,
	description = L.DESC,
	note = L.NOTE,
	category = "INTERFACE",
	defaults = {
		hideFull = true,
	},
	options = {
		{ key = "hideFull", type = "checkbox", label = L.HIDE_FULL, tooltip = L.HIDE_FULL_DESC },
	},
})

-- Equipment slot buttons seen so far, and their font strings.
local buttons, texts = {}, {}

local function GetColor(ratio)
	if ratio <= 0.25 then
		return 1, 0.1, 0.1
	elseif ratio <= 0.5 then
		return 1, 0.8, 0.1
	end
	return 1, 1, 1
end

function module:UpdateButton(button)
	local slot = button:GetID()
	if slot < INVSLOT_FIRST_EQUIPPED or slot > INVSLOT_LAST_EQUIPPED then
		return
	end
	buttons[button] = true
	local text = texts[button]
	local current, maximum = GetInventoryItemDurability(slot)
	if not current or not maximum or maximum == 0 or (self.db.hideFull and current >= maximum) then
		if text then
			text:Hide()
		end
		return
	end
	if not text then
		text = button:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
		text:SetPoint("TOP", button, "TOP", 0, -2)
		texts[button] = text
	end
	local ratio = current / maximum
	text:SetText(("%d%%"):format(ratio * 100))
	text:SetTextColor(GetColor(ratio))
	text:Show()
end

function module:UpdateAll()
	for button in pairs(buttons) do
		self:UpdateButton(button)
	end
end

function module:OnEnable()
	self:SecureHook("PaperDollItemSlotButton_Update", self.UpdateButton)
	-- Slot buttons don't refresh on durability loss while the frame is open.
	self:RegisterEvent("UPDATE_INVENTORY_DURABILITY", "UpdateAll")
	self:UpdateAll()
end

function module:OnDisable()
	for _, text in pairs(texts) do
		text:Hide()
	end
end

function module:OnOptionChanged()
	self:UpdateAll()
end
