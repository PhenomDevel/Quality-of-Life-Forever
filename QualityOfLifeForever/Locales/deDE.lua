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
L.CATEGORY_MAP = "Karte & Minimap"

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

-- Module: AutoRepair
L.AUTO_REPAIR_TITLE = "Automatisch reparieren"
L.AUTO_REPAIR_DESC = "Repariert automatisch alle Gegenstände beim Besuch eines Händlers, der reparieren kann."
L.AUTO_REPAIR_USE_GUILD = "Gildengold verwenden"
L.AUTO_REPAIR_USE_GUILD_DESC = "Versucht zuerst mit Gildenbankgold zu bezahlen und nutzt sonst dein eigenes Gold."
L.AUTO_REPAIR_DONE = "Alle Gegenstände für %s repariert."
L.AUTO_REPAIR_DONE_GUILD = "Alle Gegenstände für %s repariert (Gildengold)."
L.AUTO_REPAIR_NO_MONEY = "Nicht genug Gold zum Reparieren (%s benötigt)."

-- Module: AutoSellJunk
L.AUTO_SELL_JUNK_TITLE = "Plunder automatisch verkaufen"
L.AUTO_SELL_JUNK_DESC = "Verkauft beim Besuch eines Händlers automatisch alle Gegenstände schlechter Qualität (grau)."
L.AUTO_SELL_JUNK_SUMMARY = "Zusammenfassung anzeigen"
L.AUTO_SELL_JUNK_SUMMARY_DESC = "Gibt die Anzahl der verkauften Gegenstände und das erhaltene Gold aus."
L.AUTO_SELL_JUNK_SOLD = "%d Plundergegenstände für %s verkauft."

-- Module: FastLoot
L.FAST_LOOT_TITLE = "Schnelles Plündern"
L.FAST_LOOT_DESC = "Plündert bei aktivem automatischem Plündern alle Gegenstände sofort, ohne auf das Beutefenster zu warten."

-- Module: AutoDeclineDuels
L.AUTO_DECLINE_DUELS_TITLE = "Duelle automatisch ablehnen"
L.AUTO_DECLINE_DUELS_DESC = "Lehnt alle Duellanfragen automatisch ab."
L.AUTO_DECLINE_DUELS_NOTIFY = "Im Chat benachrichtigen"
L.AUTO_DECLINE_DUELS_NOTIFY_DESC = "Gibt eine Nachricht aus, wenn eine Duellanfrage abgelehnt wurde."
L.AUTO_DECLINE_DUELS_DECLINED = "Duellanfrage von %s abgelehnt."
