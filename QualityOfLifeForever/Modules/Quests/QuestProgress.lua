-- luacheck: read globals GetGameMessageInfo YELLOW_FONT_COLOR
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Quest progress in chat",
		DESC = "Copies quest progress messages (e.g. \"Wolf slain: 3/10\", \"Objective complete\") from the center of the screen into the chat frame.",
	},
	deDE = {
		TITLE = "Questfortschritt im Chat",
		DESC = "Kopiert Questfortschritt-Meldungen (z. B. „Wolf getötet: 3/10“, „Ziel abgeschlossen“) aus der Bildschirmmitte ins Chatfenster.",
	},
})

local module = ns:NewModule("QuestProgress", {
	title = L.TITLE,
	description = L.DESC,
	category = "QUESTS",
})

function module:OnEnable()
	self:RegisterEvent("UI_INFO_MESSAGE")
end

function module:UI_INFO_MESSAGE(messageType, message)
	if not message or ns.Utils.IsSecret(message) then
		return
	end
	local stringId = GetGameMessageInfo(messageType)
	if stringId and stringId:find("^ERR_QUEST_") then
		DEFAULT_CHAT_FRAME:AddMessage(message, YELLOW_FONT_COLOR:GetRGB())
	end
end
