-- luacheck: read globals ChatFrameUtil ChatFrame_AddMessageEventFilter ChatFrame_RemoveMessageEventFilter StaticPopup_Show GetChatWindowInfo GetChannelList FCF_OpenNewWindow FCFDock_GetSelectedWindow FCFDock_SelectWindow GENERAL_CHAT_DOCK C_Timer Constants NUM_CHAT_WINDOWS ACCEPT CANCEL strtrim
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Spam filter",
		NOTE = "Moves matching messages to a \"Spam\" tab",
		DESC = "Channel, say and yell messages containing one of your keywords are shown only in a separate \"Spam\" chat tab instead of your other tabs. Nothing is deleted. Without the tab nothing is moved.",
		TAB = "Spam",
		KEYWORDS = "Keywords",
		KEYWORDS_DESC = "Edit the comma-separated keyword list (case-insensitive, matched anywhere in the message).\n\nDefault: %s",
		EDIT = "Edit",
		CREATE_TAB = "Spam tab",
		CREATE_TAB_DESC = "Creates the \"Spam\" chat tab if it doesn't exist. Enabling the module also creates it.",
		CREATE = "Create",
		DIALOG = "Keywords, separated by commas:",
		TAB_CREATED = "Created the \"Spam\" chat tab.",
		TAB_EXISTS = "The \"Spam\" chat tab already exists.",
		NO_FREE_WINDOW = "No free chat window left to create the \"Spam\" tab.",
		TAB_MISSING = "The \"Spam\" chat tab is gone, so the spam filter was disabled. Enable it again to recreate the tab.",
	},
	deDE = {
		TITLE = "Spamfilter",
		NOTE = "Verschiebt Treffer in einen „Spam“-Tab",
		DESC = "Kanal-, Sagen- und Schreien-Nachrichten mit einem deiner Stichwörter erscheinen nur in einem eigenen Chat-Tab „Spam“ statt in deinen anderen Tabs. Es wird nichts gelöscht. Ohne den Tab wird nichts verschoben.",
		TAB = "Spam",
		KEYWORDS = "Stichwörter",
		KEYWORDS_DESC = "Bearbeitet die kommagetrennte Stichwortliste (ohne Groß-/Kleinschreibung, irgendwo in der Nachricht).\n\nStandard: %s",
		EDIT = "Bearbeiten",
		CREATE_TAB = "Spam-Tab",
		CREATE_TAB_DESC = "Erstellt den Chat-Tab „Spam“, falls er fehlt. Auch das Aktivieren des Moduls erstellt ihn.",
		CREATE = "Erstellen",
		DIALOG = "Stichwörter, durch Kommas getrennt:",
		TAB_CREATED = "Chat-Tab „Spam“ erstellt.",
		TAB_EXISTS = "Der Chat-Tab „Spam“ existiert bereits.",
		NO_FREE_WINDOW = "Kein freies Chatfenster mehr für den Tab „Spam“.",
		TAB_MISSING = "Der Chat-Tab „Spam“ fehlt, daher wurde der Spamfilter deaktiviert. Aktiviere ihn erneut, um den Tab wieder zu erstellen.",
	},
})

local DEFAULT_KEYWORDS = "boost, goldselling, carry"
local EVENTS = { "CHAT_MSG_CHANNEL", "CHAT_MSG_SAY", "CHAT_MSG_YELL" }
local DIALOG = "QUALITYOFLIFEFOREVER_SPAM_KEYWORDS"

local module = ns:NewModule("SpamFilter", {
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
			type = "button",
			label = L.KEYWORDS,
			buttonText = L.EDIT,
			tooltip = L.KEYWORDS_DESC:format(DEFAULT_KEYWORDS),
			onClick = function()
				StaticPopup_Show(DIALOG)
			end,
		},
		{
			type = "button",
			label = L.CREATE_TAB,
			buttonText = L.CREATE,
			tooltip = L.CREATE_TAB_DESC,
			onClick = function(self)
				if self:GetSpamFrame() then
					self:Print(L.TAB_EXISTS)
				else
					self:CreateSpamFrame()
				end
			end,
		},
	},
})

