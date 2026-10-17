-- luacheck: read globals CanGuildBankRepair CanMerchantRepair GetGuildBankWithdrawMoney GetMoney GetRepairAllCost IsInGuild RepairAllItems
local _, ns = ...

local Utils = ns.Utils

local L = ns.NewLocale({
	enUS = {
		TITLE = "Auto-repair",
		DESC = "Automatically repair all items when visiting a merchant that can repair.",
		USE_GUILD = "Use guild funds",
		USE_GUILD_DESC = "Try to pay with guild bank funds first and fall back to your own gold.",
		DONE = "Repaired all items for %s.",
		DONE_GUILD = "Repaired all items for %s (guild funds).",
		NO_MONEY = "Not enough gold to repair (%s needed).",
	},
	deDE = {
		TITLE = "Automatisch reparieren",
		DESC = "Repariert automatisch alle Gegenstände beim Besuch eines Händlers, der reparieren kann.",
		USE_GUILD = "Gildengold verwenden",
		USE_GUILD_DESC = "Versucht zuerst mit Gildenbankgold zu bezahlen und nutzt sonst dein eigenes Gold.",
		DONE = "Alle Gegenstände für %s repariert.",
		DONE_GUILD = "Alle Gegenstände für %s repariert (Gildengold).",
		NO_MONEY = "Nicht genug Gold zum Reparieren (%s benötigt).",
	},
})

local module = ns:NewModule("AutoRepair", {
	title = L.TITLE,
	description = L.DESC,
	category = "MERCHANT",
	defaultEnabled = true,
	defaults = {
		useGuildFunds = true,
	},
	options = {
		{
			key = "useGuildFunds",
			type = "checkbox",
			label = L.USE_GUILD,
			tooltip = L.USE_GUILD_DESC,
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
		self:Print(L.NO_MONEY:format(Utils.FormatMoney(cost)))
		return
	end
	RepairAllItems(false)
	self:Print(L.DONE:format(Utils.FormatMoney(cost)))
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
				self:Print(L.DONE_GUILD:format(Utils.FormatMoney(cost)))
			end
		end)
		return
	end

	self:RepairWithOwnMoney(cost)
end
