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
L.CATEGORY_INTERFACE = "Interface & Misc"
L.CATEGORY_ACTION_BARS = "Action bars"
L.CATEGORY_BAGS = "Bags & items"
L.CATEGORY_COOLDOWN_MANAGER = "Cooldown Manager"
L.CATEGORY_MERCHANT = "Merchant & trainer"
L.CATEGORY_LOOT = "Loot"
L.CATEGORY_SOCIAL = "Social"
L.CATEGORY_QUESTS = "Quests"
L.CATEGORY_CHAT = "Chat"
L.CATEGORY_MAP = "World map"
L.CATEGORY_CHARACTER = "Character"
L.CATEGORY_TOOLTIP = "Tooltip"
L.CATEGORY_GRAPHICS = "Camera & graphics"
L.CATEGORY_REMINDERS = "Reminders"
L.CATEGORY_WIDGETS = "Widgets"

-- Options window
L.SETTINGS_GENERAL_HEADER = "General"
L.SETTINGS_ENABLE_FOR_OPTIONS = "More options appear when enabled."
L.SETTINGS_UNLOAD_ON_RELOAD = "Off. Fully unloaded after the next |cffffd100/reload|r."
L.SETTING_PRINT_MESSAGES = "Show chat messages"
L.SETTING_PRINT_MESSAGES_DESC = "Shows feedback from modules in the chat frame (e.g. repair costs, sold junk)."
L.SETTING_MINIMAP_BUTTON = "Minimap button"
L.SETTING_MINIMAP_BUTTON_DESC = "Shows the addon button at the minimap. Drag it to move it around the minimap. The entry in the addon menu next to the minimap stays either way."
L.SETTING_DEBUG = "Debug mode"
L.SETTING_DEBUG_DESC = "Prints additional diagnostic messages. Only useful for development."
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
L.OPTIONS_PREVIEW = "Preview"
L.OPTIONS_PREVIEW_DESC = "While this window is open, shows all widgets and reminders with sample content, so you can see and drag them. Turn it off to see your interface as it is."

-- Blizzard settings page (Options > AddOns)
L.SETTINGS_PAGE_TEXT = "The options have their own window. You can also open it with |cffffd100/qol|r or the addon menu at the minimap."
L.SETTINGS_PAGE_BUTTON = "Open options"
L.RELOAD_REQUIRED = "%s requires a UI reload to fully apply this change. Reload now?"
L.RELOAD_TO_UNLOAD = "%s is off. Reload the interface now to unload it completely? Until then it stays muted."
L.COMBAT_QUEUED = "%s will be updated after combat."

-- XP session
L.XP_UNDER_A_MINUTE = "< 1 Min"
L.SESSION_RESET = "New session"
L.SESSION_RESET_DESC = "When counting starts over. On login: every login, a /reload continues. Daily: after the daily server reset, across logins. Manually: only with {Reset}. Daily and manual count online time only."
L.SESSION_RESET_LOGIN = "On login"
L.SESSION_RESET_DAILY = "Daily"
L.SESSION_RESET_MANUAL = "Manually"

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
L.MINIMAP_HINT_EDIT_MODE = "|cffffd100Right-click|r for Edit Mode to move widgets."
L.MINIMAP_HINT_DRAG = "|cffffd100Drag|r to move the button."

-- Overlays
L.OVERLAY_SCALE = "Scale"
L.EDIT_MODE_COMBAT = "Edit Mode is not available in combat."

-- Reminders (notices)
L.SETTING_NOTICES = "Reminder popups"
L.SETTING_NOTICES_DESC = "Shows reminders (e.g. new trainer skills, unspent talent points) as small popups instead of in the chat. They only appear out of combat; move them in {Edit Mode}. Click a popup to close it."
L.NOTICES_TEST = "Test popup"
L.NOTICES_TEST_DESC = "Shows a sample popup, e.g. to check its position."
L.NOTICES_TEST_BUTTON = "Show"
L.NOTICES_EDIT_MODE_NAME = "QoL Forever: Reminders"
L.NOTICES_TEST_TITLE = "Quality of Life Forever"
L.NOTICES_TEST_TEXT = "Reminders appear here. Move them in {Edit Mode}; click to close."
L.NOTICES_PREVIEW_TEXT = "Reminders appear here. Drag this frame to move them."

-- Widget stack
L.SETTING_STACK_WIDGETS = "Combine widgets"
L.SETTING_STACK_WIDGETS_DESC = "Stacks all shown widgets (XP, reputation, gold, …) on top of each other in one column. Drag any of them, or move \"QoL Forever: Widgets\" in {Edit Mode}, to move the whole stack. Turned off, every widget goes back to its own position."
L.SETTING_STACK_WIDGETS_NOTE = "All widgets in one column, moved together"
L.WIDGET_STACK_EDIT_MODE_NAME = "QoL Forever: Widgets"
L.SHOW_TITLE = "Always show title"
L.SHOW_TITLE_DESC = "Shows the name above the frame also while this window and {Edit Mode} are closed. While one of them is open, every frame shows its name."
L.TEXT_OUTLINE = "Text outline"
L.TEXT_OUTLINE_DESC = "Draws an outline around the widget's text, so it stays readable on a transparent background."
L.TEXT_OUTLINE_NONE = "None"
L.TEXT_OUTLINE_THIN = "Thin"
L.TEXT_OUTLINE_THICK = "Thick"
L.TEXT_SHADOW = "Text shadow"
L.TEXT_SHADOW_DESC = "Draws a small shadow below the widget's text."

-- What's new
L.SETTING_WHATS_NEW = "What's new after updates"
L.SETTING_WHATS_NEW_DESC = "After an update to a new version (e.g. 0.11 → 0.12, not for small fixes), shows a window with the most important changes once."
L.WHATS_NEW_SHOW = "What's new"
L.WHATS_NEW_SHOW_DESC = "Shows the changes of the current version. Also: |cffffd100/qol news|r"
L.WHATS_NEW_TITLE = "What's new"
L.WHATS_NEW_VERSION = "Version %s"
L.WHATS_NEW_HINT = "Turn this window off in the options under General."
L.SLASH_HELP_NEWS = "|cffffd100/qol news|r - show what's new in this version"
