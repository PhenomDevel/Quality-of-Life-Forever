local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Advanced graphics settings",
		DESC = "Graphics CVars not exposed in the game options. Adjust the sliders and press Apply. Disabling restores your previous values.",
		APPLY = "Apply",
		APPLY_DESC = "Write the values above to the game.",
		RESTORE = "Restore",
		RESTORE_DESC = "Restore the values from before the first Apply.",
		APPLIED = "Graphics settings applied.",
		RESTORED = "Graphics settings restored.",
		RANGE_HINT = "Ranges are estimates; the client may clamp values.",
		groundEffectDensity = "Ground clutter density",
		groundEffectDist = "Ground clutter distance",
		groundEffectFade = "Ground clutter fade distance",
		lodObjectFadeScale = "Object fade scale",
		lodObjectCullSize = "Object cull size (lower = more objects)",
		terrainLodDist = "Terrain detail distance",
		ResampleAlwaysSharpen = "Always sharpen when resampling",
		reflectionMode = "Water reflections (0-3)",
		weatherDensity = "Weather density (0-3)",
	},
	deDE = {
		TITLE = "Erweiterte Grafikeinstellungen",
		DESC = "Grafik-CVars, die nicht in den Spieloptionen stehen. Regler einstellen und „Anwenden“ drücken. Beim Deaktivieren werden die vorherigen Werte wiederhergestellt.",
		APPLY = "Anwenden",
		APPLY_DESC = "Schreibt die obigen Werte ins Spiel.",
		RESTORE = "Wiederherstellen",
		RESTORE_DESC = "Stellt die Werte von vor dem ersten „Anwenden“ wieder her.",
		APPLIED = "Grafikeinstellungen angewendet.",
		RESTORED = "Grafikeinstellungen wiederhergestellt.",
		RANGE_HINT = "Wertebereiche sind geschätzt; der Client kann Werte begrenzen.",
		groundEffectDensity = "Bodendetail-Dichte",
		groundEffectDist = "Bodendetail-Sichtweite",
		groundEffectFade = "Bodendetail-Ausblendweite",
		lodObjectFadeScale = "Objekt-Ausblendskalierung",
		lodObjectCullSize = "Objekt-Cull-Größe (kleiner = mehr Objekte)",
		terrainLodDist = "Gelände-Detailweite",
		ResampleAlwaysSharpen = "Beim Resampling immer schärfen",
		reflectionMode = "Wasserspiegelungen (0-3)",
		weatherDensity = "Wetterdichte (0-3)",
	},
})

-- CVar name doubles as option key and locale key. Ranges are estimates.
local CVARS = {
	{ cvar = "groundEffectDensity", default = 256, min = 16, max = 256, step = 8 },
	{ cvar = "groundEffectDist", default = 500, min = 50, max = 500, step = 10 },
	{ cvar = "groundEffectFade", default = 370, min = 0, max = 500, step = 10 },
	{ cvar = "lodObjectFadeScale", default = 200, min = 50, max = 200, step = 10 },
	{ cvar = "lodObjectCullSize", default = 8, min = 0, max = 35, step = 1 },
	{ cvar = "terrainLodDist", default = 1000, min = 200, max = 1000, step = 50 },
	{ cvar = "ResampleAlwaysSharpen", default = true },
	{ cvar = "reflectionMode", default = 3, min = 0, max = 3, step = 1 },
	{ cvar = "weatherDensity", default = 3, min = 0, max = 3, step = 1 },
}

local defaults, options = {}, {}
for _, entry in ipairs(CVARS) do
	defaults[entry.cvar] = entry.default
	options[#options + 1] = {
		key = entry.cvar,
		type = type(entry.default) == "boolean" and "checkbox" or "slider",
		label = L[entry.cvar],
		tooltip = ("CVar %s\n%s"):format(entry.cvar, L.RANGE_HINT),
		min = entry.min,
		max = entry.max,
		step = entry.step,
	}
end

options[#options + 1] = {
	type = "button",
	label = L.APPLY,
	buttonText = L.APPLY,
	tooltip = L.APPLY_DESC,
	onClick = function(self)
		self:Apply()
	end,
}
options[#options + 1] = {
	type = "button",
	label = L.RESTORE,
	buttonText = L.RESTORE,
	tooltip = L.RESTORE_DESC,
	onClick = function(self)
		self:RestoreCVars()
		self:Print(L.RESTORED)
	end,
}

local module = ns:NewModule("GraphicsTweaks", {
	title = L.TITLE,
	description = L.DESC,
	category = "GRAPHICS",
	defaults = defaults,
	options = options,
})

function module:Apply()
	for _, entry in ipairs(CVARS) do
		self:SetCVar(entry.cvar, self.db[entry.cvar])
	end
	self:Print(L.APPLIED)
end
