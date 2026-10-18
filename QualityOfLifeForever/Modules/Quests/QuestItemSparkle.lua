-- luacheck: read globals C_Timer
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Quest item sparkle",
		NOTE = "Quest objects in the world sparkle again",
		DESC = "The game only shows the sparkle on quest items and objects while the graphics option \"Outline mode\" is disabled. This module keeps it disabled, also after you pick a graphics preset, and turns the sparkle on.",
		NOTICE = "Changes the graphics setting \"Outline mode\" (off) and the sparkle setting. Units are no longer outlined on mouseover. Disabling restores your previous settings.",
	},
	deDE = {
		TITLE = "Questgegenstände funkeln",
		NOTE = "Quest-Objekte in der Welt funkeln wieder",
		DESC = "Das Spiel zeigt das Funkeln an Questgegenständen und -objekten nur, solange die Grafikoption „Umrissmodus“ deaktiviert ist. Dieses Modul hält ihn deaktiviert, auch nachdem du eine Grafikvoreinstellung wählst, und schaltet das Funkeln ein.",
		NOTICE = "Ändert die Grafikeinstellung „Umrissmodus“ (aus) und die Funkel-Einstellung. Einheiten werden beim Überfahren mit der Maus nicht mehr umrandet. Beim Deaktivieren werden deine vorherigen Einstellungen wiederhergestellt.",
	},
})

local module = ns:NewModule("QuestItemSparkle", {
	title = L.TITLE,
	description = L.DESC,
	notice = L.NOTICE,
	note = L.NOTE,
	category = "QUESTS",
})

-- Outline mode keys equal their CVar names (Blizzard settings: Graphics.lua).
-- outlineModeShowLootEffectWhenDisabled draws the sparkle while outlines are
-- off (CVar named on the CurseForge page of "Forever
-- Loot Sparkles", which describes the same fix).
local CVARS = {
	graphicsOutlineMode = "0",
	raidGraphicsOutlineMode = "0",
	outlineModeShowLootEffectWhenDisabled = "1",
}

function module:Apply()
	for cvar, value in pairs(CVARS) do
		self:SetCVar(cvar, value)
	end
end

-- Graphics presets write the outline mode back; set it again right after.
function module:CVAR_UPDATE(cvar, value)
	if CVARS[cvar] and tostring(value) ~= CVARS[cvar] then
		C_Timer.After(0, function()
			if self.enabled then
				self:Apply()
			end
		end)
	end
end

function module:OnEnable()
	self:Apply()
	self:RegisterEvent("CVAR_UPDATE")
end
