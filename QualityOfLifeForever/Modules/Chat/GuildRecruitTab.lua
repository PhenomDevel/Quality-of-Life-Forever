-- luacheck: read globals ChatFrameUtil GetChatWindowInfo GetChannelList FCF_OpenNewWindow FCFDock_GetSelectedWindow FCFDock_SelectWindow GENERAL_CHAT_DOCK C_Timer
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
local EVENTS = { "CHAT_MSG_CHANNEL", "CHAT_MSG_SAY", "CHAT_MSG_YELL" }

local module = ns:NewModule("GuildRecruitTab", {
	title = L.TITLE,
	description = L.DESC,
	note = L.NOTE,
	category = "CHAT",
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
				if self:GetTabFrame() then
					self:Print(L.TAB_EXISTS)
				else
					self:CreateTabFrame()
				end
			end,
		},
	},
})

local Chat = ns.Chat

local keywords = {}

function module:ParseKeywords()
	wipe(keywords)
	Chat.ParseList(self.db.keywords, keywords)
end

-- The shown chat window named like our tab, if any.
function module:GetTabFrame()
	for i = 1, Chat.MAX_WINDOWS do
		local name, _, _, _, _, _, shown, _, docked = GetChatWindowInfo(i)
		if name == L.TAB and (shown or docked) then
			return _G["ChatFrame" .. i]
		end
	end
end

function module:CreateTabFrame()
	-- FCF_OpenNewWindow selects the new tab; keep the current one selected.
	local selected = FCFDock_GetSelectedWindow(GENERAL_CHAT_DOCK)
	local frame = FCF_OpenNewWindow(L.TAB, true)
	if not frame then
		self:Print(L.NO_FREE_WINDOW)
		return
	end
	if selected then
		FCFDock_SelectWindow(GENERAL_CHAT_DOCK, selected)
		if ChatFrameUtil and ChatFrameUtil.SetLastActiveWindow and selected.editBox then
			ChatFrameUtil.SetLastActiveWindow(selected.editBox)
		end
	end
	frame:AddMessageGroup("SAY")
	frame:AddMessageGroup("YELL")
	frame:AddMessageGroup("CHANNEL")
	local channels = { GetChannelList() }
	for i = 2, #channels, 3 do
		frame:AddChannel(channels[i])
	end
	self:Print(L.TAB_CREATED)
	return frame
end

-- The spam filter's tab keeps its own messages; dropping matches there too
-- would hide a message that is both spam and a guild ad everywhere.
local function IsSpamTab(chatFrame)
	local spamFilter = ns:GetModule("SpamFilter")
	return spamFilter and spamFilter.enabled and chatFrame == spamFilter:GetSpamFrame()
end

-- Runs once per chat frame that receives the message: matches are dropped
-- everywhere except our tab, which in turn drops everything else. Without
-- the tab nothing is dropped. Blizzard only calls filters when all args are
-- accessible (no secret values).
local function Filter(chatFrame, _, text)
	if type(text) ~= "string" then
		return false
	end
	local tabFrame = module:GetTabFrame()
	if not tabFrame then
		return false
	end
	local match = Chat.ContainsAny(text, keywords)
	if chatFrame == tabFrame then
		return not match
	end
	return match and not IsSpamTab(chatFrame)
end

-- Same lifecycle as the spam filter: a tab that was closed since the last
-- session turns the module off instead of being recreated at login.
function module:CheckTabFrame()
	if self:GetTabFrame() then
		self.db.tabCreated = true
	elseif self.db.tabCreated then
		self:Print(L.TAB_MISSING)
		ns:SetModuleEnabled(self, false)
	elseif self:CreateTabFrame() then
		self.db.tabCreated = true
	end
end

function module:OnOptionChanged(key)
	if key == "keywords" then
		self:ParseKeywords()
	end
end

function module:OnEnable()
	self:ParseKeywords()
	-- Delayed because chat windows are set up after PLAYER_LOGIN.
	C_Timer.After(2, function()
		if self.enabled then
			self:CheckTabFrame()
		end
	end)
	Chat.AddFilters(EVENTS, Filter)
end

function module:OnDisable()
	self.db.tabCreated = false
	Chat.RemoveFilters(EVENTS, Filter)
end
