-- luacheck: read globals ChatFrameUtil ChatFrame_AddMessageEventFilter ChatFrame_RemoveMessageEventFilter EventRegistry StaticPopup_Show CLOSE
local addonName, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Copyable URLs",
		NOTE = "Click a link in chat to copy it",
		DESC = "Turns web addresses in chat messages into links. Clicking one opens a box with the address selected, ready for Ctrl+C.",
		COPY = "Press Ctrl+C to copy the address.",
	},
	deDE = {
		TITLE = "Kopierbare Links",
		NOTE = "Link im Chat anklicken zum Kopieren",
		DESC = "Macht Webadressen in Chatnachrichten zu Links. Ein Klick öffnet ein Feld mit der markierten Adresse, bereit für Strg+C.",
		COPY = "Drücke Strg+C, um die Adresse zu kopieren.",
	},
})

local module = ns:NewModule("CopyableURLs", {
	title = L.TITLE,
	description = L.DESC,
	note = L.NOTE,
	category = "CHAT",
})

local EVENTS = {
	"CHAT_MSG_SAY", "CHAT_MSG_YELL", "CHAT_MSG_EMOTE",
	"CHAT_MSG_GUILD", "CHAT_MSG_OFFICER",
	"CHAT_MSG_PARTY", "CHAT_MSG_PARTY_LEADER",
	"CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER", "CHAT_MSG_RAID_WARNING",
	"CHAT_MSG_INSTANCE_CHAT", "CHAT_MSG_INSTANCE_CHAT_LEADER",
	"CHAT_MSG_WHISPER", "CHAT_MSG_WHISPER_INFORM",
	"CHAT_MSG_BN_WHISPER", "CHAT_MSG_BN_WHISPER_INFORM",
	"CHAT_MSG_CHANNEL", "CHAT_MSG_COMMUNITIES_CHANNEL",
}

-- "addon:" links are routed to EventRegistry's "SetItemRef" event.
local LINK_PREFIX = "addon:" .. addonName .. ":url:"
local LINK_FORMAT = "%s|cff4fb3ff|H" .. LINK_PREFIX .. "%s|h%s|h|r%s"
local LINK_PATTERN = "^" .. LINK_PREFIX:gsub("%p", "%%%0") .. "(.+)$"
local POPUP = "QUALITYOFLIFEFOREVER_COPY_URL"

local AddFilter = ChatFrameUtil and ChatFrameUtil.AddMessageEventFilter or ChatFrame_AddMessageEventFilter
local RemoveFilter = ChatFrameUtil and ChatFrameUtil.RemoveMessageEventFilter or ChatFrame_RemoveMessageEventFilter

-- Words containing "|" are part of hyperlinks or escape sequences and stay as
-- they are. Surrounding brackets/quotes and trailing punctuation are not part
-- of the address.
local function LinkifyWord(word)
	if word:find("|", 1, true) then
		return
	end
	local leading, url, trailing = word:match("^([%(%[<\"']*)(.-)([%.,;:!%?%)%]>\"']*)$")
	if not (url:find("^[Hh][Tt][Tt][Pp][Ss]?://%w") or url:find("^[Ww][Ww][Ww]%.%w")) then
		return
	end
	return LINK_FORMAT:format(leading, url, url, trailing)
end

local function Filter(_, _, text, ...)
	if type(text) ~= "string" then
		return false
	end
	local linked = text:gsub("%S+", LinkifyWord)
	if linked == text then
		return false
	end
	return false, linked, ...
end

local function OnSetItemRef(_, link)
	if not module.enabled or type(link) ~= "string" then
		return
	end
	local url = link:match(LINK_PATTERN)
	if url then
		StaticPopup_Show(POPUP, nil, nil, url)
	end
end

function module:OnInitialize()
	StaticPopupDialogs[POPUP] = {
		text = L.COPY,
		button1 = CLOSE,
		hasEditBox = 1,
		editBoxWidth = 350,
		OnShow = function(dialog, url)
			local editBox = dialog:GetEditBox()
			editBox:SetText(url)
			editBox:SetFocus()
			editBox:HighlightText()
		end,
		EditBoxOnEnterPressed = function(editBox)
			editBox:GetParent():Hide()
		end,
		EditBoxOnEscapePressed = function(editBox)
			editBox:GetParent():Hide()
		end,
		timeout = 0,
		whileDead = 1,
		hideOnEscape = 1,
	}
	EventRegistry:RegisterCallback("SetItemRef", OnSetItemRef, self)
end

function module:OnEnable()
	for _, event in ipairs(EVENTS) do
		AddFilter(event, Filter)
	end
end

function module:OnDisable()
	for _, event in ipairs(EVENTS) do
		RemoveFilter(event, Filter)
	end
end
