-- luacheck: read globals BuyMerchantItem C_Item C_MerchantFrame ChatFrameUtil GetMerchantItemLink GetMerchantItemMaxStack GetMoney IsModifiedClick MerchantFrame StackSplitFrame
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Buy full stack with Shift",
		DESC = "Shift-click on a merchant item buys a full stack (as much as you can afford) instead of opening the quantity dialog. Items costing currencies or other items keep the dialog.",
	},
	deDE = {
		TITLE = "Vollen Stapel mit Shift kaufen",
		DESC = "Shift-Klick auf eine Händlerware kauft einen vollen Stapel (so viel du dir leisten kannst), statt den Mengendialog zu öffnen. Waren, die Währungen oder Gegenstände kosten, behalten den Dialog.",
	},
})

local module = ns:NewModule("BuyFullStack", {
	title = L.TITLE,
	description = L.DESC,
	category = "MERCHANT",
})

function module:OnEnable()
	self:SecureHook("MerchantItemButton_OnModifiedClick", self.OnModifiedClick)
end

local function GetAmount(index)
	local info = C_MerchantFrame.GetItemInfo(index)
	if not info or info.hasExtendedCost then
		return nil
	end
	local link = GetMerchantItemLink(index)
	local stackSize = link and C_Item.GetItemMaxStackSize(link) or 1
	if stackSize <= 1 then
		return nil
	end
	local bundle = math.max(info.stackCount or 1, 1)
	local amount = math.min(stackSize, GetMerchantItemMaxStack(index))
	if info.price and info.price > 0 then
		amount = math.min(amount, math.floor(GetMoney() / (info.price / bundle)))
	end
	-- Merchants sell in bundles of `bundle` items.
	amount = amount - amount % bundle
	return amount > 0 and amount or nil
end

-- Post-hook: Blizzard has opened the quantity dialog for SPLITSTACK clicks by now.
function module:OnModifiedClick(button)
	if MerchantFrame.selectedTab ~= 1 or not IsModifiedClick("SPLITSTACK") then
		return
	end
	-- Shift-click with an open chat box inserts the item link instead.
	if ChatFrameUtil.GetActiveWindow() then
		return
	end
	local index = button:GetID()
	local amount = GetAmount(index)
	if not amount then
		return
	end
	StackSplitFrame:Hide()
	BuyMerchantItem(index, amount)
end
