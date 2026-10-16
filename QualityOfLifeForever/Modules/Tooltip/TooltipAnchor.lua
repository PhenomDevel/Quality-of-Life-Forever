-- luacheck: read globals ItemRefTooltip ShoppingTooltip1 ShoppingTooltip2 TOOLTIP_DEFAULT_BACKGROUND_COLOR
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Tooltip tweaks",
		DESC = "Position, scale and background transparency of tooltips.",
		ANCHOR = "Position",
		ANCHOR_DESC = "Where tooltips that use the default position are placed.",
		ANCHOR_DEFAULT = "Default (Blizzard)",
		ANCHOR_CURSOR = "At cursor (follows)",
		ANCHOR_CURSOR_RIGHT = "Right of cursor",
		ANCHOR_CURSOR_LEFT = "Left of cursor",
		SCALE = "Scale",
		SCALE_DESC = "Size of the game, item link and comparison tooltips (text included).",
		ALPHA = "Background opacity",
		ALPHA_DESC = "Opacity of the tooltip background; the border and text stay opaque.",
	},
	deDE = {
		TITLE = "Tooltip-Anpassungen",
		DESC = "Position, Größe und Hintergrund-Transparenz von Tooltips.",
		ANCHOR = "Position",
		ANCHOR_DESC = "Wo Tooltips mit Standardposition erscheinen.",
		ANCHOR_DEFAULT = "Standard (Blizzard)",
		ANCHOR_CURSOR = "Am Mauszeiger (folgt)",
		ANCHOR_CURSOR_RIGHT = "Rechts vom Mauszeiger",
		ANCHOR_CURSOR_LEFT = "Links vom Mauszeiger",
		SCALE = "Größe",
		SCALE_DESC = "Größe von Spiel-, Gegenstandslink- und Vergleichstooltips (inklusive Text).",
		ALPHA = "Hintergrund-Deckkraft",
		ALPHA_DESC = "Deckkraft des Tooltip-Hintergrunds; Rahmen und Text bleiben deckend.",
	},
})

local ANCHOR_DEFAULT = "DEFAULT"

local function FormatPercent(value)
	return ("%d%%"):format(value * 100 + 0.5)
end

-- Module name is kept for SavedVariables compatibility (it started as anchor-only).
local module = ns:NewModule("TooltipAnchor", {
	title = L.TITLE,
	description = L.DESC,
	category = "TOOLTIP",
	defaults = {
		anchor = "ANCHOR_CURSOR",
		scale = 1,
		alpha = 1,
	},
	options = {
		{
			key = "anchor",
			type = "dropdown",
			label = L.ANCHOR,
			tooltip = L.ANCHOR_DESC,
			values = {
				{ value = ANCHOR_DEFAULT, label = L.ANCHOR_DEFAULT },
				{ value = "ANCHOR_CURSOR", label = L.ANCHOR_CURSOR },
				{ value = "ANCHOR_CURSOR_RIGHT", label = L.ANCHOR_CURSOR_RIGHT },
				{ value = "ANCHOR_CURSOR_LEFT", label = L.ANCHOR_CURSOR_LEFT },
			},
		},
		{ key = "scale", type = "slider", label = L.SCALE, tooltip = L.SCALE_DESC, min = 0.5, max = 2, step = 0.05, format = FormatPercent },
		{ key = "alpha", type = "slider", label = L.ALPHA, tooltip = L.ALPHA_DESC, min = 0, max = 1, step = 0.05, format = FormatPercent },
	},
})

-- Tooltips that get scaled; created at load time by Blizzard_GameTooltip/ItemRef.
local function GetScaledTooltips()
	return { GameTooltip, ItemRefTooltip, ShoppingTooltip1, ShoppingTooltip2 }
end

local function SetBackgroundAlpha(tooltip, alpha)
	if tooltip and tooltip.NineSlice then
		local r, g, b = TOOLTIP_DEFAULT_BACKGROUND_COLOR:GetRGB()
		tooltip.NineSlice:SetCenterColor(r, g, b, alpha)
	end
end

function module:Apply(scale, alpha)
	for _, tooltip in ipairs(GetScaledTooltips()) do
		if tooltip then
			tooltip:SetScale(scale)
			SetBackgroundAlpha(tooltip, alpha)
		end
	end
end

function module:OnEnable()
	self:SecureHook("GameTooltip_SetDefaultAnchor", self.OnSetDefaultAnchor)
	-- Blizzard resets the background on every hide/style change.
	self:SecureHook("SharedTooltip_SetBackdropStyle", self.OnSetBackdropStyle)
	self:Apply(self.db.scale, self.db.alpha)
end

function module:OnDisable()
	self:Apply(1, 1)
end

function module:OnOptionChanged()
	self:Apply(self.db.scale, self.db.alpha)
end

function module:OnSetDefaultAnchor(tooltip, parent)
	if self.db.anchor ~= ANCHOR_DEFAULT then
		tooltip:SetOwner(parent, self.db.anchor)
	end
end

function module:OnSetBackdropStyle(tooltip)
	SetBackgroundAlpha(tooltip, self.db.alpha)
end
