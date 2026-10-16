-- luacheck: read globals TooltipDataProcessor Enum C_Item C_Container SELL_PRICE
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Vendor price in tooltip",
		NOTE = "Sell price of items, also for stacks",
		DESC = "Adds the vendor sell price to item tooltips when the game doesn't show it. For stacks in your bags the price of the whole stack is shown.",
		UNIT = "Price per item",
		UNIT_DESC = "For stacks also show the price of a single item.",
		EACH = "%s each",
	},
	deDE = {
		TITLE = "Verkaufspreis im Tooltip",
		NOTE = "Händlerpreis von Gegenständen, auch für Stapel",
		DESC = "Ergänzt den Verkaufspreis beim Händler in Gegenstands-Tooltips, wenn das Spiel ihn nicht anzeigt. Bei Stapeln in den Taschen wird der Preis des ganzen Stapels angezeigt.",
		UNIT = "Preis pro Stück",
		UNIT_DESC = "Zeigt bei Stapeln zusätzlich den Preis eines einzelnen Gegenstands.",
		EACH = "je %s",
	},
})

local module = ns:NewModule("VendorPrice", {
	title = L.TITLE,
	description = L.DESC,
	note = L.NOTE,
	category = "MERCHANT",
	defaults = {
		unitPrice = true,
	},
	options = {
		{ key = "unitPrice", type = "checkbox", label = L.UNIT, tooltip = L.UNIT_DESC },
	},
})

local IsSecret = ns.Utils.IsSecret
local FormatMoney = ns.Utils.FormatMoney

local function HasSellPriceLine(data)
	for _, line in ipairs(data.lines or {}) do
		if line.type == Enum.TooltipDataLineType.SellPrice then
			return true
		end
	end
	return false
end

-- Stack size of the bag slot the tooltip belongs to, 1 elsewhere.
local function GetStackCount(tooltip)
	local owner = tooltip:GetOwner()
	if owner and type(owner.GetBagID) == "function" then
		local info = C_Container.GetContainerItemInfo(owner:GetBagID(), owner:GetID())
		if info and info.stackCount then
			return info.stackCount
		end
	end
	return 1
end

local function OnTooltipItem(tooltip, data)
	if not module.enabled or tooltip.isShopping or not data or IsSecret(data.id) or not data.id then
		return
	end
	if HasSellPriceLine(data) then
		return
	end
	local sellPrice = select(11, C_Item.GetItemInfo(data.id))
	if not sellPrice or sellPrice <= 0 then
		return
	end
	local count = GetStackCount(tooltip)
	local text = FormatMoney(sellPrice * count)
	if count > 1 and module.db.unitPrice then
		text = text .. " |cff999999(" .. L.EACH:format(FormatMoney(sellPrice)) .. ")|r"
	end
	tooltip:AddLine(("%s: %s"):format(SELL_PRICE, text), 1, 1, 1)
end

function module:OnInitialize()
	-- Post-calls can't be removed: OnTooltipItem checks module.enabled.
	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, OnTooltipItem)
end
