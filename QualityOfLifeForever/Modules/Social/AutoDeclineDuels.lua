local _, ns = ...

local L = ns.L

local module = ns:NewModule("AutoDeclineDuels", {
	title = L.AUTO_DECLINE_DUELS_TITLE,
	description = L.AUTO_DECLINE_DUELS_DESC,
	category = "SOCIAL",
	defaultEnabled = false,
	defaults = {
		notify = true,
	},
	options = {
		{
			key = "notify",
			type = "checkbox",
			label = L.AUTO_DECLINE_DUELS_NOTIFY,
			tooltip = L.AUTO_DECLINE_DUELS_NOTIFY_DESC,
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
		self:Print(L.AUTO_DECLINE_DUELS_DECLINED:format(tostring(playerName)))
	end
end
