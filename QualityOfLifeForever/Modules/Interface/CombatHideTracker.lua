-- luacheck: read globals ObjectiveTrackerFrame InCombatLockdown
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Hide objective tracker in combat",
		NOTE = "Quest tracker invisible while fighting",
		DESC = "Makes the quest tracker invisible during combat and shows it again afterwards. It stays clickable; only its look changes.",
	},
	deDE = {
		TITLE = "Questverfolgung im Kampf ausblenden",
		NOTE = "Questverfolgung im Kampf unsichtbar",
		DESC = "Macht die Questverfolgung während des Kampfes unsichtbar und zeigt sie danach wieder. Sie bleibt anklickbar; nur die Darstellung ändert sich.",
	},
})

local module = ns:NewModule("CombatHideTracker", {
	title = L.TITLE,
	description = L.DESC,
	note = L.NOTE,
	category = "INTERFACE",
})

-- Alpha only: the tracker holds secure quest item buttons and can't be
-- hidden in combat.
local function SetTrackerHidden(hidden)
	if ObjectiveTrackerFrame then
		ObjectiveTrackerFrame:SetAlpha(hidden and 0 or 1)
	end
end

function module:OnEnable()
	self:RegisterEvent("PLAYER_REGEN_DISABLED", function()
		SetTrackerHidden(true)
	end)
	self:RegisterEvent("PLAYER_REGEN_ENABLED", function()
		SetTrackerHidden(false)
	end)
	SetTrackerHidden(InCombatLockdown())
end

function module:OnDisable()
	SetTrackerHidden(false)
end
