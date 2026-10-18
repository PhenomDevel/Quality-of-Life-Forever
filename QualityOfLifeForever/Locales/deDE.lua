local _, ns = ...

if GetLocale() ~= "deDE" then
	return
end

local L = ns.L

-- General
L.ADDON_LOADED = "Version %s geladen. Gib |cffffd100/qol|r für die Optionen ein."

-- Categories
L.CATEGORY_INTERFACE = "Oberfläche"
L.CATEGORY_BAGS = "Taschen & Gegenstände"
L.CATEGORY_COOLDOWN_MANAGER = "Cooldown Manager"
L.CATEGORY_MERCHANT = "Händler & Lehrer"
L.CATEGORY_LOOT = "Beute"
L.CATEGORY_SOCIAL = "Soziales"
L.CATEGORY_QUESTS = "Quests"
L.CATEGORY_CHAT = "Chat"
L.CATEGORY_MAP = "Weltkarte"
L.CATEGORY_CHARACTER = "Charakter"
L.CATEGORY_TOOLTIP = "Tooltip"
L.CATEGORY_GRAPHICS = "Kamera & Grafik"
L.CATEGORY_REMINDERS = "Erinnerungen"
L.CATEGORY_WIDGETS = "Widgets"

-- Options window
L.SETTINGS_GENERAL_HEADER = "Allgemein"
L.SETTINGS_ENABLE_FOR_OPTIONS = "Weitere Optionen erscheinen nach dem Aktivieren."
L.SETTING_PRINT_MESSAGES = "Chatnachrichten anzeigen"
L.SETTING_PRINT_MESSAGES_DESC = "Zeigt Rückmeldungen der Module im Chatfenster an (z. B. Reparaturkosten, verkaufter Plunder)."
L.SETTING_MINIMAP_BUTTON = "Minimap-Button"
L.SETTING_MINIMAP_BUTTON_DESC = "Zeigt den Addon-Button an der Minimap. Ziehen verschiebt ihn um die Minimap. Der Eintrag im Addon-Menü neben der Minimap bleibt in jedem Fall."
L.SETTING_DEBUG = "Debug-Modus"
L.SETTING_DEBUG_DESC = "Gibt zusätzliche Diagnosemeldungen aus. Nur für die Entwicklung sinnvoll."
L.OPTIONS_VERSION = "Version %s"
L.OPTIONS_ENABLED_COUNT = "%d von %d aktiviert"
L.OPTIONS_BYLINE = "by Phenom"
L.OPTIONS_SEARCH = "Suchen"
L.OPTIONS_SEARCH_RESULTS = "Suchergebnisse"
L.OPTIONS_RESULT_COUNT = "%d gefunden"
L.OPTIONS_NO_RESULTS = "Nichts passt zu „%s“."
L.OPTIONS_RESET = "Alle Einstellungen zurücksetzen"
L.OPTIONS_RESET_DESC = "Setzt alle Funktionen auf ihren Standard zurück und lädt die Oberfläche neu."
L.OPTIONS_RESET_BUTTON = "Zurücksetzen"

-- Blizzard-Einstellungsseite (Optionen > AddOns)
L.SETTINGS_PAGE_TEXT = "Die Optionen haben ein eigenes Fenster. Du öffnest es auch mit |cffffd100/qol|r oder über das Addon-Menü an der Minimap."
L.SETTINGS_PAGE_BUTTON = "Optionen öffnen"
L.RELOAD_REQUIRED = "%s benötigt ein Neuladen der Oberfläche, damit die Änderung vollständig greift. Jetzt neu laden?"
L.COMBAT_QUEUED = "%s wird nach dem Kampf aktualisiert."

-- XP session
L.XP_UNDER_A_MINUTE = "< 1 Min."
L.SESSION_RESET = "Neue Sitzung"
L.SESSION_RESET_DESC = "Wann neu gezählt wird. Beim Einloggen: bei jedem Login, ein /reload zählt weiter. Täglich: nach dem täglichen Server-Reset, über Logins hinweg. Manuell: nur mit {Zurücksetzen}. Täglich und manuell zählen nur die Online-Zeit."
L.SESSION_RESET_LOGIN = "Beim Einloggen"
L.SESSION_RESET_DAILY = "Täglich"
L.SESSION_RESET_MANUAL = "Manuell"

