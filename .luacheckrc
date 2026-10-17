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

-- Globals the addon defines.
globals = {
	"QualityOfLifeForever",
	"QualityOfLifeForeverDB",
	"QualityOfLifeForeverSettingsNoteMixin",
	"QualityOfLifeForeverSettingsDividerMixin",
	"QualityOfLifeForever_OnAddonCompartmentClick",
	"QualityOfLifeForever_OnAddonCompartmentEnter",
	"QualityOfLifeForever_OnAddonCompartmentLeave",
	"SLASH_QOLFOREVER1",
	"SLASH_QOLFOREVER2",
	"SlashCmdList",
	"StaticPopupDialogs",
}

-- WoW API used by the core. Modules declare their own API usage inline:
--   -- luacheck: read globals SomeApiFunction C_Something
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
	"CreateSettingsButtonInitializer",
	"CreateSettingsListSectionHeaderInitializer",
	"MinimalSliderWithSteppersMixin",

	-- General API
	"C_AddOns",
	"C_CurrencyInfo",
	"C_CVar",
	"C_Timer",
	"Enum",
	"ConsoleGetAllCommands",
	"GetAddOnMetadata",
	"GetBuildInfo",
	"GetCoinTextureString",
	"GetLocale",
	"GetTime",
	"InCombatLockdown",
	"ReloadUI",
}
