local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Spam filter",
		NOTE = "Moves matching messages to a {Spam} tab",
		DESC = "Channel, say and yell messages containing one of your keywords are shown only in a separate {Spam} chat tab instead of your other tabs. Nothing is deleted. Without the tab nothing is moved.",
		TAB = "Spam",
		KEYWORDS = "Keywords",
		KEYWORDS_DESC = "Separated by commas, case-insensitive, matched anywhere in the message. Saved with Enter.\n\nDefault: %s",
		KEYWORDS_HINT = "Words, separated by commas",
		CREATE_TAB = "Spam tab",
		CREATE_TAB_DESC = "Creates the {Spam} chat tab if it doesn't exist. Enabling the module also creates it.",
		CREATE = "Create",
		TAB_CREATED = "Created the {Spam} chat tab.",
		TAB_EXISTS = "The {Spam} chat tab already exists.",
		NO_FREE_WINDOW = "No free chat window left to create the {Spam} tab.",
		TAB_MISSING = "The {Spam} chat tab is gone, so the spam filter was disabled. Enable it again to recreate the tab.",
	},
	deDE = {
		TITLE = "Spamfilter",
		NOTE = "Verschiebt Treffer in einen {Spam}-Tab",
		DESC = "Kanal-, Sagen- und Schreien-Nachrichten mit einem deiner Stichwörter erscheinen nur in einem eigenen Chat-Tab {Spam} statt in deinen anderen Tabs. Es wird nichts gelöscht. Ohne den Tab wird nichts verschoben.",
		TAB = "Spam",
		KEYWORDS = "Stichwörter",
		KEYWORDS_DESC = "Durch Kommas getrennt, ohne Groß-/Kleinschreibung, irgendwo in der Nachricht. Wird mit Enter gespeichert.\n\nStandard: %s",
		KEYWORDS_HINT = "Wörter, durch Kommas getrennt",
		CREATE_TAB = "Spam-Tab",
		CREATE_TAB_DESC = "Erstellt den Chat-Tab {Spam}, falls er fehlt. Auch das Aktivieren des Moduls erstellt ihn.",
		CREATE = "Erstellen",
		TAB_CREATED = "Chat-Tab {Spam} erstellt.",
		TAB_EXISTS = "Der Chat-Tab {Spam} existiert bereits.",
		NO_FREE_WINDOW = "Kein freies Chatfenster mehr für den Tab {Spam}.",
		TAB_MISSING = "Der Chat-Tab {Spam} fehlt, daher wurde der Spamfilter deaktiviert. Aktiviere ihn erneut, um den Tab wieder zu erstellen.",
	},
})

local DEFAULT_KEYWORDS = "boost, goldselling, carry"

local module = ns:NewModule("SpamFilter", {
	title = L.TITLE,
	description = L.DESC,
	note = L.NOTE,
	category = "CHAT",
	order = 50,
	defaults = {
		keywords = DEFAULT_KEYWORDS,
		tabCreated = false,
	},
	options = {
		{
			key = "keywords",
			type = "text",
			multiline = true,
			label = L.KEYWORDS,
			tooltip = L.KEYWORDS_DESC:format(DEFAULT_KEYWORDS),
			placeholder = L.KEYWORDS_HINT,
			maxLetters = 1000,
		},
		{
			type = "button",
			label = L.CREATE_TAB,
			buttonText = L.CREATE,
			tooltip = L.CREATE_TAB_DESC,
			onClick = function(self)
				self:CreateTabButton()
			end,
		},
	},
})

-- Matches are dropped from every other tab, including the guild tab.
ns.Chat.NewTabFilter(module, { L = L })
