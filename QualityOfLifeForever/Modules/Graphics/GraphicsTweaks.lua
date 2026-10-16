local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Advanced graphics",
		NOTE = "Not in the game options · higher values cost performance",
		DESC = "Graphics CVars not exposed in the game options. Adjust the sliders and press Apply. Disabling restores your previous values.\n\nHigher values than the game's presets can noticeably lower your frame rate.",
		APPLY = "Apply",
		APPLY_DESC = "Write the values above to the game.",
		RESTORE = "Restore",
		RESTORE_DESC = "Restore the values from before the first Apply.",
		APPLIED = "Graphics settings applied.",
		RESTORED = "Graphics settings restored.",
		RANGE = "CVar %s · default %s · range %s–%s",
		UNBOUNDED = "CVar %s · default %s · no engine limit (slider %s–%s)",
		groundEffectDensity = "Ground clutter density",
		groundEffectDensity_DESC = "How densely grass, small plants and rocks are placed on the ground.",
		groundEffectDist = "Ground clutter distance",
		groundEffectDist_DESC = "Distance up to which ground clutter is drawn.",
		groundEffectFade = "Clutter fade distance",
		groundEffectFade_DESC = "Distance at which ground clutter starts to fade out. Values above the clutter distance have no visible effect.",
		lodObjectFadeScale = "Object view distance",
		lodObjectFadeScale_DESC = "Scales the distance at which objects (trees, buildings, props) fade in and switch detail levels. 100 = standard, higher = visible further away.",
		lodObjectCullSize = "Object cull size",
		lodObjectCullSize_DESC = "Objects that appear smaller than this on screen are not drawn. Lower = more small objects in the distance.",
		terrainLodDist = "Terrain detail distance",
		terrainLodDist_DESC = "Distance up to which terrain is drawn at full detail; beyond it a coarser version is used.",
		ResampleAlwaysSharpen = "Always sharpen",
		ResampleAlwaysSharpen_DESC = "Applies sharpening whenever the image is resampled to the screen resolution.",
		reflectionMode = "Water reflections",
		reflectionMode_DESC = "Detail level of reflections on water surfaces. Higher = more of the world is reflected.",
		weatherDensity = "Weather density",
		weatherDensity_DESC = "Amount of weather particles such as rain, snow and sand.",
	},
	deDE = {
		TITLE = "Erweiterte Grafik",
		NOTE = "Nicht in den Spieloptionen · höhere Werte kosten Leistung",
		DESC = "Grafik-CVars, die nicht in den Spieloptionen stehen. Regler einstellen und „Anwenden“ drücken. Beim Deaktivieren werden die vorherigen Werte wiederhergestellt.\n\nWerte über den Voreinstellungen des Spiels können die Bildrate spürbar senken.",
		APPLY = "Anwenden",
		APPLY_DESC = "Schreibt die obigen Werte ins Spiel.",
		RESTORE = "Wiederherstellen",
		RESTORE_DESC = "Stellt die Werte von vor dem ersten „Anwenden“ wieder her.",
		APPLIED = "Grafikeinstellungen angewendet.",
		RESTORED = "Grafikeinstellungen wiederhergestellt.",
		RANGE = "CVar %s · Standard %s · Bereich %s–%s",
		UNBOUNDED = "CVar %s · Standard %s · keine Engine-Grenze (Regler %s–%s)",
		groundEffectDensity = "Bodendetail-Dichte",
		groundEffectDensity_DESC = "Wie dicht Gras, kleine Pflanzen und Steine auf dem Boden platziert werden.",
		groundEffectDist = "Bodendetail-Sichtweite",
		groundEffectDist_DESC = "Entfernung, bis zu der Bodendetails dargestellt werden.",
		groundEffectFade = "Bodendetail-Ausblendung",
		groundEffectFade_DESC = "Entfernung, ab der Bodendetails ausgeblendet werden. Werte über der Bodendetail-Sichtweite haben keinen sichtbaren Effekt.",
		lodObjectFadeScale = "Objekt-Sichtweite",
		lodObjectFadeScale_DESC = "Skaliert die Entfernung, ab der Objekte (Bäume, Gebäude, Deko) eingeblendet werden und ihre Detailstufe wechseln. 100 = Standard, höher = weiter sichtbar.",
		lodObjectCullSize = "Objekt-Mindestgröße",
		lodObjectCullSize_DESC = "Objekte, die auf dem Bildschirm kleiner erscheinen, werden nicht gezeichnet. Kleiner = mehr kleine Objekte in der Ferne.",
		terrainLodDist = "Gelände-Detailweite",
		terrainLodDist_DESC = "Entfernung, bis zu der das Gelände in voller Detailstufe dargestellt wird; dahinter wird eine gröbere Version verwendet.",
		ResampleAlwaysSharpen = "Immer schärfen",
		ResampleAlwaysSharpen_DESC = "Schärft das Bild immer, wenn es auf die Bildschirmauflösung umgerechnet wird.",
		reflectionMode = "Wasserspiegelungen",
		reflectionMode_DESC = "Detailstufe der Spiegelungen auf Wasseroberflächen. Höher = mehr von der Welt wird gespiegelt.",
		weatherDensity = "Wetterdichte",
		weatherDensity_DESC = "Menge der Wetterpartikel wie Regen, Schnee und Sand.",
	},
})

