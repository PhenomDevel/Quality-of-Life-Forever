-- luacheck: read globals ClosePetition DeclineGuild GetPetitionInfo GuildInviteFrame
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		SECTION_MAIN = "Decline",
		SECTION_MESSAGES = "Messages",
		TITLE = "Auto-decline guild invites",
		NOTE = "Guild invites and charters",
		DESC = "Automatically declines guild invitations and guild charter signature requests.",
		INVITES = "Guild invites",
		INVITES_DESC = "Declines guild invitations.",
		PETITIONS = "Guild charters",
		PETITIONS_DESC = "Closes guild charters offered for signing. Your own charter is never closed.",
		NOTIFY = "Notify in chat",
		NOTIFY_DESC = "Prints a message when something was declined.",
		DECLINED_INVITE = "Declined guild invite from %s (%s).",
		DECLINED_PETITION = "Declined guild charter from %s.",
	},
	deDE = {
		SECTION_MAIN = "Ablehnen",
		SECTION_MESSAGES = "Nachrichten",
		TITLE = "Gildeneinladungen automatisch ablehnen",
		NOTE = "Gildeneinladungen und Satzungen",
		DESC = "Lehnt Gildeneinladungen und Anfragen zum Unterschreiben von Gildensatzungen automatisch ab.",
		INVITES = "Gildeneinladungen",
		INVITES_DESC = "Lehnt Gildeneinladungen ab.",
		PETITIONS = "Gildensatzungen",
		PETITIONS_DESC = "Schließt zum Unterschreiben angebotene Gildensatzungen. Die eigene Satzung wird nie geschlossen.",
		NOTIFY = "Im Chat benachrichtigen",
		NOTIFY_DESC = "Gibt eine Nachricht aus, wenn etwas abgelehnt wurde.",
		DECLINED_INVITE = "Gildeneinladung von %s (%s) abgelehnt.",
		DECLINED_PETITION = "Gildensatzung von %s abgelehnt.",
	},
})

local module = ns:NewModule("AutoDeclineGuildInvites", {
	title = L.TITLE,
	description = L.DESC,
	note = L.NOTE,
	category = "SOCIAL",
	defaults = {
		invites = true,
		petitions = true,
		notify = true,
	},
	options = {
		{ type = "header", label = L.SECTION_MAIN },
		{ key = "invites", type = "checkbox", label = L.INVITES, tooltip = L.INVITES_DESC },
		{ key = "petitions", type = "checkbox", label = L.PETITIONS, tooltip = L.PETITIONS_DESC },
		{ type = "header", label = L.SECTION_MESSAGES },
		{ key = "notify", type = "checkbox", label = L.NOTIFY, tooltip = L.NOTIFY_DESC },
	},
})

function module:OnEnable()
	self:RegisterEvent("GUILD_INVITE_REQUEST")
	self:RegisterEvent("PETITION_SHOW")
end

function module:GUILD_INVITE_REQUEST(inviter, guildName)
	if not self.db.invites then
		return
	end
	DeclineGuild()
	if GuildInviteFrame then
		GuildInviteFrame:Hide()
	end
	if self.db.notify then
		self:Print(L.DECLINED_INVITE:format(tostring(inviter), tostring(guildName)))
	end
end

function module:PETITION_SHOW()
	if not self.db.petitions then
		return
	end
	local _, _, _, _, originator, isOriginator = GetPetitionInfo()
	if isOriginator then
		return
	end
	ClosePetition()
	if self.db.notify then
		self:Print(L.DECLINED_PETITION:format(tostring(originator)))
	end
end
