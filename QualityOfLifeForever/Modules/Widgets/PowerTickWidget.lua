-- luacheck: read globals STANDARD_TEXT_FONT CreateFrame GetTime UnitPower UnitPowerMax UnitPowerType UnitAffectingCombat InCombatLockdown Enum C_Spell
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Energy tick & 5 second rule",
		NOTE = "Next energy tick, mana regeneration in combat",
		DESC = "A small movable bar. With energy (rogues, druids in cat form) it fills up until your next energy tick; it syncs to the ticks it sees, so it is in step after the first tick. With mana it counts down the five seconds after you spend mana in combat, until mana regenerates again. Drag it to move it; scale it in {Edit Mode}.",
		EDIT_MODE_NAME = "QoL Forever: Energy tick & 5 s rule",
		NOTICE = "Only shown when relevant: with energy, and with mana in combat for 5 seconds after you spend mana. While this window or {Edit Mode} is open, a preview is shown so you can place it.",
		SECTION_ENERGY = "Energy",
		SECTION_MANA = "Mana",
		SECTION_LOOK = "Appearance",
		HIDE_FULL = "Hide when full",
		HIDE_FULL_DESC = "Hides the energy bar while your energy is full.",
		COMBAT_ONLY = "Only in combat",
		COMBAT_ONLY_DESC = "Hides the energy bar out of combat.",
		FIVE_SECOND = "Five second rule",
		FIVE_SECOND_DESC = "In combat, counts down the five seconds after you spend mana until mana regenerates again. The bar only shows during the countdown.",
		COUNTDOWN = "Countdown",
		COUNTDOWN_DESC = "Shows the seconds left in the middle of the bar.",
		COUNTDOWN_SIZE = "Countdown size",
		COUNTDOWN_SIZE_DESC = "Text size of the countdown in pixels.",
		WIDTH = "Width",
		WIDTH_DESC = "Width of the bar in pixels.",
		HEIGHT = "Height",
		HEIGHT_DESC = "Height of the bar in pixels.",
		BG_OPACITY = "Background opacity",
		BG_OPACITY_DESC = "Opacity of the widget's background and border, 0 % (transparent) to 100 %.",
	},
	deDE = {
		TITLE = "Energie-Tick & 5-Sek.-Regel",
		NOTE = "Nächster Energie-Tick, Manaregeneration im Kampf",
		DESC = "Ein kleiner verschiebbarer Balken. Mit Energie (Schurken, Druiden in Katzengestalt) füllt er sich bis zum nächsten Energie-Tick; er richtet sich nach den Ticks, die er sieht, und ist ab dem ersten Tick im Takt. Mit Mana zählt er die fünf Sekunden herunter, nachdem du im Kampf Mana ausgegeben hast, bis Mana wieder regeneriert. Zum Verschieben ziehen; skalieren im {Bearbeitungsmodus}.",
		EDIT_MODE_NAME = "QoL Forever: Energie-Tick & 5-Sek.-Regel",
		NOTICE = "Erscheint nur, wenn relevant: mit Energie, und mit Mana im Kampf für 5 Sekunden, nachdem du Mana ausgegeben hast. Solange dieses Fenster oder der {Bearbeitungsmodus} offen ist, wird eine Vorschau angezeigt, damit du es platzieren kannst.",
		SECTION_ENERGY = "Energie",
		SECTION_MANA = "Mana",
		SECTION_LOOK = "Darstellung",
		HIDE_FULL = "Bei voller Energie ausblenden",
		HIDE_FULL_DESC = "Blendet den Energie-Balken aus, solange die Energie voll ist.",
		COMBAT_ONLY = "Nur im Kampf",
		COMBAT_ONLY_DESC = "Blendet den Energie-Balken außerhalb des Kampfes aus.",
		FIVE_SECOND = "Fünf-Sekunden-Regel",
		FIVE_SECOND_DESC = "Zählt im Kampf die fünf Sekunden herunter, nachdem du Mana ausgegeben hast, bis Mana wieder regeneriert. Der Balken erscheint nur während des Countdowns.",
		COUNTDOWN = "Countdown",
		COUNTDOWN_DESC = "Zeigt die verbleibenden Sekunden mittig auf dem Balken.",
		COUNTDOWN_SIZE = "Countdown-Größe",
		COUNTDOWN_SIZE_DESC = "Textgröße des Countdowns in Pixeln.",
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
	notice = L.NOTICE,
	category = "WIDGETS",
	defaults = {
		hideFull = true,
		combatOnly = false,
		fiveSecond = true,
		countdown = true,
		countdownSize = 12,
		width = 140,
		height = 8,
		backgroundOpacity = 92,
	},
	options = {
		{ type = "header", label = L.SECTION_ENERGY },
		{ key = "hideFull", type = "checkbox", label = L.HIDE_FULL, tooltip = L.HIDE_FULL_DESC },
		{ key = "combatOnly", type = "checkbox", label = L.COMBAT_ONLY, tooltip = L.COMBAT_ONLY_DESC },
		{ type = "header", label = L.SECTION_MANA },
		{ key = "fiveSecond", type = "checkbox", label = L.FIVE_SECOND, tooltip = L.FIVE_SECOND_DESC },
		{ key = "countdown", type = "checkbox", label = L.COUNTDOWN, tooltip = L.COUNTDOWN_DESC },
		{ key = "countdownSize", type = "slider", label = L.COUNTDOWN_SIZE, tooltip = L.COUNTDOWN_SIZE_DESC, min = 8, max = 24, step = 1, format = FormatPixels },
		{ type = "header", label = L.SECTION_LOOK },
		{ key = "width", type = "slider", label = L.WIDTH, tooltip = L.WIDTH_DESC, min = 60, max = 300, step = 10, format = FormatPixels },
		{ key = "height", type = "slider", label = L.HEIGHT, tooltip = L.HEIGHT_DESC, min = 4, max = 24, step = 1, format = FormatPixels },
		{ key = "backgroundOpacity", type = "slider", label = L.BG_OPACITY, tooltip = L.BG_OPACITY_DESC, min = 0, max = 100, step = 1, format = FormatPercent },
	},
})

