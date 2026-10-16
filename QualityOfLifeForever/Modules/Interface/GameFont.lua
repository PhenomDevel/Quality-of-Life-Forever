-- luacheck: read globals GetFonts GetLocale
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Game font",
		NOTE = "Replaces the standard interface font",
		DESC = "Replaces the standard interface font (Friz Quadrata) and Arial Narrow with one of the game's fonts and optionally changes its size. Decorative fonts stay as they are. Only for clients with Latin script.",
		FONT = "Font",
		FONT_DESC = "Font used instead of Friz Quadrata and Arial Narrow. Chat windows keep their font until /reload.",
		SIZE = "Size",
		SIZE_DESC = "Scales the size of the replaced fonts. Large values can make text overflow its frame.",
	},
	deDE = {
		TITLE = "Spielschrift",
		NOTE = "Ersetzt die Standardschrift der Oberfläche",
		DESC = "Ersetzt die Standardschrift der Oberfläche (Friz Quadrata) und Arial Narrow durch eine der Schriften des Spiels und ändert auf Wunsch ihre Größe. Zierschriften bleiben unverändert. Nur für Clients mit lateinischer Schrift.",
		FONT = "Schriftart",
		FONT_DESC = "Schrift, die statt Friz Quadrata und Arial Narrow verwendet wird. Chatfenster behalten ihre Schrift bis /reload.",
		SIZE = "Größe",
		SIZE_DESC = "Skaliert die Größe der ersetzten Schriften. Große Werte können Text über seinen Rahmen hinauslaufen lassen.",
	},
})

-- Fonts shipped with the client; lower-case file names for matching.
local FONTS = {
	{ file = [[Fonts\FRIZQT__.TTF]], label = "Friz Quadrata" },
	{ file = [[Fonts\ARIALN.TTF]], label = "Arial Narrow" },
	{ file = [[Fonts\skurri.ttf]], label = "Skurri" },
	{ file = [[Fonts\MORPHEUS.TTF]], label = "Morpheus" },
}
local REPLACED = { ["frizqt__.ttf"] = true, ["arialn.ttf"] = true }

-- Other scripts use their own font files, which the fonts above lack glyphs for.
local LATIN = {
	enUS = true, enGB = true, deDE = true, frFR = true,
	esES = true, esMX = true, itIT = true, ptBR = true,
}

local values = {}
for _, font in ipairs(FONTS) do
	values[#values + 1] = { value = font.file, label = font.label, font = font.file }
end

local function FormatPercent(value)
	return ("%d%%"):format(value * 100 + 0.5)
end

local module = ns:NewModule("GameFont", {
	title = L.TITLE,
	description = L.DESC,
	note = L.NOTE,
	category = "INTERFACE",
	defaults = {
		font = FONTS[2].file,
		scale = 1,
	},
	options = {
		{ key = "font", type = "dropdown", label = L.FONT, tooltip = L.FONT_DESC, values = values },
		{ key = "scale", type = "slider", label = L.SIZE, tooltip = L.SIZE_DESC, min = 0.8, max = 1.5, step = 0.05, format = FormatPercent },
	},
})

-- font object -> { file = original file, size = original size }
local originals = {}

local function FileName(path)
	local name = type(path) == "string" and path:match("([^\\/]+)$")
	return name and name:lower()
end

function module:Apply()
	if not LATIN[GetLocale()] then
		return
	end
	for _, name in ipairs(GetFonts()) do
		local font = _G[name]
		if font and font.GetFont then
			local file, size, flags = font:GetFont()
			local original = originals[font]
			if not original and size and REPLACED[FileName(file)] then
				original = { file = file, size = size }
				originals[font] = original
			end
			if original then
				font:SetFont(self.db.font, original.size * self.db.scale, flags or "")
			end
		end
	end
end

function module:Restore()
	for font, original in pairs(originals) do
		local _, _, flags = font:GetFont()
		font:SetFont(original.file, original.size, flags or "")
	end
	wipe(originals)
end

-- Load-on-demand addons bring their own font objects.
function module:ADDON_LOADED()
	self:Apply()
end

function module:OnEnable()
	self:RegisterEvent("ADDON_LOADED")
	self:Apply()
end

function module:OnDisable()
	self:Restore()
end

function module:OnOptionChanged()
	self:Apply()
end
