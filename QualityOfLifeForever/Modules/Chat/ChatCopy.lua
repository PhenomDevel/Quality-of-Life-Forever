-- luacheck: read globals Constants NUM_CHAT_WINDOWS UIParent UISpecialFrames tinsert GameTooltip ChatFontNormal C_Timer
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Copy chat",
		NOTE = "Copy text from the chat",
		DESC = "Adds a small button to the top right of each chat window. It opens the window's chat history as plain text, so you can select and copy it with Ctrl+C.",
		BUTTON_TOOLTIP = "Copy chat",
		WINDOW_TITLE = "Copy chat: select the text and press Ctrl+C",
	},
	deDE = {
		TITLE = "Chat kopieren",
		NOTE = "Text aus dem Chat kopieren",
		DESC = "Fügt oben rechts an jedem Chatfenster einen kleinen Button hinzu. Er öffnet den Verlauf des Fensters als reinen Text, den du markieren und mit Strg+C kopieren kannst.",
		BUTTON_TOOLTIP = "Chat kopieren",
		WINDOW_TITLE = "Chat kopieren: Text markieren und Strg+C drücken",
	},
})

local module = ns:NewModule("ChatCopy", {
	title = L.TITLE,
	description = L.DESC,
	note = L.NOTE,
	category = "CHAT",
	order = 60,
})

local MAX_WINDOWS = Constants and Constants.ChatFrameConstants and Constants.ChatFrameConstants.MaxChatWindows or NUM_CHAT_WINDOWS
local BUTTON_SIZE = 18
local IDLE_ALPHA = 0.35
local WINDOW_WIDTH, WINDOW_HEIGHT = 560, 380
local PADDING = 10

local IsSecret = ns.Utils.IsSecret
local buttons = {}
local window

-- Chat lines carry colors, textures and links; keep only what is readable.
local function PlainText(text)
	text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
	text = text:gsub("|H.-|h(.-)|h", "%1")
	text = text:gsub("|T.-|t", ""):gsub("|A.-|a", ""):gsub("|K.-|k", "?")
	return text
end

local function CreateWindow()
	window = CreateFrame("Frame", "QualityOfLifeForeverChatCopy", UIParent)
	window:SetSize(WINDOW_WIDTH, WINDOW_HEIGHT)
	window:SetPoint("CENTER")
	window:SetFrameStrata("DIALOG")
	window:EnableMouse(true)
	window:SetMovable(true)
	window:RegisterForDrag("LeftButton")
	window:SetScript("OnDragStart", window.StartMoving)
	window:SetScript("OnDragStop", window.StopMovingOrSizing)
	window:SetClampedToScreen(true)
	ns:AddPanelBackground(window)
	tinsert(UISpecialFrames, window:GetName())

	window.Title = window:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	window.Title:SetPoint("TOPLEFT", PADDING, -PADDING)

	window.Close = CreateFrame("Button", nil, window, "UIPanelCloseButton")
	window.Close:SetPoint("TOPRIGHT", 2, 2)

	local scroll = CreateFrame("ScrollFrame", nil, window, "UIPanelScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", PADDING, -(PADDING + 18))
	scroll:SetPoint("BOTTOMRIGHT", -(PADDING + 22), PADDING)

	local edit = CreateFrame("EditBox", nil, scroll)
	edit:SetMultiLine(true)
	edit:SetAutoFocus(false)
	edit:SetFontObject(ChatFontNormal)
	edit:SetWidth(WINDOW_WIDTH - PADDING * 2 - 22)
	edit:SetScript("OnEscapePressed", function()
		window:Hide()
	end)
	scroll:SetScrollChild(edit)
	window.Scroll, window.Edit = scroll, edit
	window:Hide()
end

function module:ShowHistory(chatFrame)
	if not window then
		CreateWindow()
	end
	local lines = {}
	for i = 1, chatFrame:GetNumMessages() do
		local text = chatFrame:GetMessageInfo(i)
		-- Messages can be secret during chat lockdown; those are left out.
		if type(text) == "string" and not IsSecret(text) then
			lines[#lines + 1] = PlainText(text)
		end
	end
	window.Title:SetText(L.WINDOW_TITLE)
	window.Edit:SetText(table.concat(lines, "\n"))
	window:Show()
	window.Edit:SetFocus()
	window.Edit:HighlightText()
	-- Start at the newest lines once the edit box has its height.
	C_Timer.After(0, function()
		window.Scroll:SetVerticalScroll(window.Scroll:GetVerticalScrollRange())
	end)
end

local function CreateButton(chatFrame)
	local button = CreateFrame("Button", nil, chatFrame)
	button:SetSize(BUTTON_SIZE, BUTTON_SIZE)
	button:SetPoint("TOPRIGHT", chatFrame, "TOPRIGHT", 0, 0)
	button:SetFrameLevel(chatFrame:GetFrameLevel() + 5)
	button:SetNormalTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Up")
	button:SetHighlightTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Up", "ADD")
	button:SetAlpha(IDLE_ALPHA)
	button:SetScript("OnClick", function()
		module:ShowHistory(chatFrame)
	end)
	button:SetScript("OnEnter", function(self)
		self:SetAlpha(1)
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		GameTooltip:SetText(L.BUTTON_TOOLTIP)
		GameTooltip:Show()
	end)
	button:SetScript("OnLeave", function(self)
		self:SetAlpha(IDLE_ALPHA)
		GameTooltip:Hide()
	end)
	return button
end

function module:OnEnable()
	for i = 1, MAX_WINDOWS do
		local chatFrame = _G["ChatFrame" .. i]
		if chatFrame then
			buttons[i] = buttons[i] or CreateButton(chatFrame)
			buttons[i]:Show()
		end
	end
end

function module:OnDisable()
	for _, button in pairs(buttons) do
		button:Hide()
	end
	if window then
		window:Hide()
	end
end
