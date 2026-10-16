-- luacheck: read globals GetFonts GetLocale
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Game font",
		NOTE = "Replaces the standard interface font",
		DESC = "Replaces the standard interface font (Friz Quadrata) and Arial Narrow with one of the game's fonts. Decorative fonts stay as they are. Only for clients with Latin script.",
		FONT = "Font",
		FONT_DESC = "Font used instead of Friz Quadrata and Arial Narrow. Chat windows keep their font until /reload.",
	},
	deDE = {
		TITLE = "Spielschrift",
		NOTE = "Ersetzt die Standardschrift der Oberfläche",
		DESC = "Ersetzt die Standardschrift der Oberfläche (Friz Quadrata) und Arial Narrow durch eine der Schriften des Spiels. Zierschriften bleiben unverändert. Nur für Clients mit lateinischer Schrift.",
		FONT = "Schriftart",
		FONT_DESC = "Schrift, die statt Friz Quadrata und Arial Narrow verwendet wird. Chatfenster behalten ihre Schrift bis /reload.",
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
	values[#values + 1] = { value = font.file, label = font.label }
end

local module = ns:NewModule("GameFont", {
	title = L.TITLE,
	description = L.DESC,
	note = L.NOTE,
	category = "INTERFACE",
	defaults = {
		font = FONTS[2].file,
	},
	options = {
		{ key = "font", type = "dropdown", label = L.FONT, tooltip = L.FONT_DESC, values = values },
	},
})

-- font object -> original font file
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
			if not original and REPLACED[FileName(file)] then
				original = file
				originals[font] = file
			end
			if original and size and file ~= self.db.font then
				font:SetFont(self.db.font, size, flags or "")
			end
		end
	end
end

function module:Restore()
	for font, file in pairs(originals) do
		local _, size, flags = font:GetFont()
		if size then
			font:SetFont(file, size, flags or "")
		end
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
