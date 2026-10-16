std = "lua51"
max_line_length = false
codes = true
exclude_files = {
	".release/",
}

-- Ignore unused `self` and unused arguments starting with an underscore.
self = false
unused_args = true
ignore = { "212/_.*" }

files["tests/"] = {
	std = "max",
	globals = { "setfenv" },
}

-- Globals the addon defines.
globals = {
	"QualityOfLifeForever",
	"QualityOfLifeForeverDB",
	"QualityOfLifeForever_OnAddonCompartmentClick",
	"QualityOfLifeForever_OnAddonCompartmentEnter",
	"QualityOfLifeForever_OnAddonCompartmentLeave",
	"SLASH_QOLFOREVER1",
	"SLASH_QOLFOREVER2",
	"SlashCmdList",
	"StaticPopupDialogs",
}

-- WoW API used by the addon. Add new entries when a module needs them.
read_globals = {
	-- Lua extensions provided by the client
	"wipe",
	"geterrorhandler",
	"hooksecurefunc",
	"issecretvalue",

	-- Frames & UI
	"CreateFrame",
	"DEFAULT_CHAT_FRAME",
	"GameTooltip",
	"UIParent",
	"StaticPopup_Show",
	"StaticPopup_Hide",
	"ACCEPT",
	"CANCEL",

	-- Settings
	"Settings",
	"CreateSettingsListSectionHeaderInitializer",
	"MinimalSliderWithSteppersMixin",

	-- C_ namespaces
	"C_AddOns",
	"C_Container",
	"C_CurrencyInfo",
	"C_Item",
	"C_Timer",
	"Enum",

	-- General API
	"GetAddOnMetadata",
	"GetCoinTextureString",
	"GetCVarBool",
	"GetItemInfo",
	"GetLocale",
	"GetTime",
	"InCombatLockdown",
	"IsModifiedClick",
	"ReloadUI",

	-- Bags
	"BACKPACK_CONTAINER",
	"NUM_BAG_SLOTS",
	"NUM_TOTAL_EQUIPPED_BAG_SLOTS",

	-- Merchant & money
	"CanGuildBankRepair",
	"CanMerchantRepair",
	"GetGuildBankWithdrawMoney",
	"GetMoney",
	"GetRepairAllCost",
	"IsInGuild",
	"RepairAllItems",

	-- Loot
	"GetNumLootItems",
	"LootSlot",

	-- Social
	"CancelDuel",
}
