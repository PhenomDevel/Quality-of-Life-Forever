-- luacheck: read globals CancelDuel
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Auto-decline duels",
		DESC = "Declines all duel requests automatically.",
		NOTIFY = "Notify in chat",
		NOTIFY_DESC = "Prints a message when a duel request was declined.",
		DECLINED = "Declined duel request from %s.",
	},
	deDE = {
		TITLE = "Duelle automatisch ablehnen",
		DESC = "Lehnt alle Duellanfragen automatisch ab.",
		NOTIFY = "Im Chat benachrichtigen",
		NOTIFY_DESC = "Gibt eine Nachricht aus, wenn eine Duellanfrage abgelehnt wurde.",
		DECLINED = "Duellanfrage von %s abgelehnt.",
	},
})

local module = ns:NewModule("AutoDeclineDuels", {
	title = L.TITLE,
	description = L.DESC,
	category = "SOCIAL",
	order = 20,
	defaultEnabled = false,
	defaults = {
		notify = true,
	},
	options = {
		{
			key = "notify",
			type = "checkbox",
			label = L.NOTIFY,
			tooltip = L.NOTIFY_DESC,
		},
	},
})

function module:OnEnable()
	self:RegisterEvent("DUEL_REQUESTED")
end

function module:DUEL_REQUESTED(playerName)
	CancelDuel()
	StaticPopup_Hide("DUEL_REQUESTED")
	if self.db.notify then
		self:Print(L.DECLINED:format(tostring(playerName)))
	end
end
