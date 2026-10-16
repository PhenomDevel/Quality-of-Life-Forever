-- luacheck: read globals CharacterFrame PaperDollFrame C_TooltipInfo INVSLOT_FIRST_EQUIPPED INVSLOT_LAST_EQUIPPED REPAIR_COST
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Repair costs",
		NOTE = "Shown on the character frame",
		DESC = "Shows what repairing all equipped items costs at the top of the character frame. Hidden when nothing needs repairing.",
	},
	deDE = {
		TITLE = "Reparaturkosten",
		NOTE = "Im Charakterfenster angezeigt",
		DESC = "Zeigt oben im Charakterfenster, was die Reparatur aller angelegten Gegenstände kostet. Ausgeblendet, wenn nichts repariert werden muss.",
	},
})

local module = ns:NewModule("RepairCosts", {
	title = L.TITLE,
	description = L.DESC,
	note = L.NOTE,
	category = "CHARACTER",
})

local IsSecret = ns.Utils.IsSecret
local text

-- Sum of the repair costs in the tooltip data of every equipped item.
local function GetRepairCost()
	local total = 0
	for slot = INVSLOT_FIRST_EQUIPPED, INVSLOT_LAST_EQUIPPED do
		local data = C_TooltipInfo.GetInventoryItem("player", slot)
		local cost = data and data.repairCost
		if cost and not IsSecret(cost) then
			total = total + cost
		end
	end
	return total
end

function module:Update()
	if not text or not PaperDollFrame:IsVisible() then
		return
	end
	local cost = self.enabled and GetRepairCost() or 0
	if cost > 0 then
		text:SetFormattedText("%s %s", REPAIR_COST, ns.Utils.FormatMoney(cost))
		text:Show()
	else
		text:Hide()
	end
end

function module:OnEnable()
	if not text then
		local inset = CharacterFrame.Inset or PaperDollFrame
		text = PaperDollFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		text:SetPoint("TOP", inset, "TOP", 0, -6)
	end
	self:HookScript(PaperDollFrame, "OnShow", self.Update)
	for _, event in ipairs({ "UPDATE_INVENTORY_DURABILITY", "PLAYER_EQUIPMENT_CHANGED", "MERCHANT_CLOSED" }) do
		self:RegisterEvent(event, self.Update)
	end
	self:Update()
end

function module:OnDisable()
	if text then
		text:Hide()
	end
end
