local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Guild recruitment tab",
		NOTE = "Moves guild ads to a {Guilds} tab",
		DESC = "Channel, say and yell messages containing one of your keywords (guild ads, recruitment) are shown only in a separate {Guilds} chat tab instead of your other tabs. Nothing is deleted. Without the tab nothing is moved.",
		TAB = "Guilds",
		KEYWORDS = "Keywords",
		KEYWORDS_DESC = "Separated by commas, case-insensitive, matched anywhere in the message. Saved with Enter.\n\nDefault: %s",
		KEYWORDS_HINT = "Words, separated by commas",
		CREATE_TAB = "Guilds tab",
		CREATE_TAB_DESC = "Creates the {Guilds} chat tab if it doesn't exist. Enabling the module also creates it.",
		CREATE = "Create",
		TAB_CREATED = "Created the {Guilds} chat tab.",
		TAB_EXISTS = "The {Guilds} chat tab already exists.",
		NO_FREE_WINDOW = "No free chat window left to create the {Guilds} tab.",
		TAB_MISSING = "The {Guilds} chat tab is gone, so the guild recruitment tab was disabled. Enable it again to recreate the tab.",
	},
	deDE = {
		TITLE = "Gildenwerbung-Tab",
		NOTE = "Verschiebt Gildenwerbung in einen {Gilden}-Tab",
		DESC = "Kanal-, Sagen- und Schreien-Nachrichten mit einem deiner Stichwörter (Gildenwerbung, Rekrutierung) erscheinen nur in einem eigenen Chat-Tab {Gilden} statt in deinen anderen Tabs. Es wird nichts gelöscht. Ohne den Tab wird nichts verschoben.",
		TAB = "Gilden",
		KEYWORDS = "Stichwörter",
		KEYWORDS_DESC = "Durch Kommas getrennt, ohne Groß-/Kleinschreibung, irgendwo in der Nachricht. Wird mit Enter gespeichert.\n\nStandard: %s",
		KEYWORDS_HINT = "Wörter, durch Kommas getrennt",
		CREATE_TAB = "Gilden-Tab",
		CREATE_TAB_DESC = "Erstellt den Chat-Tab {Gilden}, falls er fehlt. Auch das Aktivieren des Moduls erstellt ihn.",
		CREATE = "Erstellen",
		TAB_CREATED = "Chat-Tab {Gilden} erstellt.",
		TAB_EXISTS = "Der Chat-Tab {Gilden} existiert bereits.",
		NO_FREE_WINDOW = "Kein freies Chatfenster mehr für den Tab {Gilden}.",
		TAB_MISSING = "Der Chat-Tab {Gilden} fehlt, daher wurde der Gildenwerbung-Tab deaktiviert. Aktiviere ihn erneut, um den Tab wieder zu erstellen.",
	},
})

local DEFAULT_KEYWORDS = "recruit, guild, gilde, rekrut"

local module = ns:NewModule("GuildRecruitTab", {
	title = L.TITLE,
	description = L.DESC,
	note = L.NOTE,
	category = "CHAT",
	order = 90,
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

-- The spam filter's tab keeps its own messages; dropping matches there too
-- would hide a message that is both spam and a guild ad everywhere.
ns.Chat.NewTabFilter(module, { L = L, keepOtherTabs = true })
