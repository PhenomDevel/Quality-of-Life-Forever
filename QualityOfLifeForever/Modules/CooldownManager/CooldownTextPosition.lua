-- luacheck: read globals C_AddOns
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Cooldown text position",
		NOTE = "Moves the countdown numbers away from the center",
		DESC = "Places the remaining cooldown time on the icons of the cooldown manager at a corner or edge instead of the center.",
		POSITION = "Position",
		POSITION_DESC = "Where on the icon the cooldown text is shown.",
		OFFSET_X = "Horizontal offset",
		OFFSET_X_DESC = "Moves the text to the right (positive) or left (negative), in pixels.",
		OFFSET_Y = "Vertical offset",
		OFFSET_Y_DESC = "Moves the text up (positive) or down (negative), in pixels.",
	},
	deDE = {
		TITLE = "Position des Abklingzeit-Texts",
		NOTE = "Verschiebt die Countdown-Zahlen aus der Mitte",
		DESC = "Zeigt die verbleibende Abklingzeit auf den Symbolen des Cooldown-Managers an einer Ecke oder Kante statt in der Mitte.",
		POSITION = "Position",
		POSITION_DESC = "Wo auf dem Symbol der Abklingzeit-Text angezeigt wird.",
		OFFSET_X = "Horizontaler Versatz",
		OFFSET_X_DESC = "Verschiebt den Text nach rechts (positiv) oder links (negativ), in Pixeln.",
		OFFSET_Y = "Vertikaler Versatz",
		OFFSET_Y_DESC = "Verschiebt den Text nach oben (positiv) oder unten (negativ), in Pixeln.",
	},
})

local module = ns:NewModule("CooldownTextPosition", {
	title = L.TITLE,
	description = L.DESC,
	note = L.NOTE,
	category = "COOLDOWN_MANAGER",
	order = 20,
	defaults = {
		position = "BOTTOMRIGHT",
		x = 0,
		y = 0,
	},
	options = {
		{ key = "position", type = "dropdown", label = L.POSITION, tooltip = L.POSITION_DESC, values = ns.Utils.AnchorPointValues() },
		{ key = "x", type = "slider", label = L.OFFSET_X, tooltip = L.OFFSET_X_DESC, min = -20, max = 20, step = 1, format = ns.Utils.FormatPixels },
		{ key = "y", type = "slider", label = L.OFFSET_Y, tooltip = L.OFFSET_Y_DESC, min = -20, max = 20, step = 1, format = ns.Utils.FormatPixels },
	},
})

local VIEWERS = { "EssentialCooldownViewer", "UtilityCooldownViewer", "BuffIconCooldownViewer" }

-- countdown FontString -> its original anchors, to restore on disable
local originals = {}

local function Place(cooldown)
	local text = cooldown and cooldown.GetCountdownFontString and cooldown:GetCountdownFontString()
	if not text then
		return
	end
	if not originals[text] then
		local points = {}
		for i = 1, text:GetNumPoints() do
			points[i] = { text:GetPoint(i) }
		end
		originals[text] = points
	end
	local db = module.db
	text:ClearAllPoints()
	text:SetPoint(db.position, cooldown, db.position, db.x, db.y)
end

function module:UpdateViewer(frame)
	if not frame.GetItemFrames then
		return
	end
	for _, item in ipairs(frame:GetItemFrames()) do
		Place(item.Cooldown)
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
	if C_AddOns.IsAddOnLoaded("Blizzard_CooldownViewer") then
		self:HookViewers()
	else
		self:RegisterEvent("ADDON_LOADED")
	end
end

function module:OnDisable()
	for text, points in pairs(originals) do
		text:ClearAllPoints()
		for _, point in ipairs(points) do
			text:SetPoint(unpack(point))
		end
	end
	wipe(originals)
end

function module:OnOptionChanged()
	self:UpdateViewers()
end
