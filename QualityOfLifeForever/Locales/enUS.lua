local _, ns = ...

-- Core strings only; module strings live in the module file (ns.NewLocale).
-- enUS is the base locale, other locales override what they translate.
-- Missing keys resolve to the key itself, so typos are visible in-game.
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
L.CATEGORY_INTERFACE = "Interface"
L.CATEGORY_COOLDOWN_MANAGER = "Cooldown Manager"
L.CATEGORY_MERCHANT = "Merchant & Trainer"
L.CATEGORY_LOOT = "Loot"
L.CATEGORY_SOCIAL = "Social"
L.CATEGORY_QUESTS = "Quests"
L.CATEGORY_CHAT = "Chat"
L.CATEGORY_MAP = "World map"
L.CATEGORY_CHARACTER = "Character"
L.CATEGORY_STATISTICS = "Statistics"
L.CATEGORY_TOOLTIP = "Tooltip"
L.CATEGORY_CAMERA = "Camera"
L.CATEGORY_GRAPHICS = "Graphics"
L.CATEGORY_XP_BAR = "XP Bar"

-- Options window
L.SETTINGS_GENERAL_HEADER = "General"
L.SETTINGS_ENABLE_FOR_OPTIONS = "More options appear when enabled."
L.SETTING_PRINT_MESSAGES = "Show chat messages"
L.SETTING_PRINT_MESSAGES_DESC = "Show feedback from modules in the chat frame (e.g. repair costs, sold junk)."
L.SETTING_MINIMAP_BUTTON = "Minimap button"
L.SETTING_MINIMAP_BUTTON_DESC = "Shows the addon button at the minimap. Drag it to move it around the minimap. The entry in the addon menu next to the minimap stays either way."
L.SETTING_DEBUG = "Debug mode"
L.SETTING_DEBUG_DESC = "Print additional diagnostic messages. Only useful for development."
L.OPTIONS_VERSION = "Version %s"
L.OPTIONS_ENABLED_COUNT = "%d of %d enabled"
L.OPTIONS_BYLINE = "by Phenom"
L.OPTIONS_SEARCH = "Search"
L.OPTIONS_SEARCH_RESULTS = "Search results"
L.OPTIONS_RESULT_COUNT = "%d found"
L.OPTIONS_NO_RESULTS = "Nothing matches \"%s\"."
L.OPTIONS_RESET = "Reset all settings"
L.OPTIONS_RESET_DESC = "Turns every feature back to its default and reloads the interface."
L.OPTIONS_RESET_BUTTON = "Reset"

-- Blizzard settings page (Options > AddOns)
L.SETTINGS_PAGE_TEXT = "The options have their own window. You can also open it with |cffffd100/qol|r or the addon menu at the minimap."
L.SETTINGS_PAGE_BUTTON = "Open options"
L.RELOAD_REQUIRED = "%s requires a UI reload to fully apply this change. Reload now?"
L.COMBAT_QUEUED = "%s will be updated after combat."

-- Slash commands
L.SLASH_HELP_HEADER = "Commands:"
L.SLASH_HELP_CONFIG = "|cffffd100/qol|r - open the options"
L.SLASH_HELP_LIST = "|cffffd100/qol list|r - list all modules"
L.SLASH_HELP_ENABLE = "|cffffd100/qol enable <module>|r - enable a module"
L.SLASH_HELP_DISABLE = "|cffffd100/qol disable <module>|r - disable a module"
L.SLASH_HELP_TOGGLE = "|cffffd100/qol toggle <module>|r - toggle a module"
L.SLASH_HELP_MINIMAP = "|cffffd100/qol minimap|r - show/hide the minimap button"
L.SLASH_HELP_DEBUG = "|cffffd100/qol debug|r - toggle debug mode"
L.SLASH_HELP_RESET = "|cffffd100/qol reset|r - reset all settings"
L.SLASH_HELP_CVARINFO = "|cffffd100/qol cvarinfo <cvar> [...]|r - show help, default and range of CVars"
L.CVARINFO_LINE = "%s: value %s, default %s, min %s, max %s - %s"
L.CVARINFO_MISSING = "Unknown CVar: %s"
L.CVARINFO_SAVED = "Saved to QualityOfLifeForeverDB.global.cvarInfo (written on /reload or logout)."
L.MODULE_LIST_HEADER = "Modules:"
L.MODULE_ENABLED = "%s |cff00ff00enabled|r."
L.MODULE_DISABLED = "%s |cffff0000disabled|r."
L.MODULE_NOT_FOUND = "Unknown module: %s"
L.MODULE_STATE_ON = "|cff00ff00on|r"
L.MODULE_STATE_OFF = "|cffff0000off|r"
L.MINIMAP_SHOWN = "Minimap button shown."
L.MINIMAP_HIDDEN = "Minimap button hidden. |cffffd100/qol minimap|r shows it again."
L.DEBUG_ON = "Debug mode |cff00ff00enabled|r."
L.DEBUG_OFF = "Debug mode |cffff0000disabled|r."
L.RESET_CONFIRM = "Reset all Quality of Life Forever settings and reload the UI?"

-- Addon compartment
L.COMPARTMENT_HINT = "|cffffd100Click|r to open the options."

-- Minimap button
L.MINIMAP_HINT_OPTIONS = "|cffffd100Click|r to open the options."
L.MINIMAP_HINT_DRAG = "|cffffd100Drag|r to move the button."