local AddFilter = ChatFrameUtil and ChatFrameUtil.AddMessageEventFilter or ChatFrame_AddMessageEventFilter
local RemoveFilter = ChatFrameUtil and ChatFrameUtil.RemoveMessageEventFilter or ChatFrame_RemoveMessageEventFilter
local MAX_WINDOWS = Constants and Constants.ChatFrameConstants and Constants.ChatFrameConstants.MaxChatWindows or NUM_CHAT_WINDOWS

local keywords = {}

function module:ParseKeywords()
	wipe(keywords)
	for word in self.db.keywords:gmatch("[^,]+") do
		word = strtrim(word):lower()
		if word ~= "" then
			keywords[#keywords + 1] = word
		end
	end
end

local function IsSpam(text)
	text = text:lower()
	for _, word in ipairs(keywords) do
		if text:find(word, 1, true) then
			return true
		end
	end
	return false
end

-- The shown chat window named "Spam", if any.
function module:GetSpamFrame()
	for i = 1, MAX_WINDOWS do
		local name, _, _, _, _, _, shown, _, docked = GetChatWindowInfo(i)
		if name == L.TAB and (shown or docked) then
			return _G["ChatFrame" .. i]
		end
	end
end

function module:CreateSpamFrame()
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

-- Runs once per chat frame that receives the message: matches are dropped
-- everywhere except the spam tab, which in turn drops everything else.
-- Without a spam tab nothing is dropped. Blizzard only calls filters when all
-- args are accessible (no secret values).
local function Filter(chatFrame, _, text)
	if type(text) ~= "string" then
		return false
	end
	local spamFrame = module:GetSpamFrame()
	if not spamFrame then
		return false
	end
	local spam = IsSpam(text)
	if chatFrame == spamFrame then
		return not spam
	end
	return spam
end

function module:OnInitialize()
	StaticPopupDialogs[DIALOG] = {
		text = L.DIALOG,
		button1 = ACCEPT,
		button2 = CANCEL,
		hasEditBox = 1,
		editBoxWidth = 350,
		maxLetters = 1000,
		OnShow = function(dialog)
			local editBox = dialog:GetEditBox()
			editBox:SetText(self.db.keywords)
			editBox:HighlightText()
		end,
		OnAccept = function(dialog)
			self.db.keywords = dialog:GetEditBox():GetText()
			self:ParseKeywords()
		end,
		EditBoxOnEnterPressed = function(editBox)
			editBox:GetParent():GetButton1():Click()
		end,
		timeout = 0,
		whileDead = 1,
		hideOnEscape = 1,
	}
end

-- tabCreated is true while the module is enabled with its tab. Enabled with
-- tabCreated set but no tab means the tab was closed since the last session
-- (the check runs at login): turn the module off instead of recreating it.
-- Turning it off clears the flag, so the next enable creates the tab again.
function module:CheckSpamFrame()
	if self:GetSpamFrame() then
		self.db.tabCreated = true
	elseif self.db.tabCreated then
		self:Print(L.TAB_MISSING)
		ns:SetModuleEnabled(self, false)
	elseif self:CreateSpamFrame() then
		self.db.tabCreated = true
	end
end

function module:OnEnable()
	self:ParseKeywords()
	-- Delayed because chat windows are set up after PLAYER_LOGIN.
	C_Timer.After(2, function()
		if self.enabled then
			self:CheckSpamFrame()
		end
	end)
	for _, event in ipairs(EVENTS) do
		AddFilter(event, Filter)
	end
end

function module:OnDisable()
	self.db.tabCreated = false
	for _, event in ipairs(EVENTS) do
		RemoveFilter(event, Filter)
	end
end
