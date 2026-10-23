-- luacheck: read globals C_AddOns InCombatLockdown
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Cooldown text position",
		NOTE = "Moves the countdown numbers away from the center",
		DESC = "Places the remaining cooldown time on the icons of the cooldown manager and the action bars at a corner or edge instead of the center.",
		VIEWER = "Cooldown manager",
		ACTIONBARS = "Action bars",
		ENABLE = "Move cooldown text",
		ENABLE_VIEWER_DESC = "Moves the cooldown text on the icons of the cooldown manager.",
		ENABLE_ACTIONBARS_DESC = "Moves the cooldown text on the action buttons. Changes wait until you leave combat.",
		POSITION = "Position",
		POSITION_DESC = "Where on the icon the cooldown text is shown.",
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
		TITLE = "Position des Abklingzeit-Texts",
		NOTE = "Verschiebt die Countdown-Zahlen aus der Mitte",
		DESC = "Zeigt die verbleibende Abklingzeit auf den Symbolen des Cooldown-Managers und der Aktionsleisten an einer Ecke oder Kante statt in der Mitte.",
		VIEWER = "Cooldown-Manager",
		ACTIONBARS = "Aktionsleisten",
		ENABLE = "Abklingzeit-Text verschieben",
		ENABLE_VIEWER_DESC = "Verschiebt den Abklingzeit-Text auf den Symbolen des Cooldown-Managers.",
		ENABLE_ACTIONBARS_DESC = "Verschiebt den Abklingzeit-Text auf den Aktionstasten. Änderungen warten, bis du den Kampf verlässt.",
		POSITION = "Position",
		POSITION_DESC = "Wo auf dem Symbol der Abklingzeit-Text angezeigt wird.",
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

-- Settings per group, stored as <prefix>, <prefix>Position, <prefix>X, <prefix>Y
local GROUPS = {
	{ prefix = "viewer", label = L.VIEWER, enableDesc = L.ENABLE_VIEWER_DESC, position = "BOTTOMRIGHT" },
	{ prefix = "actionbars", label = L.ACTIONBARS, enableDesc = L.ENABLE_ACTIONBARS_DESC, position = "BOTTOMRIGHT" },
}

local defaults, options = {}, {}
for _, group in ipairs(GROUPS) do
	local p = group.prefix
	defaults[p] = true
	defaults[p .. "Position"] = group.position
	defaults[p .. "X"] = 0
	defaults[p .. "Y"] = 0
	for _, option in ipairs({
		{ type = "header", label = group.label },
		{ key = p, type = "checkbox", label = L.ENABLE, tooltip = group.enableDesc },
		{ key = p .. "Position", type = "dropdown", label = L.POSITION, tooltip = L.POSITION_DESC, values = positionValues },
		{ key = p .. "X", type = "slider", label = L.OFFSET_X, tooltip = L.OFFSET_X_DESC, min = -20, max = 20, step = 1, format = FormatPixels },
		{ key = p .. "Y", type = "slider", label = L.OFFSET_Y, tooltip = L.OFFSET_Y_DESC, min = -20, max = 20, step = 1, format = FormatPixels },
	}) do
		options[#options + 1] = option
	end
end

local module = ns:NewModule("CooldownTextPosition", {
	title = L.TITLE,
	description = L.DESC,
	note = L.NOTE,
	category = "COOLDOWN_MANAGER",
	defaults = defaults,
	options = options,
})

local VIEWERS = { "EssentialCooldownViewer", "UtilityCooldownViewer", "BuffIconCooldownViewer" }

-- MainActionBar is the Midnight name, MainMenuBar the older one.
local ACTION_BARS = {
	"MainActionBar", "MainMenuBar", "MultiBarBottomLeft", "MultiBarBottomRight",
	"MultiBarRight", "MultiBarLeft", "MultiBar5", "MultiBar6", "MultiBar7",
}

-- countdown FontString -> its original anchors, to restore on disable
local originals = {}

local function SavePoints(text)
	if originals[text] then
		return
	end
	local points = {}
	for i = 1, text:GetNumPoints() do
		points[i] = { text:GetPoint(i) }
	end
	originals[text] = points
end

local function RestorePoints(text)
	local points = originals[text]
	if not points then
		return
	end
	text:ClearAllPoints()
	for _, point in ipairs(points) do
		text:SetPoint(unpack(point))
	end
	originals[text] = nil
end

local function CountdownText(cooldown)
	return cooldown and cooldown.GetCountdownFontString and cooldown:GetCountdownFontString()
end

local function Place(cooldown, prefix)
	local text = CountdownText(cooldown)
	if not text then
		return
	end
	local db = module.db
	if not module.enabled or not db[prefix] then
		RestorePoints(text)
		return
	end
	SavePoints(text)
	local point = db[prefix .. "Position"]
	text:ClearAllPoints()
	text:SetPoint(point, cooldown, point, db[prefix .. "X"], db[prefix .. "Y"])
end

function module:UpdateViewer(frame)
	if not frame.GetItemFrames then
		return
	end
	for _, item in ipairs(frame:GetItemFrames()) do
		Place(item.Cooldown, "viewer")
	end
end

function module:UpdateViewers()
	for _, name in ipairs(VIEWERS) do
		local frame = _G[name]
		if frame then
			self:UpdateViewer(frame)
		end
	end
end

-- Action buttons are secure; their regions are only touched out of combat.
function module:UpdateActionBars()
	if InCombatLockdown() then
		self:RegisterEvent("PLAYER_REGEN_ENABLED", "UpdateActionBars")
		return
	end
	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	for _, name in ipairs(ACTION_BARS) do
		local bar = _G[name]
		if bar and bar.actionButtons then
			for _, button in ipairs(bar.actionButtons) do
				Place(button.cooldown, "actionbars")
			end
		end
	end
end

function module:HookViewers()
	for _, name in ipairs(VIEWERS) do
		local frame = _G[name]
		if frame then
			self:SecureHook(frame, "RefreshLayout", function()
				self:UpdateViewer(frame)
			end)
		end
	end
	self:UpdateViewers()
end

function module:ADDON_LOADED(name)
	if name == "Blizzard_CooldownViewer" then
		self:UnregisterEvent("ADDON_LOADED")
		self:HookViewers()
	end
end

function module:OnEnable()
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateActionBars")
	self:UpdateActionBars()
	if C_AddOns.IsAddOnLoaded("Blizzard_CooldownViewer") then
		self:HookViewers()
	else
		self:RegisterEvent("ADDON_LOADED")
	end
end

-- Module events are unregistered on disable, so a restore that has to wait
-- for the end of combat goes through the addon's own event frame.
local restorePending, restoreHooked

local function RestoreAfterCombat()
	if restorePending and not module.enabled then
		module:UpdateActionBars()
	end
	restorePending = false
end

function module:OnDisable()
	-- Place() restores every text while the module is disabled.
	self:UpdateViewers()
	if InCombatLockdown() then
		restorePending = true
		if not restoreHooked then
			restoreHooked = true
			ns:RegisterEvent("PLAYER_REGEN_ENABLED", RestoreAfterCombat)
		end
	else
		self:UpdateActionBars()
	end
end

function module:OnOptionChanged(key)
	if key:find("^viewer") then
		self:UpdateViewers()
	else
		self:UpdateActionBars()
	end
end
