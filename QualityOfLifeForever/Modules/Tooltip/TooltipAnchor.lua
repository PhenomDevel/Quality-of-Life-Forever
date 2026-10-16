local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Anchor tooltip to cursor",
		DESC = "Shows tooltips that use the default position at the mouse cursor instead.",
		ANCHOR = "Position",
		ANCHOR_DESC = "Where the tooltip is placed relative to the cursor.",
		ANCHOR_CURSOR = "At cursor (follows)",
		ANCHOR_CURSOR_RIGHT = "Right of cursor",
		ANCHOR_CURSOR_LEFT = "Left of cursor",
	},
	deDE = {
		TITLE = "Tooltip an der Maus",
		DESC = "Zeigt Tooltips mit Standardposition stattdessen am Mauszeiger an.",
		ANCHOR = "Position",
		ANCHOR_DESC = "Wo der Tooltip relativ zum Mauszeiger erscheint.",
		ANCHOR_CURSOR = "Am Mauszeiger (folgt)",
		ANCHOR_CURSOR_RIGHT = "Rechts vom Mauszeiger",
		ANCHOR_CURSOR_LEFT = "Links vom Mauszeiger",
	},
})

local module = ns:NewModule("TooltipAnchor", {
	title = L.TITLE,
	description = L.DESC,
	category = "TOOLTIP",
	defaults = {
		anchor = "ANCHOR_CURSOR",
	},
	options = {
		{
			key = "anchor",
			type = "dropdown",
			label = L.ANCHOR,
			tooltip = L.ANCHOR_DESC,
			values = {
				{ value = "ANCHOR_CURSOR", label = L.ANCHOR_CURSOR },
				{ value = "ANCHOR_CURSOR_RIGHT", label = L.ANCHOR_CURSOR_RIGHT },
				{ value = "ANCHOR_CURSOR_LEFT", label = L.ANCHOR_CURSOR_LEFT },
			},
		},
	},
})

function module:OnEnable()
	self:SecureHook("GameTooltip_SetDefaultAnchor", self.OnSetDefaultAnchor)
end

-- Post-hook: re-anchor after Blizzard placed the tooltip at its default spot.
function module:OnSetDefaultAnchor(tooltip, parent)
	tooltip:SetOwner(parent, self.db.anchor)
end
