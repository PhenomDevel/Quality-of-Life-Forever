-- luacheck: read globals GetGameMessageInfo YELLOW_FONT_COLOR C_ChatInfo SendChatMessage IsInGroup IsInRaid LE_PARTY_CATEGORY_HOME LE_PARTY_CATEGORY_INSTANCE
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Quest progress in chat",
		DESC = "Copies quest progress messages (e.g. \"Wolf slain: 3/10\", \"Objective complete\") from the center of the screen into the chat frame, marked with the addon prefix.",
		SHARE = "Share with your party",
		SHARE_DESC = "Also sends your quest progress to party chat (instance chat in dungeon finder groups), so everyone sees where you are. Not in raids. Others don't need the addon.",
	},
	deDE = {
		TITLE = "Questfortschritt im Chat",
		DESC = "Kopiert Questfortschritt-Meldungen (z. B. „Wolf getötet: 3/10“, „Ziel abgeschlossen“) aus der Bildschirmmitte ins Chatfenster, markiert mit dem Addon-Präfix.",
		SHARE = "Mit der Gruppe teilen",
		SHARE_DESC = "Sendet deinen Questfortschritt zusätzlich in den Gruppenchat (Instanzchat in Gruppen aus der Dungeonsuche), damit alle deinen Stand sehen. Nicht in Schlachtzügen. Die anderen brauchen das Addon nicht.",
	},
})

local module = ns:NewModule("QuestProgress", {
	title = L.TITLE,
	description = L.DESC,
	category = "QUESTS",
	defaults = {
		share = false,
	},
	options = {
		{ key = "share", type = "checkbox", label = L.SHARE, tooltip = L.SHARE_DESC },
	},
})

local SendChat = C_ChatInfo and C_ChatInfo.SendChatMessage or SendChatMessage

-- Party or instance chat; nil when solo, in a raid or while addons may not
-- send chat messages (Midnight lockdown, e.g. during encounters).
local function GetShareChannel()
	if IsInRaid() then
		return nil
	end
	if C_ChatInfo and C_ChatInfo.InChatMessagingLockdown and C_ChatInfo.InChatMessagingLockdown() then
		return nil
	end
	if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
		return "INSTANCE_CHAT"
	elseif IsInGroup(LE_PARTY_CATEGORY_HOME) then
		return "PARTY"
	end
end

function module:OnEnable()
	self:RegisterEvent("UI_INFO_MESSAGE")
end

function module:UI_INFO_MESSAGE(messageType, message)
	if not message or ns.Utils.IsSecret(message) then
		return
	end
	local stringId = GetGameMessageInfo(messageType)
	if not (stringId and stringId:find("^ERR_QUEST_")) then
		return
	end
	local prefix = ("|cff%s%s|r: "):format(ns.color, ns.shortTitle)
	DEFAULT_CHAT_FRAME:AddMessage(prefix .. message, YELLOW_FONT_COLOR:GetRGB())
	if self.db.share then
		local channel = GetShareChannel()
		if channel then
			SendChat(message, channel)
		end
	end
end
