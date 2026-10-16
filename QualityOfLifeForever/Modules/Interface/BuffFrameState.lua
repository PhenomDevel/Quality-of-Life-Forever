-- luacheck: read globals BuffFrame InCombatLockdown
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Remember buff bar state",
		NOTE = "Keeps the buffs collapsed or expanded",
		DESC = "Remembers whether you collapsed or expanded the buffs with the arrow next to the buff bar and restores it after logging in or reloading. Turns on Blizzard's collapse arrow.",
	},
	deDE = {
		TITLE = "Buffleisten-Zustand merken",
		NOTE = "Buffs bleiben ein- bzw. ausgeklappt",
		DESC = "Merkt sich, ob du die Buffs mit dem Pfeil neben der Buffleiste ein- oder ausgeklappt hast, und stellt das nach dem Einloggen oder Neuladen wieder her. Schaltet Blizzards Einklapp-Pfeil ein.",
	},
})

local module = ns:NewModule("BuffFrameState", {
	title = L.TITLE,
	description = L.DESC,
	note = L.NOTE,
	category = "INTERFACE",
})

-- Only called when the state differs, so the default (expanded) never
-- touches Blizzard's buff frame. Out of combat to keep taint away from it.
function module:Restore()
	if InCombatLockdown() then
		self:RegisterEvent("PLAYER_REGEN_ENABLED", self.Restore)
		return
	end
	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	if BuffFrame.isExpanded ~= self.db.expanded then
		BuffFrame:SetBuffsExpandedState(self.db.expanded)
	end
end

function module:OnEnable()
	if not BuffFrame or not BuffFrame.SetBuffsExpandedState then
		return
	end
	self:SetCVar("collapseExpandBuffs", true)
	-- First enable: keep whatever is shown right now.
	if self.db.expanded == nil then
		self.db.expanded = BuffFrame.isExpanded ~= false
	end
	self:SecureHook(BuffFrame, "SetBuffsExpandedState", function(_, _, expanded)
		self.db.expanded = expanded and true or false
	end)
	self:Restore()
end
