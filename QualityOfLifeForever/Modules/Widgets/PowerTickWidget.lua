-- luacheck: read globals CreateFrame GetTime UnitPower UnitPowerMax UnitPowerType InCombatLockdown Enum
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Energy tick widget",
		NOTE = "When the next energy tick comes",
		DESC = "A small movable bar that fills up until your next energy tick while your power is energy (rogues, druids in cat form). Syncs to the ticks it sees, so it is in step after the first tick. Drag it to move it; scale it in {Edit Mode}.",
		EDIT_MODE_NAME = "QoL Forever: Energy tick",
		SECTION_SHOW = "Show",
		SECTION_LOOK = "Appearance",
		HIDE_FULL = "Hide when full",
		HIDE_FULL_DESC = "Hides the bar while your energy is full.",
		COMBAT_ONLY = "Only in combat",
		COMBAT_ONLY_DESC = "Hides the bar out of combat.",
		WIDTH = "Width",
		WIDTH_DESC = "Width of the bar in pixels.",
		HEIGHT = "Height",
		HEIGHT_DESC = "Height of the bar in pixels.",
		BG_OPACITY = "Background opacity",
		BG_OPACITY_DESC = "Opacity of the widget's background and border, 0 % (transparent) to 100 %.",
	},
	deDE = {
		TITLE = "Energie-Tick-Widget",
		NOTE = "Wann der nächste Energie-Tick kommt",
		DESC = "Ein kleiner verschiebbarer Balken, der sich bis zum nächsten Energie-Tick füllt, solange deine Ressource Energie ist (Schurken, Druiden in Katzengestalt). Richtet sich nach den Ticks, die er sieht, und ist ab dem ersten Tick im Takt. Zum Verschieben ziehen; skalieren im {Bearbeitungsmodus}.",
		EDIT_MODE_NAME = "QoL Forever: Energie-Tick",
		SECTION_SHOW = "Anzeigen",
		SECTION_LOOK = "Darstellung",
		HIDE_FULL = "Bei voller Energie ausblenden",
		HIDE_FULL_DESC = "Blendet den Balken aus, solange die Energie voll ist.",
		COMBAT_ONLY = "Nur im Kampf",
		COMBAT_ONLY_DESC = "Blendet den Balken außerhalb des Kampfes aus.",
		WIDTH = "Breite",
		WIDTH_DESC = "Breite des Balkens in Pixeln.",
		HEIGHT = "Höhe",
		HEIGHT_DESC = "Höhe des Balkens in Pixeln.",
		BG_OPACITY = "Hintergrund-Deckkraft",
		BG_OPACITY_DESC = "Deckkraft von Hintergrund und Rahmen des Widgets, von 0 % (durchsichtig) bis 100 %.",
	},
})

local function FormatPercent(value)
	return ("%d%%"):format(value)
end

local function FormatPixels(value)
	return ("%d px"):format(value)
end

local module = ns:NewModule("PowerTickWidget", {
	title = L.TITLE,
	description = L.DESC,
	note = L.NOTE,
	category = "WIDGETS",
	defaults = {
		hideFull = true,
		combatOnly = false,
		width = 140,
		height = 8,
		backgroundOpacity = 92,
	},
	options = {
		{ type = "header", label = L.SECTION_SHOW },
		{ key = "hideFull", type = "checkbox", label = L.HIDE_FULL, tooltip = L.HIDE_FULL_DESC },
		{ key = "combatOnly", type = "checkbox", label = L.COMBAT_ONLY, tooltip = L.COMBAT_ONLY_DESC },
		{ type = "header", label = L.SECTION_LOOK },
		{ key = "width", type = "slider", label = L.WIDTH, tooltip = L.WIDTH_DESC, min = 60, max = 300, step = 10, format = FormatPixels },
		{ key = "height", type = "slider", label = L.HEIGHT, tooltip = L.HEIGHT_DESC, min = 4, max = 24, step = 1, format = FormatPixels },
		{ key = "backgroundOpacity", type = "slider", label = L.BG_OPACITY, tooltip = L.BG_OPACITY_DESC, min = 0, max = 100, step = 1, format = FormatPercent },
	},
})

