-- luacheck: read globals AcceptGroup C_BattleNet C_FriendList IsGuildMember StaticPopup_FindVisible WillAcceptInviteRemoveQueues
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		SECTION_MAIN = "Accept from",
		SECTION_MESSAGES = "Messages",
		TITLE = "Auto-accept: group invites",
		NOTE = "From friends and guild members",
		DESC = "Automatically accepts group invites from friends and guild members. Role-check invites and invites that would remove you from a queue are left to you.",
		FRIENDS = "Friends",
		FRIENDS_DESC = "Battle.net and character friends.",
		GUILD = "Guild members",
		GUILD_DESC = "Members of your guild.",
		NOTIFY = "Notify in chat",
		NOTIFY_DESC = "Print a message when an invite was accepted.",
		ACCEPTED = "Accepted group invite from %s.",
	},
	deDE = {
		SECTION_MAIN = "Annehmen von",
		SECTION_MESSAGES = "Nachrichten",
		TITLE = "Auto-Annahme: Einladungen",
		NOTE = "Gruppeneinladungen von Freunden und Gilde",
		DESC = "Nimmt Gruppeneinladungen von Freunden und Gildenmitgliedern automatisch an. Einladungen mit Rollenauswahl und solche, die dich aus einer Warteschlange entfernen würden, bleiben dir überlassen.",
		FRIENDS = "Freunde",
		FRIENDS_DESC = "Battle.net- und Charakterfreunde.",
		GUILD = "Gildenmitglieder",
		GUILD_DESC = "Mitglieder deiner Gilde.",
		NOTIFY = "Im Chat benachrichtigen",
		NOTIFY_DESC = "Gibt eine Nachricht aus, wenn eine Einladung angenommen wurde.",
		ACCEPTED = "Gruppeneinladung von %s angenommen.",
	},
})

local module = ns:NewModule("AutoAcceptGroupInvites", {
	title = L.TITLE,
	description = L.DESC,
	note = L.NOTE,
	category = "SOCIAL",
	defaults = {
		friends = true,
		guild = true,
		notify = true,
	},
	options = {
		{ type = "header", label = L.SECTION_MAIN },
		{ key = "friends", type = "checkbox", label = L.FRIENDS, tooltip = L.FRIENDS_DESC },
		{ key = "guild", type = "checkbox", label = L.GUILD, tooltip = L.GUILD_DESC },
		{ type = "header", label = L.SECTION_MESSAGES },
		{ key = "notify", type = "checkbox", label = L.NOTIFY, tooltip = L.NOTIFY_DESC },
	},
})

function module:IsTrusted(guid)
	if not guid then
		return false
	end
	if self.db.friends and (C_BattleNet.GetAccountInfoByGUID(guid) or C_FriendList.IsFriend(guid)) then
		return true
	end
	return self.db.guild and IsGuildMember(guid) or false
end

function module:OnEnable()
	self:RegisterEvent("PARTY_INVITE_REQUEST")
end

function module:PARTY_INVITE_REQUEST(inviter, tank, healer, damage, _, _, inviterGUID, questSessionActive)
	-- Role checks and quest sessions use their own dialogs.
	if tank or healer or damage or questSessionActive then
		return
	end
	if WillAcceptInviteRemoveQueues() or not self:IsTrusted(inviterGUID) then
		return
	end
	-- Next frame: Blizzard's PARTY_INVITE popup must exist first, otherwise it
	-- would still show up after we accepted.
	C_Timer.After(0, function()
		if not self.enabled then
			return
		end
		AcceptGroup()
		-- The popup calls DeclineGroup() on hide unless it was accepted through it.
		local dialog = StaticPopup_FindVisible("PARTY_INVITE")
		if dialog then
			dialog.inviteAccepted = 1
		end
		StaticPopup_Hide("PARTY_INVITE")
		if self.db.notify then
			self:Print(L.ACCEPTED:format(tostring(inviter)))
		end
	end)
end
