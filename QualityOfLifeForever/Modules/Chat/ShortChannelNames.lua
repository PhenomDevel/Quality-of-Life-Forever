-- luacheck: read globals ChatFrameUtil ChatFrame_AddMessageEventFilter ChatFrame_RemoveMessageEventFilter
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Short channel names",
		NOTE = "[1. General - Elwynn Forest] → [1. G]",
		DESC = "Shortens the channel tag of channel messages: number plus the initials of server channels (General → G, Trade → T, LookingForGroup → LFG). Custom channels keep their name, without the zone suffix.",
	},
	deDE = {
		TITLE = "Kurze Kanalnamen",
		NOTE = "[1. Allgemein - Wald von Elwynn] → [1. A]",
		DESC = "Kürzt die Kanalangabe von Kanalnachrichten: Nummer plus die Anfangsbuchstaben der Serverkanäle (Allgemein → A, Handel → H, SucheNachGruppe → SNG). Eigene Kanäle behalten ihren Namen, ohne Zonenzusatz.",
	},
})

local module = ns:NewModule("ShortChannelNames", {
	title = L.TITLE,
	description = L.DESC,
	note = L.NOTE,
	category = "CHAT",
})

local EVENT = "CHAT_MSG_CHANNEL"

-- ChatFrameUtil replaced the global filter functions in newer clients.
local AddFilter = ChatFrameUtil and ChatFrameUtil.AddMessageEventFilter or ChatFrame_AddMessageEventFilter
local RemoveFilter = ChatFrameUtil and ChatFrameUtil.RemoveMessageEventFilter or ChatFrame_RemoveMessageEventFilter

local function Shorten(baseName)
	local initials = baseName:gsub("%U", "")
	if initials == "" then
		return baseName:sub(1, 1):upper()
	end
	return initials
end

-- Event args: text, playerName, languageName, channelName ("1. General - Elwynn
-- Forest"), playerName2, specialFlags, zoneChannelID (0 for custom channels),
-- channelIndex, channelBaseName, … The chat frame builds the tag from
-- channelName and expects the "<number>. " prefix, so only the name part changes.
-- Filters only run when all args are accessible (no secret values).
local function Filter(_, _, text, playerName, languageName, _, playerName2, specialFlags, zoneChannelID, channelIndex, channelBaseName, ...)
	if type(channelIndex) ~= "number" or type(channelBaseName) ~= "string" or channelBaseName == "" then
		return false
	end
	local name = zoneChannelID ~= 0 and Shorten(channelBaseName) or channelBaseName
	return false, text, playerName, languageName, ("%d. %s"):format(channelIndex, name), playerName2,
		specialFlags, zoneChannelID, channelIndex, channelBaseName, ...
end

function module:OnEnable()
	AddFilter(EVENT, Filter)
end

function module:OnDisable()
	RemoveFilter(EVENT, Filter)
end