-- Energy regenerates every 2 seconds (https://warcraft.wiki.gg/wiki/Energy).
local TICK_SECONDS = 2
-- Gains closer than this to the last tick come from talents, items etc.
local MIN_TICK_GAP = 1.5
local INSET = 2
local COLOR = { 1, 0.85, 0.1 }

local IsSecret = ns.Utils.IsSecret

local frame
-- tracked: power is energy; last: last read energy; lastTick: GetTime() of it.
local state = { tracked = false, last = nil, lastTick = nil }

local function IsEnergy()
	return UnitPowerType("player") == Enum.PowerType.Energy
end

local function ReadEnergy()
	local power, max = UnitPower("player", Enum.PowerType.Energy), UnitPowerMax("player", Enum.PowerType.Energy)
	if IsSecret(power) or IsSecret(max) then
		return nil
	end
	return power, max
end

local function OnUpdate(self)
	if state.lastTick then
		self.Bar:SetValue(((GetTime() - state.lastTick) % TICK_SECONDS) / TICK_SECONDS)
	else
		self.Bar:SetValue(0)
	end
end

local function CreateWidget()
	frame = ns:CreateOverlay("PowerTickWidget", {
		title = L.EDIT_MODE_NAME,
		width = 140,
		height = 12,
		default = { point = "CENTER", x = 0, y = -160 },
	})
	frame.Bar = CreateFrame("StatusBar", nil, frame)
	frame.Bar:SetPoint("TOPLEFT", INSET, -INSET)
	frame.Bar:SetPoint("BOTTOMRIGHT", -INSET, INSET)
	frame.Bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
	frame.Bar:SetStatusBarColor(unpack(COLOR))
	frame.Bar:SetMinMaxValues(0, 1)
	frame.Bar:SetValue(0)
	frame:SetScript("OnUpdate", OnUpdate)
end

function module:UpdateShown()
	if not frame then
		return
	end
	local shown = self.enabled and state.tracked
	if shown and self.db.combatOnly and not InCombatLockdown() then
		shown = false
	end
	if shown and self.db.hideFull then
		local power, max = ReadEnergy()
		shown = not (power and power >= max)
	end
	frame:SetShown(shown)
end

-- Power type changed (shapeshift, login): start over.
function module:ResetPower()
	state.tracked = IsEnergy()
	state.last = state.tracked and ReadEnergy() or nil
	state.lastTick = nil
	self:UpdateShown()
end

function module:UNIT_POWER_FREQUENT(unit)
	if unit ~= "player" or not state.tracked then
		return
	end
	local power = ReadEnergy()
	if not power then
		return
	end
	local now = GetTime()
	if state.last and power > state.last and (not state.lastTick or now - state.lastTick >= MIN_TICK_GAP) then
		state.lastTick = now
	end
	state.last = power
	self:UpdateShown()
end

function module:ApplyLayout()
	frame:SetSize(self.db.width, self.db.height + INSET * 2)
	ns:SetOverlayBackgroundAlpha(frame, self.db.backgroundOpacity / 100)
end

function module:OnOptionChanged()
	self:ApplyLayout()
	self:ResetPower()
end

function module:OnEnable()
	if not frame then
		CreateWidget()
	end
	self:ApplyLayout()
	self:RegisterEvent("UNIT_POWER_FREQUENT")
	self:RegisterEvent("UNIT_DISPLAYPOWER", function(_, unit)
		if unit == "player" then
			self:ResetPower()
		end
	end)
	self:RegisterEvent("UNIT_MAXPOWER", self.UpdateShown)
	self:RegisterEvent("PLAYER_ENTERING_WORLD", self.ResetPower)
	self:RegisterEvent("PLAYER_REGEN_DISABLED", self.UpdateShown)
	self:RegisterEvent("PLAYER_REGEN_ENABLED", self.UpdateShown)
	self:ResetPower()
end

function module:OnDisable()
	frame:Hide()
end