-- CVar name doubles as option key and locale key. `engineDefault`, `min` and
-- `max` were measured with /qol cvarinfo on Forever 1.60.1 (70425); the engine
-- silently rejects values outside min..max. `unbounded` CVars accept any value,
-- their slider range is our choice. lodObjectFadeScale (engine max 5000) and
-- terrainLodDist are limited to 1000 for performance. `default` is the preset
-- applied by Apply.
local CVARS = {
	{ cvar = "groundEffectDensity", default = 256, engineDefault = 16, min = 16, max = 256, step = 8 },
	{ cvar = "groundEffectDist", default = 500, engineDefault = 70, min = 40, max = 500, step = 10 },
	{ cvar = "groundEffectFade", default = 370, engineDefault = 70, min = 0, max = 500, step = 10, unbounded = true },
	{ cvar = "lodObjectFadeScale", default = 200, engineDefault = 100, min = 50, max = 1000, step = 50 },
	{ cvar = "lodObjectCullSize", default = 8, engineDefault = 15, min = 1, max = 100, step = 1 },
	{ cvar = "terrainLodDist", default = 1000, engineDefault = 400, min = 100, max = 1000, step = 50, unbounded = true },
	{ cvar = "ResampleAlwaysSharpen", default = true, engineDefault = 0 },
	{ cvar = "reflectionMode", default = 3, engineDefault = 3, min = 0, max = 4, step = 1 },
	{ cvar = "weatherDensity", default = 3, engineDefault = 2, min = 0, max = 3, step = 1 },
}

local function BuildTooltip(entry)
	local limits
	if entry.min then
		limits = (entry.unbounded and L.UNBOUNDED or L.RANGE):format(entry.cvar, entry.engineDefault, entry.min, entry.max)
	else
		limits = L.RANGE:format(entry.cvar, entry.engineDefault, 0, 1)
	end
	return L[entry.cvar .. "_DESC"] .. "\n\n" .. limits
end

local defaults, options = {}, {}
for _, entry in ipairs(CVARS) do
	defaults[entry.cvar] = entry.default
	options[#options + 1] = {
		key = entry.cvar,
		type = type(entry.default) == "boolean" and "checkbox" or "slider",
		label = L[entry.cvar],
		tooltip = BuildTooltip(entry),
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
	note = L.NOTE,
	category = "GRAPHICS",
	defaults = defaults,
	options = options,
})

function module:Apply()
	for _, entry in ipairs(CVARS) do
		local value = self.db[entry.cvar]
		-- Saved values from before a max was lowered.
		if entry.max and value > entry.max then
			value = entry.max
			self:SetOption(entry.cvar, value)
		end
		self:SetCVar(entry.cvar, value)
	end
	self:Print(L.APPLIED)
end
