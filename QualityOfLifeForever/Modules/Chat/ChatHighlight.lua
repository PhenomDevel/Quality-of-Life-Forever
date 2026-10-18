-- luacheck: read globals UnitName Ambiguate PlaySound SOUNDKIT
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Chat highlight",
		NOTE = "Your name and keywords stand out",
		DESC = "Colors your name and your keywords in chat messages of others and plays a sound. Optionally plays a louder sound for whispers.",
		SECTION_MENTIONS = "Mentions",
		NAME = "Highlight your name",
		NAME_DESC = "Highlights messages that contain your character name.",
		KEYWORDS = "Keywords",
		KEYWORDS_DESC = "Separated by commas, case-insensitive. Saved with Enter.",
		KEYWORDS_HINT = "Words, separated by commas",
		SOUND = "Sound on mention",
		SOUND_DESC = "Plays a sound when a message mentions your name or a keyword.",
		SECTION_WHISPERS = "Whispers",
		WHISPER_SOUND = "Loud whisper sound",
		WHISPER_SOUND_DESC = "Plays an extra sound on the master channel for incoming whispers, also when sound effects are muted.",
	},
	deDE = {
		TITLE = "Chat-Hervorhebung",
		NOTE = "Dein Name und Stichwörter fallen auf",
		DESC = "Färbt deinen Namen und deine Stichwörter in Chatnachrichten anderer ein und spielt einen Ton. Optional ein lauterer Ton bei Flüsternachrichten.",
		SECTION_MENTIONS = "Erwähnungen",
		NAME = "Deinen Namen hervorheben",
		NAME_DESC = "Hebt Nachrichten hervor, die deinen Charakternamen enthalten.",
		KEYWORDS = "Stichwörter",
		KEYWORDS_DESC = "Durch Kommas getrennt, ohne Groß-/Kleinschreibung. Wird mit Enter gespeichert.",
		KEYWORDS_HINT = "Wörter, durch Kommas getrennt",
		SOUND = "Ton bei Erwähnung",
		SOUND_DESC = "Spielt einen Ton, wenn eine Nachricht deinen Namen oder ein Stichwort enthält.",
		SECTION_WHISPERS = "Flüstern",
		WHISPER_SOUND = "Lauter Flüsterton",
		WHISPER_SOUND_DESC = "Spielt bei eingehendem Flüstern einen zusätzlichen Ton über den Master-Kanal, auch wenn Soundeffekte stumm sind.",
	},
})

local COLOR = "ffff8000"
local EVENTS = {
	"CHAT_MSG_CHANNEL", "CHAT_MSG_SAY", "CHAT_MSG_YELL",
	"CHAT_MSG_GUILD", "CHAT_MSG_OFFICER",
	"CHAT_MSG_PARTY", "CHAT_MSG_PARTY_LEADER",
	"CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER",
	"CHAT_MSG_INSTANCE_CHAT", "CHAT_MSG_INSTANCE_CHAT_LEADER",
}

local module = ns:NewModule("ChatHighlight", {
	title = L.TITLE,
	description = L.DESC,
	note = L.NOTE,
	category = "CHAT",
	defaults = {
		name = true,
		keywords = "",
		sound = true,
		whisperSound = false,
	},
	options = {
		{ type = "header", label = L.SECTION_MENTIONS },
		{ key = "name", type = "checkbox", label = L.NAME, tooltip = L.NAME_DESC },
		{
			key = "keywords",
			type = "text",
			multiline = true,
			label = L.KEYWORDS,
			tooltip = L.KEYWORDS_DESC,
			placeholder = L.KEYWORDS_HINT,
			maxLetters = 1000,
		},
		{ key = "sound", type = "checkbox", label = L.SOUND, tooltip = L.SOUND_DESC },
		{ type = "header", label = L.SECTION_WHISPERS },
		{ key = "whisperSound", type = "checkbox", label = L.WHISPER_SOUND, tooltip = L.WHISPER_SOUND_DESC },
	},
})

local Chat = ns.Chat

-- Lower-case words to look for: keywords plus the player name.
local words = {}
local playerName
local lastSoundLine

function module:UpdateWords()
	wipe(words)
	playerName = UnitName("player")
	if self.db.name and playerName then
		words[#words + 1] = playerName:lower()
	end
	Chat.ParseList(self.db.keywords, words)
end

-- Wraps every case-insensitive occurrence of word in the highlight color.
local function Colorize(text, word)
	local lower, result, position = text:lower(), {}, 1
	while true do
		local first, last = lower:find(word, position, true)
		if not first then
			break
		end
		result[#result + 1] = text:sub(position, first - 1)
		result[#result + 1] = "|c" .. COLOR .. text:sub(first, last) .. "|r"
		position = last + 1
	end
	result[#result + 1] = text:sub(position)
	return table.concat(result)
end

-- Runs once per chat frame showing the message; lineID keeps the sound to one.
local function Filter(_, _, text, author, ...)
	if type(text) ~= "string" or #words == 0 then
		return false
	end
	if type(author) == "string" and Ambiguate(author, "short") == playerName then
		return false
	end
	if not Chat.ContainsAny(text, words) then
		return false
	end
	local lineID = select(9, ...)
	if module.db.sound and lineID ~= lastSoundLine then
		lastSoundLine = lineID
		PlaySound(SOUNDKIT.RAID_WARNING, "Master")
	end
	-- Hyperlinks would break if colored inside; leave those messages as they are.
	if text:find("|H", 1, true) then
		return false
	end
	for _, word in ipairs(words) do
		text = Colorize(text, word)
	end
	return false, text, author, ...
end

function module:CHAT_MSG_WHISPER()
	if self.db.whisperSound then
		PlaySound(SOUNDKIT.TELL_MESSAGE, "Master")
	end
end
module.CHAT_MSG_BN_WHISPER = module.CHAT_MSG_WHISPER

function module:OnEnable()
	self:UpdateWords()
	Chat.AddFilters(EVENTS, Filter)
	self:RegisterEvent("CHAT_MSG_WHISPER")
	self:RegisterEvent("CHAT_MSG_BN_WHISPER")
end

function module:OnDisable()
	Chat.RemoveFilters(EVENTS, Filter)
end

function module:OnOptionChanged()
	self:UpdateWords()
end
