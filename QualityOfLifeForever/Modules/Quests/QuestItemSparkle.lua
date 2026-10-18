-- luacheck: read globals C_Timer C_CVar
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Quest item sparkle",
		NOTE = "Quest objects in the world sparkle again",
		DESC = "Turns on the sparkle on quest items and objects you still need and keeps it on, also after you pick a graphics preset. Outlines stay as they are.",
		NOTICE = "Changes the game setting outlineModeShowLootEffectWhenDisabled. Applies to objects that appear afterwards; objects already in view keep their state. Disabling restores your previous setting.",
	},
	deDE = {
		TITLE = "Questgegenstände funkeln",
		NOTE = "Quest-Objekte in der Welt funkeln wieder",
		DESC = "Schaltet das Funkeln an Questgegenständen und -objekten ein, die du noch brauchst, und hält es eingeschaltet, auch nachdem du eine Grafikvoreinstellung wählst. Umrisse bleiben unverändert.",
		NOTICE = "Ändert die Spieleinstellung outlineModeShowLootEffectWhenDisabled. Gilt für Objekte, die danach erscheinen; bereits sichtbare Objekte behalten ihren Zustand. Beim Deaktivieren wird deine vorherige Einstellung wiederhergestellt.",
	},
})

local module = ns:NewModule("QuestItemSparkle", {
	title = L.TITLE,
	description = L.DESC,
	notice = L.NOTICE,
	note = L.NOTE,
	category = "QUESTS",
})

-- Enough on its own (verified in-game): outlines may stay on.
local CVAR = "outlineModeShowLootEffectWhenDisabled"
-- Earlier versions also turned outlines off; put back the user's values.
local OLD_CVARS = { "graphicsOutlineMode", "raidGraphicsOutlineMode" }

local function RestoreOldOutline(self)
	local backup = self.db.cvarBackup
	if not backup then
		return
	end
	for _, cvar in ipairs(OLD_CVARS) do
		if backup[cvar] ~= nil then
			C_CVar.SetCVar(cvar, backup[cvar])
			backup[cvar] = nil
		end
	end
end

-- Graphics presets reset the setting; set it again right after.
function module:CVAR_UPDATE(cvar, value)
	if cvar == CVAR and tostring(value) ~= "1" then
		C_Timer.After(0, function()
			if self.enabled then
				self:SetCVar(CVAR, 1)
			end
		end)
	end
end

function module:OnEnable()
	RestoreOldOutline(self)
	self:SetCVar(CVAR, 1)
	self:RegisterEvent("CVAR_UPDATE")
end
