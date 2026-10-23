-- luacheck: read globals STANDARD_TEXT_FONT CreateFrame GetTime UnitPower UnitPowerType UnitAffectingCombat Enum C_Spell
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "5 second rule",
		NOTE = "Mana regeneration in combat",
		DESC = "A small movable bar that counts down the five seconds after you spend mana in combat, until mana regenerates again. Drag it to move it; scale it in {Edit Mode}.",
		EDIT_MODE_NAME = "QoL Forever: 5 second rule",
		NOTICE = "Only shown with mana, in combat, for 5 seconds after you spend mana. While this window or {Edit Mode} is open, a preview is shown so you can place it.",
		SECTION_MANA = "Countdown",
		SECTION_LOOK = "Appearance",
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
		TITLE = "5-Sek.-Regel",
		NOTE = "Manaregeneration im Kampf",
		DESC = "Ein kleiner verschiebbarer Balken, der die fünf Sekunden herunterzählt, nachdem du im Kampf Mana ausgegeben hast, bis Mana wieder regeneriert. Zum Verschieben ziehen; skalieren im {Bearbeitungsmodus}.",
		EDIT_MODE_NAME = "QoL Forever: 5-Sek.-Regel",
		NOTICE = "Erscheint nur mit Mana, im Kampf, für 5 Sekunden, nachdem du Mana ausgegeben hast. Solange dieses Fenster oder der {Bearbeitungsmodus} offen ist, wird eine Vorschau angezeigt, damit du es platzieren kannst.",
		SECTION_MANA = "Countdown",
		SECTION_LOOK = "Darstellung",
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
	order = 70,
	defaults = {
		countdown = true,
		countdownSize = 12,
		width = 140,
		height = 8,
		backgroundOpacity = 92,
		textOutline = "OUTLINE",
		textShadow = false,
		showTitle = false,
	},
	options = {
		{ type = "header", label = L.SECTION_MANA },
		{ key = "countdown", type = "checkbox", label = L.COUNTDOWN, tooltip = L.COUNTDOWN_DESC },
		{ key = "countdownSize", type = "slider", label = L.COUNTDOWN_SIZE, tooltip = L.COUNTDOWN_SIZE_DESC, min = 8, max = 24, step = 1, format = FormatPixels },
		{ type = "header", label = L.SECTION_LOOK },
		ns:TextOutlineOption(),
		ns:TextShadowOption(),
		{ key = "width", type = "slider", label = L.WIDTH, tooltip = L.WIDTH_DESC, min = 60, max = 300, step = 10, format = FormatPixels },
		{ key = "height", type = "slider", label = L.HEIGHT, tooltip = L.HEIGHT_DESC, min = 4, max = 24, step = 1, format = FormatPixels },
		{ key = "backgroundOpacity", type = "slider", label = L.BG_OPACITY, tooltip = L.BG_OPACITY_DESC, min = 0, max = 100, step = 1, format = FormatPercent },
		ns:TitleOption(),
	},
})

-- Mana regenerates steadily, but in combat only once 5 seconds passed since
-- mana was last spent (https://warcraft.wiki.gg/wiki/Five_second_rule).
-- Energy has no ticks on Forever; it regenerates continuously.
local FIVE_SECONDS = 5
local INSET = 2
local MANA_COLOR = { 0.25, 0.55, 1 }

local IsSecret = ns.Utils.IsSecret
local LibEditMode = ns.LibEditMode
-- Shown as a preview while Edit Mode or the options window is open, so it can
-- be found and moved.
local editing, optionsShown = false, false

local function IsPreview()
	return editing or optionsShown
end

local frame
-- mana: the player uses mana right now; last: last read mana; spentAt:
-- GetTime() mana was last spent.
local state = { mana = false, last = nil, spentAt = nil }

local function UsesMana()
	return UnitPowerType("player") == Enum.PowerType.Mana
end

local function ReadMana()
	local power = UnitPower("player", Enum.PowerType.Mana)
	if IsSecret(power) then
		return nil
	end
	return power
end

local function FiveSecondsLeft()
	return state.spentAt and FIVE_SECONDS - (GetTime() - state.spentAt) or 0
end

local function OnUpdate(self)
	if IsPreview() then
		return
	end
	local left = FiveSecondsLeft()
	if left <= 0 then
		module:UpdateShown()
		return
	end
	self.Bar:SetValue(left / FIVE_SECONDS)
	self.Countdown:SetFormattedText("%.1f", left)
end

local function CreateWidget()
	frame = ns:CreateOverlay("PowerTickWidget", {
		title = L.EDIT_MODE_NAME,
		module = module,
		width = 140,
		height = 12,
		default = { point = "CENTER", x = 0, y = -160 },
	})
	frame.Bar = CreateFrame("StatusBar", nil, frame)
	frame.Bar:SetPoint("TOPLEFT", INSET, -INSET)
	frame.Bar:SetPoint("BOTTOMRIGHT", -INSET, INSET)
	frame.Bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
	frame.Bar:SetStatusBarColor(unpack(MANA_COLOR))
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
	frame.Countdown:SetShown(self.db.countdown)
	if IsPreview() and self.enabled then
		frame.Bar:SetValue(0.6)
		frame.Countdown:SetFormattedText("%.1f", FIVE_SECONDS * 0.6)
		frame:Show()
		return
	end
	frame:SetShown(self.enabled and state.mana and UnitAffectingCombat("player") and FiveSecondsLeft() > 0)
end

-- Power type changed (shapeshift, login): start over.
function module:ResetPower()
	state.mana = UsesMana()
	state.last = state.mana and ReadMana() or nil
	state.spentAt = nil
	self:UpdateShown()
end

function module:UNIT_POWER_FREQUENT(unit)
	if unit ~= "player" or not state.mana then
		return
	end
	local power = ReadMana()
	if not power then
		return
	end
	if state.last and power < state.last then
		self:OnManaSpent()
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
	if unit == "player" and state.mana and CostsMana(spellID) then
		self:OnManaSpent()
	end
end

function module:OnCombatEnd()
	state.spentAt = nil
	self:UpdateShown()
end

function module:ApplyLayout()
	frame:SetSize(self.db.width, self.db.height + INSET * 2)
	ns:SetOverlayFont(frame.Countdown, self.db.countdownSize, self.db)
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
