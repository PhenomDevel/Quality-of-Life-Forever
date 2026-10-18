-- luacheck: read globals ChatFrameUtil ChatFrame_AddMessageEventFilter ChatFrame_RemoveMessageEventFilter Constants NUM_CHAT_WINDOWS strtrim
local _, ns = ...

-- Shared helpers for the chat modules.
local Chat = {}
ns.Chat = Chat

Chat.MAX_WINDOWS = Constants and Constants.ChatFrameConstants and Constants.ChatFrameConstants.MaxChatWindows or NUM_CHAT_WINDOWS

local AddFilter = ChatFrameUtil and ChatFrameUtil.AddMessageEventFilter or ChatFrame_AddMessageEventFilter
local RemoveFilter = ChatFrameUtil and ChatFrameUtil.RemoveMessageEventFilter or ChatFrame_RemoveMessageEventFilter

-- Calls func(frame, editBox) for every existing ChatFrame1..n.
function Chat.ForEachFrame(func)
	for i = 1, Chat.MAX_WINDOWS do
		local frame = _G["ChatFrame" .. i]
		if frame then
			func(frame, _G["ChatFrame" .. i .. "EditBox"])
		end
	end
end

function Chat.AddFilters(events, filter)
	for _, event in ipairs(events) do
		AddFilter(event, filter)
	end
end

function Chat.RemoveFilters(events, filter)
	for _, event in ipairs(events) do
		RemoveFilter(event, filter)
	end
end

-- Comma-separated words, trimmed and lower-cased; empty entries are skipped.
-- Appends to `list` (a new table without one) and returns it.
function Chat.ParseList(text, list)
	list = list or {}
	for word in text:gmatch("[^,]+") do
		word = strtrim(word):lower()
		if word ~= "" then
			list[#list + 1] = word
		end
	end
	return list
end

-- Whether text contains one of the lower-case words, case-insensitively.
function Chat.ContainsAny(text, words)
	text = text:lower()
	for _, word in ipairs(words) do
		if text:find(word, 1, true) then
			return true
		end
	end
	return false
end
