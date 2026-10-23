-- luacheck: read globals PlayerFrame TargetFrame PlayerFrame_GetHealthBar PlayerFrame_GetManaBar
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Health & mana text size",
		NOTE = "Player and target frame",
		DESC = "Changes the text size of the health and mana numbers on the player and target unit frames. Applies to the numbers and percentages the game shows there (see {Status Text} in the game's interface settings).",
		SECTION_PLAYER = "Player",
		SECTION_TARGET = "Target",
		HEALTH = "Health",
		HEALTH_DESC = "Text size of the health numbers in pixels.",
		MANA = "Mana",
		MANA_DESC = "Text size of the mana (energy, rage) numbers in pixels.",
	},
	deDE = {
		TITLE = "Textgröße Leben & Mana",
		NOTE = "Spieler- und Zielrahmen",
		DESC = "Ändert die Textgröße der Lebens- und Manazahlen im Spieler- und Zielrahmen. Gilt für die Zahlen und Prozente, die das Spiel dort anzeigt (siehe {Statustext} in den Interface-Einstellungen des Spiels).",
		SECTION_PLAYER = "Spieler",
		SECTION_TARGET = "Ziel",
		HEALTH = "Leben",
		HEALTH_DESC = "Textgröße der Lebenszahlen in Pixeln.",
		MANA = "Mana",
		MANA_DESC = "Textgröße der Manazahlen (Energie, Wut) in Pixeln.",
	},
})

local function FormatPixels(value)
	return ("%d px"):format(value)
end

local module = ns:NewModule("UnitFrameText", {
	title = L.TITLE,
	description = L.DESC,
	note = L.NOTE,
	category = "CHARACTER",
	defaults = {
		playerHealth = 12,
		playerMana = 12,
		targetHealth = 12,
		targetMana = 12,
	},
	options = {
		{ type = "header", label = L.SECTION_PLAYER },
		{ key = "playerHealth", type = "slider", label = L.HEALTH, tooltip = L.HEALTH_DESC, min = 6, max = 24, step = 1, format = FormatPixels },
		{ key = "playerMana", type = "slider", label = L.MANA, tooltip = L.MANA_DESC, min = 6, max = 24, step = 1, format = FormatPixels },
		{ type = "header", label = L.SECTION_TARGET },
		{ key = "targetHealth", type = "slider", label = L.HEALTH, tooltip = L.HEALTH_DESC, min = 6, max = 24, step = 1, format = FormatPixels },
		{ key = "targetMana", type = "slider", label = L.MANA, tooltip = L.MANA_DESC, min = 6, max = 24, step = 1, format = FormatPixels },
	},
})

-- Follows a chain of child keys from `frame`; nil if one is missing.
local function Walk(frame, ...)
	for i = 1, select("#", ...) do
		if not frame then
			return nil
		end
		frame = frame[select(i, ...)]
	end
	return frame
end

-- The status bars of the mainline unit frames; the Get* helpers first, the
-- frame paths as a fallback.
local BARS = {
	playerHealth = function()
		return PlayerFrame_GetHealthBar and PlayerFrame_GetHealthBar()
			or Walk(PlayerFrame, "PlayerFrameContent", "PlayerFrameContentMain", "HealthBarsContainer", "HealthBar")
	end,
	playerMana = function()
		return PlayerFrame_GetManaBar and PlayerFrame_GetManaBar()
			or Walk(PlayerFrame, "PlayerFrameContent", "PlayerFrameContentMain", "ManaBarArea", "ManaBar")
	end,
	targetHealth = function()
		return Walk(TargetFrame, "TargetFrameContent", "TargetFrameContentMain", "HealthBarsContainer", "HealthBar")
			or Walk(TargetFrame, "healthbar")
	end,
	targetMana = function()
		return Walk(TargetFrame, "TargetFrameContent", "TargetFrameContentMain", "ManaBar")
			or Walk(TargetFrame, "manabar")
	end,
}

-- A bar shows its value centered (TextString) or split (LeftText/RightText).
local TEXT_KEYS = { "TextString", "LeftText", "RightText" }

-- Original font of every changed FontString, to restore on disable.
local originals = {}

local function ForEachText(key, callback)
	local bar = BARS[key]()
	if not bar then
		module:Debug("bar not found:", key)
		return
	end
	for _, textKey in ipairs(TEXT_KEYS) do
		local text = bar[textKey]
		if text and text.SetFont then
			callback(text)
		end
	end
end

function module:Apply()
	for key in pairs(BARS) do
		local size = self.db[key]
		ForEachText(key, function(text)
			if not originals[text] then
				originals[text] = { text:GetFont() }
			end
			local file, _, flags = unpack(originals[text])
			text:SetFont(file, size, flags or "")
		end)
	end
end

function module:OnOptionChanged()
	self:Apply()
end

function module:OnEnable()
	-- Re-applied on world entry in case Blizzard reset the fonts after a
	-- loading screen or vehicle swap.
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "Apply")
	self:Apply()
end

function module:OnDisable()
	for text, font in pairs(originals) do
		text:SetFont(font[1], font[2], font[3] or "")
	end
	wipe(originals)
end
