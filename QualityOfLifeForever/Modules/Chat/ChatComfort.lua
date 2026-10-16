-- luacheck: read globals Constants NUM_CHAT_WINDOWS IsShiftKeyDown
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Chat comfort",
		NOTE = "Arrow keys, longer history, fewer buttons",
		DESC = "Small improvements for the chat windows.",
		ARROW_KEYS = "Arrow keys without Alt",
		ARROW_KEYS_DESC = "Move the cursor in the chat input with the arrow keys; Up/Down browse the sent messages. Without this, Alt has to be held.",
		HISTORY = "Chat history",
		HISTORY_DESC = "Number of lines each chat window keeps. Changing it clears the chat windows once.",
		SCROLL = "Shift + mouse wheel",
		SCROLL_DESC = "Holding Shift while scrolling jumps to the first or the newest message.",
		HIDE_BUTTONS = "Hide chat buttons",
		HIDE_BUTTONS_DESC = "Hides the menu, channel and voice buttons next to the chat.",
	},
	deDE = {
		TITLE = "Chat-Komfort",
		NOTE = "Pfeiltasten, längerer Verlauf, weniger Knöpfe",
		DESC = "Kleine Verbesserungen für die Chatfenster.",
		ARROW_KEYS = "Pfeiltasten ohne Alt",
		ARROW_KEYS_DESC = "Cursor in der Chateingabe mit den Pfeiltasten bewegen; Hoch/Runter blättert durch gesendete Nachrichten. Ohne diese Option muss Alt gehalten werden.",
		HISTORY = "Chatverlauf",
		HISTORY_DESC = "Anzahl der Zeilen, die jedes Chatfenster behält. Eine Änderung leert die Chatfenster einmalig.",
		SCROLL = "Shift + Mausrad",
		SCROLL_DESC = "Mit gehaltener Shift-Taste springt das Mausrad zur ersten oder neuesten Nachricht.",
		HIDE_BUTTONS = "Chat-Knöpfe ausblenden",
		HIDE_BUTTONS_DESC = "Blendet die Menü-, Kanal- und Sprachchat-Knöpfe neben dem Chat aus.",
	},
})

local DEFAULT_HISTORY = 128

local module = ns:NewModule("ChatComfort", {
	title = L.TITLE,
	description = L.DESC,
	note = L.NOTE,
	category = "CHAT",
	defaults = {
		arrowKeys = true,
		history = 1024,
		scroll = true,
		hideButtons = false,
	},
	options = {
		{ key = "arrowKeys", type = "checkbox", label = L.ARROW_KEYS, tooltip = L.ARROW_KEYS_DESC },
		{ key = "history", type = "slider", label = L.HISTORY, tooltip = L.HISTORY_DESC, min = DEFAULT_HISTORY, max = 4096, step = 128 },
		{ key = "scroll", type = "checkbox", label = L.SCROLL, tooltip = L.SCROLL_DESC },
		{ key = "hideButtons", type = "checkbox", label = L.HIDE_BUTTONS, tooltip = L.HIDE_BUTTONS_DESC },
	},
})

local MAX_WINDOWS = Constants and Constants.ChatFrameConstants and Constants.ChatFrameConstants.MaxChatWindows or NUM_CHAT_WINDOWS
local BUTTONS = { "ChatFrameMenuButton", "ChatFrameChannelButton", "ChatFrameToggleVoiceDeafenButton", "ChatFrameToggleVoiceMuteButton", "QuickJoinToastButton" }

local function EachChatFrame(func)
	for i = 1, MAX_WINDOWS do
		local frame = _G["ChatFrame" .. i]
		if frame then
			func(frame, _G["ChatFrame" .. i .. "EditBox"])
		end
	end
end

-- Values before the module changed them, restored on disable. hiddenButtons
-- only holds buttons we hid, so ones Blizzard hides (voice) stay hidden.
local originalArrowMode, originalLines, hiddenButtons = {}, {}, {}

function module:ApplyArrowKeys()
	EachChatFrame(function(_, editBox)
		if editBox then
			if originalArrowMode[editBox] == nil then
				originalArrowMode[editBox] = editBox:GetAltArrowKeyMode()
			end
			editBox:SetAltArrowKeyMode(not self.db.arrowKeys and originalArrowMode[editBox])
		end
	end)
end

-- SetMaxLines clears the frame, so only call it when the value changes.
function module:ApplyHistory()
	EachChatFrame(function(frame)
		if originalLines[frame] == nil then
			originalLines[frame] = frame:GetMaxLines()
		end
		if frame:GetMaxLines() ~= self.db.history then
			frame:SetMaxLines(self.db.history)
		end
	end)
end

local function HideButton(button)
	if button:IsShown() then
		hiddenButtons[button] = true
		button:Hide()
	end
end

local function RestoreButtons()
	for button in pairs(hiddenButtons) do
		button:Show()
	end
	wipe(hiddenButtons)
end

function module:ApplyButtons()
	if not self.db.hideButtons then
		RestoreButtons()
		return
	end
	for _, name in ipairs(BUTTONS) do
		local button = _G[name]
		if button then
			HideButton(button)
			self:HookScript(button, "OnShow", function()
				if self.db.hideButtons then
					HideButton(button)
				end
			end)
		end
	end
end

function module:OnEnable()
	self:ApplyArrowKeys()
	self:ApplyHistory()
	self:ApplyButtons()
	EachChatFrame(function(frame)
		self:HookScript(frame, "OnMouseWheel", function(_, chatFrame, delta)
			if self.db.scroll and IsShiftKeyDown() then
				if delta > 0 then
					chatFrame:ScrollToTop()
				else
					chatFrame:ScrollToBottom()
				end
			end
		end)
	end)
end

function module:OnDisable()
	for editBox, mode in pairs(originalArrowMode) do
		editBox:SetAltArrowKeyMode(mode)
	end
	for frame, lines in pairs(originalLines) do
		if frame:GetMaxLines() ~= lines then
			frame:SetMaxLines(lines)
		end
	end
	wipe(originalArrowMode)
	wipe(originalLines)
	RestoreButtons()
end

function module:OnOptionChanged(key)
	if key == "arrowKeys" then
		self:ApplyArrowKeys()
	elseif key == "history" then
		self:ApplyHistory()
	elseif key == "hideButtons" then
		self:ApplyButtons()
	end
end
