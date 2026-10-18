-- luacheck: read globals CanGuildBankRepair CanMerchantRepair GetGuildBankWithdrawMoney GetMoney GetRepairAllCost IsInGuild RepairAllItems
local _, ns = ...

local Utils = ns.Utils

local L = ns.NewLocale({
	enUS = {
		TITLE = "Auto-repair",
		DESC = "Repairs all items automatically when you open a merchant that can repair.",
		NOTICE = "On by default. Spends gold at every repair merchant without asking.",
		USE_GUILD = "Use guild funds",
		USE_GUILD_DESC = "Pays with guild bank funds first and falls back to your own gold.",
		DONE = "Repaired all items for %s.",
		DONE_GUILD = "Repaired all items for %s (guild funds).",
		NO_MONEY = "Not enough gold to repair (%s needed).",
	},
	deDE = {
		TITLE = "Automatisch reparieren",
		DESC = "Repariert alle Gegenstände automatisch, wenn du einen Händler öffnest, der reparieren kann.",
		NOTICE = "Standardmäßig aktiv. Gibt bei jedem Reparaturhändler ohne Nachfrage Gold aus.",
		USE_GUILD = "Gildengold verwenden",
		USE_GUILD_DESC = "Bezahlt zuerst mit Gildenbankgold und sonst mit deinem eigenen Gold.",
		DONE = "Alle Gegenstände für %s repariert.",
		DONE_GUILD = "Alle Gegenstände für %s repariert (Gildengold).",
		NO_MONEY = "Nicht genug Gold zum Reparieren (%s benötigt).",
	},
})

local module = ns:NewModule("AutoRepair", {
	title = L.TITLE,
	description = L.DESC,
	notice = L.NOTICE,
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
