local _, ns = ...

local L = ns.L
local Utils = ns.Utils

local module = ns:NewModule("AutoRepair", {
	title = L.AUTO_REPAIR_TITLE,
	description = L.AUTO_REPAIR_DESC,
	category = "MERCHANT",
	defaultEnabled = true,
	defaults = {
		useGuildFunds = true,
	},
	options = {
		{
			key = "useGuildFunds",
			type = "checkbox",
			label = L.AUTO_REPAIR_USE_GUILD,
			tooltip = L.AUTO_REPAIR_USE_GUILD_DESC,
		},
	},
})

-- Delay before checking whether a guild repair actually went through.
local GUILD_REPAIR_CHECK_DELAY = 0.5

function module:OnEnable()
	self:RegisterEvent("MERCHANT_SHOW")
end

local function CanUseGuildFunds(cost)
	if not (IsInGuild() and CanGuildBankRepair and CanGuildBankRepair()) then
		return false
	end
	local withdrawLimit = GetGuildBankWithdrawMoney()
	-- -1 means unlimited (guild master).
	return withdrawLimit == -1 or withdrawLimit >= cost
end

function module:RepairWithOwnMoney(cost)
	if GetMoney() < cost then
		self:Print(L.AUTO_REPAIR_NO_MONEY:format(Utils.FormatMoney(cost)))
		return
	end
	RepairAllItems(false)
	self:Print(L.AUTO_REPAIR_DONE:format(Utils.FormatMoney(cost)))
end

function module:MERCHANT_SHOW()
	if not CanMerchantRepair() then
		return
	end
	local cost, canRepair = GetRepairAllCost()
	if not canRepair or cost <= 0 then
		return
	end

	if self.db.useGuildFunds and CanUseGuildFunds(cost) then
		RepairAllItems(true)
		-- The guild bank may not have enough gold, which we only learn afterwards.
		C_Timer.After(GUILD_REPAIR_CHECK_DELAY, function()
			if not self.enabled then
				return
			end
			local remaining = GetRepairAllCost()
			if remaining and remaining > 0 then
				self:RepairWithOwnMoney(remaining)
			else
				self:Print(L.AUTO_REPAIR_DONE_GUILD:format(Utils.FormatMoney(cost)))
			end
		end)
		return
	end

	self:RepairWithOwnMoney(cost)
end
