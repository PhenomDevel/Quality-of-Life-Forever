-- luacheck: read globals CreateFrame GetTime UnitPower UnitPowerMax UnitPowerType InCombatLockdown Enum
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Mana & energy tick widget",
		NOTE = "When the next mana or energy tick comes",
		DESC = "A small movable bar that fills up until your next mana or energy tick. After you spend mana it first counts down the five seconds without mana regeneration. Syncs to the ticks it sees, so it is in step after the first tick. Drag it to move it; scale it in {Edit Mode}.",
		EDIT_MODE_NAME = "QoL Forever: Mana & energy tick",
		SECTION_SHOW = "Show",
		SECTION_LOOK = "Appearance",
		MANA = "Mana",
		MANA_DESC = "Shows the bar while your power is mana.",
		ENERGY = "Energy",
		ENERGY_DESC = "Shows the bar while your power is energy.",
		FIVE_SECOND = "Five second rule",
		FIVE_SECOND_DESC = "After spending mana, counts down the five seconds until mana regenerates again.",
		HIDE_FULL = "Hide when full",
		HIDE_FULL_DESC = "Hides the bar while your mana or energy is full.",
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
		TITLE = "Mana- & Energie-Tick-Widget",
		NOTE = "Wann der nächste Mana- oder Energie-Tick kommt",
		DESC = "Ein kleiner verschiebbarer Balken, der sich bis zum nächsten Mana- oder Energie-Tick füllt. Nachdem du Mana ausgegeben hast, zählt er zuerst die fünf Sekunden ohne Manaregeneration herunter. Richtet sich nach den Ticks, die er sieht, und ist ab dem ersten Tick im Takt. Zum Verschieben ziehen; skalieren im {Bearbeitungsmodus}.",
		EDIT_MODE_NAME = "QoL Forever: Mana- & Energie-Tick",
		SECTION_SHOW = "Anzeigen",
		SECTION_LOOK = "Darstellung",
		MANA = "Mana",
		MANA_DESC = "Zeigt den Balken, solange deine Ressource Mana ist.",
		ENERGY = "Energie",
		ENERGY_DESC = "Zeigt den Balken, solange deine Ressource Energie ist.",
		FIVE_SECOND = "Fünf-Sekunden-Regel",
		FIVE_SECOND_DESC = "Zählt nach dem Ausgeben von Mana die fünf Sekunden herunter, bis Mana wieder regeneriert.",
		HIDE_FULL = "Bei voller Ressource ausblenden",
		HIDE_FULL_DESC = "Blendet den Balken aus, solange Mana oder Energie voll ist.",
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
		mana = true,
		energy = true,
		fiveSecond = true,
		hideFull = true,
		combatOnly = false,
		width = 140,
		height = 8,
		backgroundOpacity = 92,
	},
	options = {
		{ type = "header", label = L.SECTION_SHOW },
		{ key = "mana", type = "checkbox", label = L.MANA, tooltip = L.MANA_DESC },
		{ key = "energy", type = "checkbox", label = L.ENERGY, tooltip = L.ENERGY_DESC },
		{ key = "fiveSecond", type = "checkbox", label = L.FIVE_SECOND, tooltip = L.FIVE_SECOND_DESC },
		{ key = "hideFull", type = "checkbox", label = L.HIDE_FULL, tooltip = L.HIDE_FULL_DESC },
		{ key = "combatOnly", type = "checkbox", label = L.COMBAT_ONLY, tooltip = L.COMBAT_ONLY_DESC },
		{ type = "header", label = L.SECTION_LOOK },
		{ key = "width", type = "slider", label = L.WIDTH, tooltip = L.WIDTH_DESC, min = 60, max = 300, step = 10, format = FormatPixels },
		{ key = "height", type = "slider", label = L.HEIGHT, tooltip = L.HEIGHT_DESC, min = 4, max = 24, step = 1, format = FormatPixels },
		{ key = "backgroundOpacity", type = "slider", label = L.BG_OPACITY, tooltip = L.BG_OPACITY_DESC, min = 0, max = 100, step = 1, format = FormatPercent },
	},
})

-- Mana and energy regenerate every 2 seconds; spending mana pauses mana
-- regeneration for 5 seconds (https://warcraft.wiki.gg/wiki/Five_second_rule).
local TICK_SECONDS = 2
local FIVE_SECONDS = 5
-- Gains closer than this to the last tick come from potions, talents etc.
local MIN_TICK_GAP = 1.5
local INSET = 2

local COLORS = {
	MANA = { 0.25, 0.55, 1 },
	ENERGY = { 1, 0.85, 0.1 },
	FIVE_SECOND = { 0.65, 0.4, 1 },
}

local IsSecret = ns.Utils.IsSecret

local frame
-- powerKey: "MANA"/"ENERGY" while tracked, nil otherwise.
local state = { powerKey = nil, last = nil, lastTick = nil, spentAt = nil }

local function TrackedPower()
	local powerType = UnitPowerType("player")
	if powerType == Enum.PowerType.Mana and module.db.mana then
		return "MANA", powerType
	elseif powerType == Enum.PowerType.Energy and module.db.energy then
		return "ENERGY", powerType
	end
end

local function ReadPower(powerType)
	local power, max = UnitPower("player", powerType), UnitPowerMax("player", powerType)
	if IsSecret(power) or IsSecret(max) then
		return nil
	end
	return power, max
end

local function OnUpdate(self)
	local now = GetTime()
	if state.spentAt and module.db.fiveSecond and now - state.spentAt < FIVE_SECONDS then
		self.Bar:SetStatusBarColor(unpack(COLORS.FIVE_SECOND))
		self.Bar:SetValue(1 - (now - state.spentAt) / FIVE_SECONDS)
		return
	end
	self.Bar:SetStatusBarColor(unpack(COLORS[state.powerKey]))
	if state.lastTick then
		self.Bar:SetValue(((now - state.lastTick) % TICK_SECONDS) / TICK_SECONDS)
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
	frame.Bar:SetMinMaxValues(0, 1)
	frame.Bar:SetValue(0)
	frame:SetScript("OnUpdate", OnUpdate)
end

function module:UpdateShown()
	if not frame then
		return
	end
	local shown = self.enabled and state.powerKey ~= nil
	if shown and self.db.combatOnly and not InCombatLockdown() then
		shown = false
	end
	if shown and self.db.hideFull then
		local _, powerType = TrackedPower()
		local power, max = ReadPower(powerType)
		local waiting = state.spentAt and GetTime() - state.spentAt < FIVE_SECONDS
		shown = not (power and power >= max and not waiting)
	end
	frame:SetShown(shown)
end

-- Power type changed (shapeshift, login): start over.
function module:ResetPower()
	local key, powerType = TrackedPower()
	state.powerKey = key
	state.last = key and ReadPower(powerType)
	state.lastTick, state.spentAt = nil, nil
	self:UpdateShown()
end

function module:UNIT_POWER_FREQUENT(unit)
	if unit ~= "player" or not state.powerKey then
		return
	end
	local _, powerType = TrackedPower()
	local power = ReadPower(powerType)
	if not power then
		return
	end
	local now = GetTime()
	if state.last then
		if power > state.last then
			if not state.lastTick or now - state.lastTick >= MIN_TICK_GAP then
				state.lastTick = now
			end
		elseif power < state.last and state.powerKey == "MANA" then
			state.spentAt = now
		end
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
