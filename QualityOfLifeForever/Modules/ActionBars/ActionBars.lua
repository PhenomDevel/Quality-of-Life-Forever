-- luacheck: read globals InCombatLockdown
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Action bars",
		NOTE = "Tweaks for the action buttons",
		DESC = "Adjustments for the buttons of the action bars.",
		COOLDOWN_TEXT = "Cooldown text",
		POSITION = "Position",
		POSITION_DESC = "Where on the button the remaining cooldown time is shown. Changes wait until you leave combat.",
		OFFSET_X = "Horizontal offset",
		OFFSET_X_DESC = "Moves the text to the right (positive) or left (negative), in pixels.",
		OFFSET_Y = "Vertical offset",
		OFFSET_Y_DESC = "Moves the text up (positive) or down (negative), in pixels.",
		TOPLEFT = "Top left",
		TOP = "Top",
		TOPRIGHT = "Top right",
		LEFT = "Left",
		CENTER = "Center",
		RIGHT = "Right",
		BOTTOMLEFT = "Bottom left",
		BOTTOM = "Bottom",
		BOTTOMRIGHT = "Bottom right",
	},
	deDE = {
		TITLE = "Aktionsleisten",
		NOTE = "Anpassungen der Aktionstasten",
		DESC = "Anpassungen für die Tasten der Aktionsleisten.",
		COOLDOWN_TEXT = "Abklingzeit-Text",
		POSITION = "Position",
		POSITION_DESC = "Wo auf der Taste die verbleibende Abklingzeit angezeigt wird. Änderungen warten, bis du den Kampf verlässt.",
		OFFSET_X = "Horizontaler Versatz",
		OFFSET_X_DESC = "Verschiebt den Text nach rechts (positiv) oder links (negativ), in Pixeln.",
		OFFSET_Y = "Vertikaler Versatz",
		OFFSET_Y_DESC = "Verschiebt den Text nach oben (positiv) oder unten (negativ), in Pixeln.",
		TOPLEFT = "Oben links",
		TOP = "Oben",
		TOPRIGHT = "Oben rechts",
		LEFT = "Links",
		CENTER = "Mitte",
		RIGHT = "Rechts",
		BOTTOMLEFT = "Unten links",
		BOTTOM = "Unten",
		BOTTOMRIGHT = "Unten rechts",
	},
})

local POSITIONS = {
	"TOPLEFT", "TOP", "TOPRIGHT",
	"LEFT", "CENTER", "RIGHT",
	"BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT",
}

local positionValues = {}
for _, point in ipairs(POSITIONS) do
	positionValues[#positionValues + 1] = { value = point, label = L[point] }
end

local function FormatPixels(value)
	return ("%d px"):format(value)
end

local module = ns:NewModule("ActionBars", {
	title = L.TITLE,
	description = L.DESC,
	note = L.NOTE,
	category = "ACTION_BARS",
	defaults = {
		cooldownPosition = "CENTER",
		cooldownX = 0,
		cooldownY = 0,
	},
	options = {
		{ type = "header", label = L.COOLDOWN_TEXT },
		{ key = "cooldownPosition", type = "dropdown", label = L.POSITION, tooltip = L.POSITION_DESC, values = positionValues },
		{ key = "cooldownX", type = "slider", label = L.OFFSET_X, tooltip = L.OFFSET_X_DESC, min = -20, max = 20, step = 1, format = FormatPixels },
		{ key = "cooldownY", type = "slider", label = L.OFFSET_Y, tooltip = L.OFFSET_Y_DESC, min = -20, max = 20, step = 1, format = FormatPixels },
	},
})

-- MainActionBar is the Midnight name, MainMenuBar the older one.
local ACTION_BARS = {
	"MainActionBar", "MainMenuBar", "MultiBarBottomLeft", "MultiBarBottomRight",
	"MultiBarRight", "MultiBarLeft", "MultiBar5", "MultiBar6", "MultiBar7",
}

-- countdown FontString -> its original anchors, to restore on disable
local originals = {}

local function EachCountdown(callback)
	for _, name in ipairs(ACTION_BARS) do
		local bar = _G[name]
		if bar and bar.actionButtons then
			for _, button in ipairs(bar.actionButtons) do
				local cooldown = button.cooldown
				local text = cooldown and cooldown.GetCountdownFontString and cooldown:GetCountdownFontString()
				if text then
					callback(text, cooldown)
				end
			end
		end
	end
end

local function Place(text, cooldown)
	if not originals[text] then
		local points = {}
		for i = 1, text:GetNumPoints() do
			points[i] = { text:GetPoint(i) }
		end
		originals[text] = points
	end
	local db = module.db
	text:ClearAllPoints()
	text:SetPoint(db.cooldownPosition, cooldown, db.cooldownPosition, db.cooldownX, db.cooldownY)
end

local function Restore()
	for text, points in pairs(originals) do
		text:ClearAllPoints()
		for _, point in ipairs(points) do
			text:SetPoint(unpack(point))
		end
	end
	wipe(originals)
end

-- Action buttons are secure; their regions are only touched out of combat.
function module:Update()
	if InCombatLockdown() then
		self:RegisterEvent("PLAYER_REGEN_ENABLED", "Update")
		return
	end
	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	EachCountdown(Place)
end

function module:OnEnable()
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "Update")
	self:Update()
end

-- Module events are unregistered on disable, so a restore that has to wait
-- for the end of combat goes through the addon's own event frame.
local restorePending, restoreHooked

local function RestoreAfterCombat()
	if restorePending and not module.enabled then
		Restore()
	end
	restorePending = false
end

function module:OnDisable()
	if InCombatLockdown() then
		restorePending = true
		if not restoreHooked then
			restoreHooked = true
			ns:RegisterEvent("PLAYER_REGEN_ENABLED", RestoreAfterCombat)
		end
	else
		Restore()
	end
end

function module:OnOptionChanged()
	self:Update()
end
