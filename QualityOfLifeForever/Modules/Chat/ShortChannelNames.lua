-- luacheck: read globals EnumerateServerChannels Constants NUM_CHAT_WINDOWS
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Short channel names",
		NOTE = "[1. General - Elwynn Forest] → [1.G]",
		DESC = "Shortens the channel tag of channel messages: number plus the initials of server channels (General → G, Trade → T, LookingForGroup → LFG). Custom channels keep their name, without the zone suffix.",
	},
	deDE = {
		TITLE = "Kurze Kanalnamen",
		NOTE = "[1. Allgemein - Wald von Elwynn] → [1.A]",
		DESC = "Kürzt die Kanalangabe von Kanalnachrichten: Nummer plus die Anfangsbuchstaben der Serverkanäle (Allgemein → A, Handel → H, SucheNachGruppe → SNG). Eigene Kanäle behalten ihren Namen, ohne Zonenzusatz.",
	},
})

local module = ns:NewModule("ShortChannelNames", {
	title = L.TITLE,
	description = L.DESC,
	note = L.NOTE,
	category = "CHAT",
})

local MAX_WINDOWS = Constants and Constants.ChatFrameConstants and Constants.ChatFrameConstants.MaxChatWindows or NUM_CHAT_WINDOWS

-- Localized base names of the server channels (General, Trade, …).
local serverChannels

local function IsServerChannel(baseName)
	if not serverChannels then
		serverChannels = {}
		for _, name in ipairs({ EnumerateServerChannels() }) do
			serverChannels[name] = true
		end
	end
	-- Without the API every channel counts as a server channel.
	return next(serverChannels) == nil or serverChannels[baseName]
end

local function Shorten(baseName)
	local initials = baseName:gsub("%U", "")
	if initials == "" then
		return baseName:sub(1, 1):upper()
	end
	return initials
end

local function ShortTag(channelID, number, name)
	local baseName = name:gsub(" %- .*$", "")
	local short = IsServerChannel(baseName) and Shorten(baseName) or baseName
	return ("|Hchannel:channel:%s|h[%s.%s]|h"):format(channelID, number, short)
end

-- The chat frame prefixes channel lines with
-- "|Hchannel:channel:<id>|h[<number>. <name>]|h". The channel name in the
-- event itself can't be changed: it is also used to match the line to the
-- chat frames that show the channel.
local function Transform(text)
	if ns.Utils.IsSecret(text) or type(text) ~= "string" then
		return text
	end
	return (text:gsub("|Hchannel:channel:(%d+)|h%[(%d+)%. ([^%]]+)%]|h", ShortTag, 1))
end

local wrapped = {}

-- Wrapping stays in place after disabling (it then passes text through), so a
-- wrapper another addon put on top of ours is never removed.
local function Wrap(frame)
	if not frame or wrapped[frame] then
		return
	end
	wrapped[frame] = true
	local original = frame.AddMessage
	frame.AddMessage = function(self, text, ...)
		if module.enabled then
			text = Transform(text)
		end
		return original(self, text, ...)
	end
end

function module:OnEnable()
	for i = 1, MAX_WINDOWS do
		Wrap(_G["ChatFrame" .. i])
	end
end