-- Energy regenerates every 2 seconds (https://warcraft.wiki.gg/wiki/Energy).
-- Mana regenerates steadily, but in combat only once 5 seconds passed since
-- mana was last spent (https://warcraft.wiki.gg/wiki/Five_second_rule).
local TICK_SECONDS = 2
local FIVE_SECONDS = 5
-- Gains closer than this to the last tick come from talents, items etc.
local MIN_TICK_GAP = 1.5
local INSET = 2
local COLORS = {
	ENERGY = { 1, 0.85, 0.1 },
	MANA = { 0.25, 0.55, 1 },
}

local IsSecret = ns.Utils.IsSecret
local LibEditMode = ns.LibEditMode
-- Shown as a preview while Edit Mode or the options window is open, so it can
-- be found and moved.
local editing, optionsShown = false, false

local function IsPreview()
	return editing or optionsShown
end

local frame
-- mode: "ENERGY", "MANA" or nil; last: last read power; lastTick: GetTime()
-- of the last energy tick; spentAt: GetTime() mana was last spent.
local state = { mode = nil, last = nil, lastTick = nil, spentAt = nil }

local function CurrentMode()
	local powerType = UnitPowerType("player")
	if powerType == Enum.PowerType.Energy then
		return "ENERGY"
	elseif powerType == Enum.PowerType.Mana and module.db.fiveSecond then
		return "MANA"
	end
end

local function ReadPower()
	local powerType = Enum.PowerType[state.mode == "MANA" and "Mana" or "Energy"]
	local power, max = UnitPower("player", powerType), UnitPowerMax("player", powerType)
	if IsSecret(power) or IsSecret(max) then
		return nil
	end
	return power, max
end

local function FiveSecondsLeft()
	return state.spentAt and FIVE_SECONDS - (GetTime() - state.spentAt) or 0
end

local function OnUpdate(self)
	if IsPreview() then
		return
	end
	if state.mode == "MANA" then
		local left = FiveSecondsLeft()
		if left <= 0 then
			module:UpdateShown()
			return
		end
		self.Bar:SetValue(left / FIVE_SECONDS)
		self.Countdown:SetFormattedText("%.1f", left)
	elseif state.lastTick then
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
	frame.Bar:SetMinMaxValues(0, 1)
	frame.Bar:SetValue(0)
	-- Above the bar fill; may be taller than a thin bar.
	frame.Countdown = frame.Bar:CreateFontString(nil, "OVERLAY")
	frame.Countdown:SetPoint("CENTER", frame, "CENTER")
	frame:SetScript("OnUpdate", OnUpdate)
end

function module:UpdateShown()
	if not frame then
		return
	end
	frame.Countdown:SetShown(state.mode == "MANA" and self.db.countdown)
	if IsPreview() and self.enabled then
		frame.Bar:SetStatusBarColor(unpack(COLORS[state.mode or "ENERGY"]))
		frame.Bar:SetValue(0.6)
		frame.Countdown:SetFormattedText("%.1f", FIVE_SECONDS * 0.6)
		frame:Show()
		return
	end
	local shown = self.enabled and state.mode ~= nil
	if shown and state.mode == "MANA" then
		shown = UnitAffectingCombat("player") and FiveSecondsLeft() > 0
	elseif shown then
		if self.db.combatOnly and not InCombatLockdown() then
			shown = false
		elseif self.db.hideFull then
			local power, max = ReadPower()
			shown = not (power and power >= max)
		end
	end
	if shown then
		frame.Bar:SetStatusBarColor(unpack(COLORS[state.mode]))
	end
	frame:SetShown(shown)
end

-- Power type changed (shapeshift, login): start over.
function module:ResetPower()
	state.mode = CurrentMode()
	state.last = state.mode and ReadPower() or nil
	state.lastTick, state.spentAt = nil, nil
	self:UpdateShown()
end

function module:UNIT_POWER_FREQUENT(unit)
	if unit ~= "player" or not state.mode then
		return
	end
	local power = ReadPower()
	if not power then
		return
	end
	local now = GetTime()
	if state.last then
		if state.mode == "MANA" then
			if power < state.last then
				self:OnManaSpent()
			end
		elseif power > state.last and (not state.lastTick or now - state.lastTick >= MIN_TICK_GAP) then
			state.lastTick = now
		end
	end
	state.last = power
	self:UpdateShown()
end

-- Also out of combat: the opening spell is paid before combat starts.
function module:OnManaSpent()
	state.spentAt = GetTime()
	self:UpdateShown()
end

local function CostsMana(spellID)
	if not spellID or IsSecret(spellID) then
		return false
	end
	for _, cost in ipairs(C_Spell.GetSpellPowerCost(spellID) or {}) do
		if not IsSecret(cost.type) and cost.type == Enum.PowerType.Mana
			and not IsSecret(cost.cost) and cost.cost > 0 then
			return true
		end
	end
	return false
end

-- Mana can be secret in combat, so a cast that costs mana counts as well.
function module:UNIT_SPELLCAST_SUCCEEDED(unit, _, spellID)
	if unit == "player" and state.mode == "MANA" and CostsMana(spellID) then
		self:OnManaSpent()
	end
end

function module:OnCombatEnd()
	state.spentAt = nil
	self:UpdateShown()
end

function module:ApplyLayout()
	frame:SetSize(self.db.width, self.db.height + INSET * 2)
	frame.Countdown:SetFont(STANDARD_TEXT_FONT, self.db.countdownSize, "OUTLINE")
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
	self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	optionsShown = ns:IsOptionsShown()
	if not self.editModeHooked then
		self.editModeHooked = true
		LibEditMode:RegisterCallback("enter", function()
			editing = true
			self:UpdateShown()
		end)
		LibEditMode:RegisterCallback("exit", function()
			editing = false
			self:UpdateShown()
		end)
	end
	self:RegisterEvent("UNIT_DISPLAYPOWER", function(_, unit)
		if unit == "player" then
			self:ResetPower()
		end
	end)
	self:RegisterEvent("UNIT_MAXPOWER", self.UpdateShown)
	self:RegisterEvent("PLAYER_ENTERING_WORLD", self.ResetPower)
	self:RegisterEvent("PLAYER_REGEN_DISABLED", self.UpdateShown)
	self:RegisterEvent("PLAYER_REGEN_ENABLED", self.OnCombatEnd)
	self:ResetPower()
end

function module:OnOptionsShown(shown)
	optionsShown = shown
	self:UpdateShown()
end

function module:OnDisable()
	frame:Hide()
end
