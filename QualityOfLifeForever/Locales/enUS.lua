local _, ns = ...

-- enUS is the base locale. Every key must exist here; other locales only
-- override what they translate. Missing keys fall back to the key itself so a
-- typo shows up visibly in-game instead of raising an error.
local L = setmetatable({}, {
	__index = function(_, key)
		return key
	end,
})
ns.L = L

-- General
L.ADDON_LOADED = "Version %s loaded. Type |cffffd100/qol|r for options."
L.UNKNOWN_VERSION = "dev"

-- Categories
L.CATEGORY_GENERAL = "General"
L.CATEGORY_INTERFACE = "Interface"
L.CATEGORY_MERCHANT = "Merchant"
L.CATEGORY_LOOT = "Loot"
L.CATEGORY_SOCIAL = "Social"
L.CATEGORY_QUESTS = "Quests"
L.CATEGORY_CHAT = "Chat"
L.CATEGORY_MAP = "Map & Minimap"

-- Settings panel
L.SETTINGS_GENERAL_HEADER = "General"
L.SETTINGS_MODULE_OPTIONS = "Options"
L.SETTING_PRINT_MESSAGES = "Show chat messages"
L.SETTING_PRINT_MESSAGES_DESC = "Show feedback from modules in the chat frame (e.g. repair costs, sold junk)."
L.SETTING_DEBUG = "Debug mode"
L.SETTING_DEBUG_DESC = "Print additional diagnostic messages. Only useful for development."
L.SETTINGS_UNAVAILABLE = "The settings panel is not available on this client. Use |cffffd100/qol help|r instead."
L.RELOAD_REQUIRED = "%s requires a UI reload to fully apply this change. Reload now?"
L.COMBAT_QUEUED = "%s will be updated after combat."

-- Slash commands
L.SLASH_HELP_HEADER = "Commands:"
L.SLASH_HELP_CONFIG = "|cffffd100/qol|r - open the options"
L.SLASH_HELP_LIST = "|cffffd100/qol list|r - list all modules"
L.SLASH_HELP_ENABLE = "|cffffd100/qol enable <module>|r - enable a module"
L.SLASH_HELP_DISABLE = "|cffffd100/qol disable <module>|r - disable a module"
L.SLASH_HELP_TOGGLE = "|cffffd100/qol toggle <module>|r - toggle a module"
L.SLASH_HELP_DEBUG = "|cffffd100/qol debug|r - toggle debug mode"
L.SLASH_HELP_RESET = "|cffffd100/qol reset|r - reset all settings"
L.MODULE_LIST_HEADER = "Modules:"
L.MODULE_ENABLED = "%s |cff00ff00enabled|r."
L.MODULE_DISABLED = "%s |cffff0000disabled|r."
L.MODULE_NOT_FOUND = "Unknown module: %s"
L.MODULE_STATE_ON = "|cff00ff00on|r"
L.MODULE_STATE_OFF = "|cffff0000off|r"
L.DEBUG_ON = "Debug mode |cff00ff00enabled|r."
L.DEBUG_OFF = "Debug mode |cffff0000disabled|r."
L.RESET_CONFIRM = "Reset all Quality of Life Forever settings and reload the UI?"

-- Addon compartment
L.COMPARTMENT_HINT = "|cffffd100Click|r to open the options."

-- Module: AutoRepair
L.AUTO_REPAIR_TITLE = "Auto repair"
L.AUTO_REPAIR_DESC = "Automatically repair all items when visiting a merchant that can repair."
L.AUTO_REPAIR_USE_GUILD = "Use guild funds"
L.AUTO_REPAIR_USE_GUILD_DESC = "Try to pay with guild bank funds first and fall back to your own gold."
L.AUTO_REPAIR_DONE = "Repaired all items for %s."
L.AUTO_REPAIR_DONE_GUILD = "Repaired all items for %s (guild funds)."
L.AUTO_REPAIR_NO_MONEY = "Not enough gold to repair (%s needed)."

-- Module: AutoSellJunk
L.AUTO_SELL_JUNK_TITLE = "Auto sell junk"
L.AUTO_SELL_JUNK_DESC = "Automatically sell all poor quality (grey) items when visiting a merchant."
L.AUTO_SELL_JUNK_SUMMARY = "Show summary"
L.AUTO_SELL_JUNK_SUMMARY_DESC = "Print the number of sold items and the earned gold."
L.AUTO_SELL_JUNK_SOLD = "Sold %d junk item(s) for %s."

-- Module: FastLoot
L.FAST_LOOT_TITLE = "Fast loot"
L.FAST_LOOT_DESC = "Loot all items instantly when auto loot is active instead of waiting for the loot window."

-- Module: AutoDeclineDuels
L.AUTO_DECLINE_DUELS_TITLE = "Auto decline duels"
L.AUTO_DECLINE_DUELS_DESC = "Automatically decline all duel requests."
L.AUTO_DECLINE_DUELS_NOTIFY = "Notify in chat"
L.AUTO_DECLINE_DUELS_NOTIFY_DESC = "Print a message when a duel request was declined."
L.AUTO_DECLINE_DUELS_DECLINED = "Declined duel request from %s."
