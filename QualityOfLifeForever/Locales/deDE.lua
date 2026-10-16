local _, ns = ...

if GetLocale() ~= "deDE" then
	return
end

local L = ns.L

-- General
L.ADDON_LOADED = "Version %s geladen. Gib |cffffd100/qol|r für die Optionen ein."

-- Categories
L.CATEGORY_GENERAL = "Allgemein"
L.CATEGORY_INTERFACE = "Oberfläche"
L.CATEGORY_MERCHANT = "Händler"
L.CATEGORY_LOOT = "Beute"
L.CATEGORY_SOCIAL = "Soziales"
L.CATEGORY_QUESTS = "Quests"
L.CATEGORY_CHAT = "Chat"
L.CATEGORY_MAP = "Weltkarte"
L.CATEGORY_EASYSETTINGS = "EasySettings"
L.CATEGORY_CHARACTER = "Charakter"
L.CATEGORY_TOOLTIP = "Tooltip"
L.CATEGORY_CAMERA = "Kamera"
L.CATEGORY_GRAPHICS = "Grafik"

-- Settings panel
L.SETTINGS_GENERAL_HEADER = "Allgemein"
L.SETTINGS_MODULE_OPTIONS = "Optionen"
L.SETTING_PRINT_MESSAGES = "Chatnachrichten anzeigen"
L.SETTING_PRINT_MESSAGES_DESC = "Zeigt Rückmeldungen der Module im Chatfenster an (z. B. Reparaturkosten, verkaufter Plunder)."
L.SETTING_DEBUG = "Debug-Modus"
L.SETTING_DEBUG_DESC = "Gibt zusätzliche Diagnosemeldungen aus. Nur für die Entwicklung sinnvoll."
L.SETTINGS_UNAVAILABLE = "Das Einstellungsfenster ist in diesem Client nicht verfügbar. Nutze stattdessen |cffffd100/qol help|r."
L.RELOAD_REQUIRED = "%s benötigt ein Neuladen der Oberfläche, damit die Änderung vollständig greift. Jetzt neu laden?"
L.COMBAT_QUEUED = "%s wird nach dem Kampf aktualisiert."

-- Slash commands
L.SLASH_HELP_HEADER = "Befehle:"
L.SLASH_HELP_CONFIG = "|cffffd100/qol|r - Optionen öffnen"
L.SLASH_HELP_LIST = "|cffffd100/qol list|r - alle Module auflisten"
L.SLASH_HELP_ENABLE = "|cffffd100/qol enable <Modul>|r - Modul aktivieren"
L.SLASH_HELP_DISABLE = "|cffffd100/qol disable <Modul>|r - Modul deaktivieren"
L.SLASH_HELP_TOGGLE = "|cffffd100/qol toggle <Modul>|r - Modul umschalten"
L.SLASH_HELP_DEBUG = "|cffffd100/qol debug|r - Debug-Modus umschalten"
L.SLASH_HELP_RESET = "|cffffd100/qol reset|r - alle Einstellungen zurücksetzen"
L.MODULE_LIST_HEADER = "Module:"
L.MODULE_ENABLED = "%s |cff00ff00aktiviert|r."
L.MODULE_DISABLED = "%s |cffff0000deaktiviert|r."
L.MODULE_NOT_FOUND = "Unbekanntes Modul: %s"
L.MODULE_STATE_ON = "|cff00ff00an|r"
L.MODULE_STATE_OFF = "|cffff0000aus|r"
L.DEBUG_ON = "Debug-Modus |cff00ff00aktiviert|r."
L.DEBUG_OFF = "Debug-Modus |cffff0000deaktiviert|r."
L.RESET_CONFIRM = "Alle Einstellungen von Quality of Life Forever zurücksetzen und die Oberfläche neu laden?"

-- Addon compartment
L.COMPARTMENT_HINT = "|cffffd100Klicken|r, um die Optionen zu öffnen."
