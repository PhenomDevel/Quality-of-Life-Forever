-- luacheck: read globals BACKPACK_CONTAINER NUM_BAG_SLOTS NUM_TOTAL_EQUIPPED_BAG_SLOTS C_Container C_Item GetItemInfo
local _, ns = ...

local Utils = ns.Utils

local L = ns.NewLocale({
	enUS = {
		TITLE = "Auto-sell junk",
		DESC = "Automatically sell all poor quality (grey) items when visiting a merchant.",
		SUMMARY = "Show summary",
		SUMMARY_DESC = "Print the number of sold items and the earned gold.",
		SOLD = "Sold %d junk item(s) for %s.",
	},
	deDE = {
		TITLE = "Plunder automatisch verkaufen",
		DESC = "Verkauft beim Besuch eines Händlers automatisch alle Gegenstände schlechter Qualität (grau).",
		SUMMARY = "Zusammenfassung anzeigen",
		SUMMARY_DESC = "Gibt die Anzahl der verkauften Gegenstände und das erhaltene Gold aus.",
		SOLD = "%d Plundergegenstände für %s verkauft.",
	},
})

local module = ns:NewModule("AutoSellJunk", {
	title = L.TITLE,
	description = L.DESC,
	category = "MERCHANT",
	defaultEnabled = true,
	defaults = {
		showSummary = true,
	},
	options = {
		{
			key = "showSummary",
			type = "checkbox",
			label = L.SUMMARY,
			tooltip = L.SUMMARY_DESC,
		},
	},
})

-- Selling everything in one frame can get throttled by the server, so items
-- are sold in small batches.
local ITEMS_PER_BATCH = 10
local BATCH_INTERVAL = 0.2

local POOR_QUALITY = Enum and Enum.ItemQuality and Enum.ItemQuality.Poor or 0

local GetItemInfo = (C_Item and C_Item.GetItemInfo) or GetItemInfo

local function GetLastBagIndex()
	return NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS
end

local function CollectJunk()
	local junk = {}
	for bag = BACKPACK_CONTAINER, GetLastBagIndex() do
		for slot = 1, C_Container.GetContainerNumSlots(bag) do
			local info = C_Container.GetContainerItemInfo(bag, slot)
			if info and info.quality == POOR_QUALITY and not info.hasNoValue and not info.isLocked then
				local sellPrice = select(11, GetItemInfo(info.itemID))
				if sellPrice and sellPrice > 0 then
					junk[#junk + 1] = {
						bag = bag,
						slot = slot,
						itemID = info.itemID,
						value = sellPrice * (info.stackCount or 1),
					}
				end
			end
		end
	end
	return junk
end

function module:OnEnable()
	self:RegisterEvent("MERCHANT_SHOW")
	self:RegisterEvent("MERCHANT_CLOSED")
end

function module:OnDisable()
	self:StopSelling()
end

function module:StopSelling()
	if self.ticker then
		self.ticker:Cancel()
		self.ticker = nil
	end
end

function module:PrintSummary(count, value)
	if count > 0 and self.db.showSummary then
		self:Print(L.SOLD:format(count, Utils.FormatMoney(value)))
	end
end

function module:MERCHANT_SHOW()
	self:StopSelling()

	local junk = CollectJunk()
	if #junk == 0 then
		return
	end

	local index, soldCount, soldValue = 1, 0, 0
	local function SellBatch()
		for _ = 1, ITEMS_PER_BATCH do
			local item = junk[index]
			if not item then
				self:StopSelling()
				self:PrintSummary(soldCount, soldValue)
				return
			end
			index = index + 1
			-- Make sure the slot still holds the same item.
			local info = C_Container.GetContainerItemInfo(item.bag, item.slot)
			if info and info.itemID == item.itemID and not info.isLocked then
				C_Container.UseContainerItem(item.bag, item.slot)
				soldCount = soldCount + 1
				soldValue = soldValue + item.value
			end
		end
	end

	self.ticker = C_Timer.NewTicker(BATCH_INTERVAL, SellBatch)
	SellBatch()
end

function module:MERCHANT_CLOSED()
	self:StopSelling()
end