-- Slash commands
L.SLASH_HELP_HEADER = "Befehle:"
L.SLASH_HELP_CONFIG = "|cffffd100/qol|r - Optionen öffnen"
L.SLASH_HELP_LIST = "|cffffd100/qol list|r - alle Module auflisten"
L.SLASH_HELP_ENABLE = "|cffffd100/qol enable <Modul>|r - Modul aktivieren"
L.SLASH_HELP_DISABLE = "|cffffd100/qol disable <Modul>|r - Modul deaktivieren"
L.SLASH_HELP_TOGGLE = "|cffffd100/qol toggle <Modul>|r - Modul umschalten"
L.SLASH_HELP_MINIMAP = "|cffffd100/qol minimap|r - Minimap-Button ein-/ausblenden"
L.SLASH_HELP_DEBUG = "|cffffd100/qol debug|r - Debug-Modus umschalten"
L.SLASH_HELP_RESET = "|cffffd100/qol reset|r - alle Einstellungen zurücksetzen"
L.SLASH_HELP_CVARINFO = "|cffffd100/qol cvarinfo <CVar> [...]|r - Hilfe, Standardwert und Wertebereich von CVars anzeigen"
L.CVARINFO_LINE = "%s: Wert %s, Standard %s, Min %s, Max %s - %s"
L.CVARINFO_MISSING = "Unbekannter CVar: %s"
L.CVARINFO_SAVED = "In QualityOfLifeForeverDB.global.cvarInfo gespeichert (wird bei /reload oder Logout geschrieben)."
L.MODULE_LIST_HEADER = "Module:"
L.MODULE_ENABLED = "%s |cff00ff00aktiviert|r."
L.MODULE_DISABLED = "%s |cffff0000deaktiviert|r."
L.MODULE_NOT_FOUND = "Unbekanntes Modul: %s"
L.MODULE_STATE_ON = "|cff00ff00an|r"
L.MODULE_STATE_OFF = "|cffff0000aus|r"
L.MINIMAP_SHOWN = "Minimap-Button eingeblendet."
L.MINIMAP_HIDDEN = "Minimap-Button ausgeblendet. |cffffd100/qol minimap|r blendet ihn wieder ein."
L.DEBUG_ON = "Debug-Modus |cff00ff00aktiviert|r."
L.DEBUG_OFF = "Debug-Modus |cffff0000deaktiviert|r."
L.RESET_CONFIRM = "Alle Einstellungen von Quality of Life Forever zurücksetzen und die Oberfläche neu laden?"

-- Addon compartment
L.COMPARTMENT_HINT = "|cffffd100Klicken|r, um die Optionen zu öffnen."

-- Minimap button
L.MINIMAP_HINT_OPTIONS = "|cffffd100Klicken|r, um die Optionen zu öffnen."
L.MINIMAP_HINT_EDIT_MODE = "|cffffd100Rechtsklick|r öffnet den Bearbeitungsmodus, um Widgets zu verschieben."
L.MINIMAP_HINT_DRAG = "|cffffd100Ziehen|r, um den Button zu verschieben."

-- Overlays
L.OVERLAY_SCALE = "Skalierung"
L.EDIT_MODE_COMBAT = "Der Bearbeitungsmodus ist im Kampf nicht verfügbar."

-- Notices
L.SETTING_NOTICES = "Hinweise als Popup"
L.SETTING_NOTICES_DESC = "Zeigt Hinweise und Erinnerungen (z. B. neue Fähigkeiten beim Lehrer, freie Talentpunkte) als kleine Popups statt im Chat. Sie erscheinen nur außerhalb des Kampfes; verschieben im {Bearbeitungsmodus}. Zum Schließen auf das Popup klicken."
L.NOTICES_TEST = "Test-Popup"
L.NOTICES_TEST_DESC = "Zeigt ein Beispiel-Popup, z. B. um seine Position zu prüfen."
L.NOTICES_TEST_BUTTON = "Anzeigen"
L.NOTICES_EDIT_MODE_NAME = "QoL Forever: Hinweise"
L.NOTICES_TEST_TITLE = "Quality of Life Forever"
L.NOTICES_TEST_TEXT = "Hier erscheinen Hinweise und Erinnerungen. Verschieben im {Bearbeitungsmodus}; zum Schließen klicken."

-- Widget stack
L.SETTING_STACK_WIDGETS = "Widgets kombinieren"
L.SETTING_STACK_WIDGETS_DESC = "Stapelt alle angezeigten Widgets (EP, Ruf, Gold, …) in einer Spalte untereinander. Eines davon ziehen oder „QoL Forever: Widgets“ im {Bearbeitungsmodus} verschieben bewegt den ganzen Stapel. Ausgeschaltet kehrt jedes Widget an seine eigene Position zurück."
L.SETTING_STACK_WIDGETS_NOTE = "Alle Widgets in einer Spalte, gemeinsam verschiebbar"
L.WIDGET_STACK_EDIT_MODE_NAME = "QoL Forever: Widgets"
