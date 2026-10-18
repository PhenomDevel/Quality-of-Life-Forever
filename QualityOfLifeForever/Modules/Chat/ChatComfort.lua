-- luacheck: read globals IsShiftKeyDown
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Chat comfort",
		NOTE = "Longer history, quick scrolling",
		DESC = "Keeps more lines in the chat history and lets you jump to the first or newest message with Shift + mouse wheel.",
		HISTORY = "Lines in chat history",
		HISTORY_DESC = "Number of lines each chat window keeps. Changing it clears the chat windows once.",
		SCROLL = "Shift + wheel: jump to top/end",
		SCROLL_DESC = "Holding Shift while scrolling jumps to the first or the newest message.",
	},
	deDE = {
		TITLE = "Chat-Komfort",
		NOTE = "Längerer Verlauf, schnelles Scrollen",
		DESC = "Behält mehr Zeilen im Chatverlauf und springt mit Shift + Mausrad zur ersten oder neuesten Nachricht.",
		HISTORY = "Zeilen im Chatverlauf",
		HISTORY_DESC = "Anzahl der Zeilen, die jedes Chatfenster behält. Eine Änderung leert die Chatfenster einmalig.",
		SCROLL = "Shift + Mausrad: Anfang/Ende",
		SCROLL_DESC = "Mit gehaltener Shift-Taste springt das Mausrad zur ersten oder neuesten Nachricht.",
	},
})

local DEFAULT_HISTORY = 128

local module = ns:NewModule("ChatComfort", {
	title = L.TITLE,
	description = L.DESC,
	note = L.NOTE,
	category = "CHAT",
	defaults = {
		history = 1024,
		scroll = true,
	},
	options = {
		{ key = "history", type = "slider", label = L.HISTORY, tooltip = L.HISTORY_DESC, min = DEFAULT_HISTORY, max = 4096, step = 128 },
		{ key = "scroll", type = "checkbox", label = L.SCROLL, tooltip = L.SCROLL_DESC },
	},
})

local ForEachFrame = ns.Chat.ForEachFrame

-- Line counts before the module changed them, restored on disable.
local originalLines = {}

-- SetMaxLines clears the frame, so only call it when the value changes.
function module:ApplyHistory()
	ForEachFrame(function(frame)
		if originalLines[frame] == nil then
			originalLines[frame] = frame:GetMaxLines()
		end
		if frame:GetMaxLines() ~= self.db.history then
			frame:SetMaxLines(self.db.history)
		end
	end)
end

function module:OnEnable()
	self:ApplyHistory()
	ForEachFrame(function(frame)
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
	for frame, lines in pairs(originalLines) do
		if frame:GetMaxLines() ~= lines then
			frame:SetMaxLines(lines)
		end
	end
	wipe(originalLines)
end

function module:OnOptionChanged(key)
	if key == "history" then
		self:ApplyHistory()
	end
end
