-- luacheck: read globals CreateFont STANDARD_TEXT_FONT C_Timer C_Reputation GetTime UnitGUID UnitSex GetText FACTION_BAR_COLORS AbbreviateNumbers BreakUpLargeNumbers SecondsToTime time
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Reputation widget",
		NOTE = "Watched faction, progress and reputation per hour",
		DESC = "A small movable display of the faction you watch in the reputation tab: standing, progress, reputation per hour and time to the next standing, laid out like the {XP widget}. At max level it can take the XP widget's place. Hidden while no faction is watched. Drag it to move it; scale it in {Edit Mode}.",
		EDIT_MODE_NAME = "QoL Forever: Reputation widget",
		SECTION_SHOW = "Show",
		SECTION_MAX_LEVEL = "Max level",
		SECTION_LOOK = "Appearance",
		SECTION_SESSION = "Session",
		SHOW_PERCENT = "Progress in percent",
		SHOW_PERCENT_DESC = "Shows the progress within the current standing in percent next to the standing, e.g. Honored · 45.3%.",
		SHOW_RATE = "Reputation per hour and time",
		SHOW_RATE_DESC = "Shows reputation per hour and the time to the next standing for the current session (see {New session}); appears after the first minute with a gain.",
		REPLACE_XP = "Replace the XP widget",
		REPLACE_XP_DESC = "At max level, where the {XP widget} is hidden, this widget moves to the XP widget's place (also in the widget column). Moving it there moves that place. Below max level it stays where you put it.",
		LAYOUT = "Layout",
		LAYOUT_DESC = "Horizontal: wide, with the bar between the text rows. Vertical: narrow, with the bar on the left filling from bottom to top and the texts stacked next to it.",
		LAYOUT_HORIZONTAL = "Horizontal",
		LAYOUT_VERTICAL = "Vertical",
		FONT_SIZE = "Text size",
		FONT_SIZE_DESC = "Size of the widget's text. The widget grows with it.",
		BAR_LENGTH = "Bar length",
		BAR_LENGTH_DESC = "Length of the reputation bar in pixels: its width in the horizontal layout, its height in the vertical one. Auto follows the text size (horizontal) or the text rows (vertical).",
		BAR_THICKNESS = "Bar thickness",
		BAR_THICKNESS_DESC = "Thickness of the reputation bar in pixels: its height in the horizontal layout, its width in the vertical one.",
		AUTO = "Auto",
		BG_OPACITY = "Background opacity",
		BG_OPACITY_DESC = "Opacity of the widget's background and border, 0 % (transparent) to 100 %.",
		RESET = "Reputation per hour",
		RESET_DESC = "Starts counting reputation per hour from now.",
		RESET_BUTTON = "Reset",
		RESET_DONE = "Reputation session reset.",
		STANDING_PERCENT = "%s  ·  %.1f%%",
		VALUES = "%s / %s",
		RATE = "%s/h  ·  %s",
	},
	deDE = {
		TITLE = "Ruf-Widget",
		NOTE = "Beobachtete Fraktion, Fortschritt und Ruf pro Stunde",
		DESC = "Eine kleine verschiebbare Anzeige der Fraktion, die du im Ruf-Reiter beobachtest: Ruf-Stufe, Fortschritt, Ruf pro Stunde und Zeit bis zur nächsten Stufe, aufgebaut wie das {EP-Widget}. Auf Maximalstufe kann es den Platz des EP-Widgets einnehmen. Ausgeblendet, solange keine Fraktion beobachtet wird. Zum Verschieben ziehen; skalieren im {Bearbeitungsmodus}.",
		EDIT_MODE_NAME = "QoL Forever: Ruf-Widget",
		SECTION_SHOW = "Anzeigen",
		SECTION_MAX_LEVEL = "Maximalstufe",
		SECTION_LOOK = "Darstellung",
		SECTION_SESSION = "Sitzung",
		SHOW_PERCENT = "Fortschritt in Prozent",
		SHOW_PERCENT_DESC = "Zeigt den Fortschritt in der aktuellen Ruf-Stufe in Prozent neben der Stufe, z. B. Wohlwollend · 45,3 %.",
		SHOW_RATE = "Ruf pro Stunde und Zeit",
		SHOW_RATE_DESC = "Zeigt Ruf pro Stunde und die Zeit bis zur nächsten Ruf-Stufe für die aktuelle Sitzung (siehe {Neue Sitzung}); erscheint nach der ersten Minute mit Rufgewinn.",
		REPLACE_XP = "EP-Widget ersetzen",
		REPLACE_XP_DESC = "Auf Maximalstufe, wo das {EP-Widget} ausgeblendet ist, rückt dieses Widget an den Platz des EP-Widgets (auch in der Widget-Spalte). Verschiebst du es dort, verschiebt sich dieser Platz. Unter der Maximalstufe bleibt es, wo du es hingesetzt hast.",
		LAYOUT = "Ausrichtung",
		LAYOUT_DESC = "Horizontal: breit, die Leiste zwischen den Textzeilen. Vertikal: schmal, die Leiste links wird von unten nach oben gefüllt, die Texte stehen untereinander daneben.",
		LAYOUT_HORIZONTAL = "Horizontal",
		LAYOUT_VERTICAL = "Vertikal",
		FONT_SIZE = "Textgröße",
		FONT_SIZE_DESC = "Schriftgröße des Widgets. Das Widget wächst mit.",
		BAR_LENGTH = "Leistenlänge",
		BAR_LENGTH_DESC = "Länge der Rufleiste in Pixeln: ihre Breite bei horizontaler, ihre Höhe bei vertikaler Ausrichtung. Automatisch richtet sie sich nach der Textgröße (horizontal) bzw. den Textzeilen (vertikal).",
		BAR_THICKNESS = "Leistendicke",
		BAR_THICKNESS_DESC = "Dicke der Rufleiste in Pixeln: ihre Höhe bei horizontaler, ihre Breite bei vertikaler Ausrichtung.",
		AUTO = "Automatisch",
		BG_OPACITY = "Hintergrund-Deckkraft",
		BG_OPACITY_DESC = "Deckkraft von Hintergrund und Rahmen des Widgets, von 0 % (durchsichtig) bis 100 %.",
		RESET = "Ruf pro Stunde",
		RESET_DESC = "Zählt den Ruf pro Stunde ab jetzt neu.",
		RESET_BUTTON = "Zurücksetzen",
		RESET_DONE = "Ruf-Sitzung zurückgesetzt.",
		STANDING_PERCENT = "%s  ·  %.1f %%",
		VALUES = "%s / %s",
		RATE = "%s/h  ·  %s",
	},
})

local function FormatPercent(value)
	return ("%d%%"):format(value)
end

local function FormatPixels(value)
	return ("%d px"):format(value)
end

local function FormatLength(value)
	return value == 0 and L.AUTO or FormatPixels(value)
end

local module = ns:NewModule("ReputationWidget", {
	title = L.TITLE,
	description = L.DESC,
	note = L.NOTE,
	category = "WIDGETS",
	order = 30,
	defaults = {
		showPercent = true,
		showRate = true,
		replaceXPWidget = false,
		sessionReset = "LOGIN",
		layout = "HORIZONTAL",
		fontSize = 11,
		barLength = 0,
		barThickness = 6,
		backgroundOpacity = 92,
		textOutline = "NONE",
		textShadow = true,
		showTitle = false,
	},
	options = {
		{ type = "header", label = L.SECTION_SHOW },
		{ key = "showPercent", type = "checkbox", label = L.SHOW_PERCENT, tooltip = L.SHOW_PERCENT_DESC },
		{ key = "showRate", type = "checkbox", label = L.SHOW_RATE, tooltip = L.SHOW_RATE_DESC },
		{ type = "header", label = L.SECTION_MAX_LEVEL },
		{ key = "replaceXPWidget", type = "checkbox", label = L.REPLACE_XP, tooltip = L.REPLACE_XP_DESC },
		{ type = "header", label = L.SECTION_LOOK },
		{
			key = "layout",
			type = "dropdown",
			label = L.LAYOUT,
			tooltip = L.LAYOUT_DESC,
			values = {
				{ value = "HORIZONTAL", label = L.LAYOUT_HORIZONTAL },
				{ value = "VERTICAL", label = L.LAYOUT_VERTICAL },
			},
		},
		{ key = "fontSize", type = "slider", label = L.FONT_SIZE, tooltip = L.FONT_SIZE_DESC, min = 8, max = 20, step = 1 },
		ns:TextOutlineOption(),
		ns:TextShadowOption(),
		-- 0 is Auto; anything below MIN_BAR_LENGTH is raised to it.
		{ key = "barLength", type = "slider", label = L.BAR_LENGTH, tooltip = L.BAR_LENGTH_DESC, min = 0, max = 600, step = 10, format = FormatLength },
		{ key = "barThickness", type = "slider", label = L.BAR_THICKNESS, tooltip = L.BAR_THICKNESS_DESC, min = 2, max = 24, step = 1, format = FormatPixels },
		{ key = "backgroundOpacity", type = "slider", label = L.BG_OPACITY, tooltip = L.BG_OPACITY_DESC, min = 0, max = 100, step = 1, format = FormatPercent },
		ns:TitleOption(),
		{ type = "header", label = L.SECTION_SESSION },
		{ key = "sessionReset", type = "dropdown", label = ns.L.SESSION_RESET, tooltip = ns.L.SESSION_RESET_DESC, values = ns.Utils.SessionResetValues() },
		{
			type = "button",
			label = L.RESET,
			buttonText = L.RESET_BUTTON,
			tooltip = L.RESET_DESC,
			onClick = function(self)
				self:ResetSession()
				self:Update()
				self:Print(L.RESET_DONE)
			end,
		},
	},
})

-- Width at the default text size of 11; it scales with the text size.
local BASE_WIDTH, BASE_FONT_SIZE = 260, 11
-- Text column of the vertical layout at the default text size.
local VERTICAL_TEXT_WIDTH = 150
local ROW_GAP = 3
local PADDING = 7
local MIN_BAR_LENGTH = 60
local REFRESH_SECONDS = 5
local DIM_COLOR = { 0.72, 0.72, 0.74 }
-- Overlay key of the XP widget, whose place this widget can take.
local XP_WIDGET_KEY = "XPWidget"

local frame, ticker
-- Online seconds (elapsed until mark, a GetTime()), the next daily reset and,
-- per faction ID, the standing when it was first seen in the session.
local session = { standings = {} }

-- The game's own short notation (e.g. 8.9K), as used in Blizzard's UI.
local Short = AbbreviateNumbers or BreakUpLargeNumbers

function module:ResetSession()
	session.elapsed, session.mark = 0, GetTime()
	session.nextReset = ns.Utils.NextDailyReset()
	session.standings = {}
end

local function Elapsed()
	return session.elapsed + GetTime() - session.mark
end

-- Continues this character's saved session unless the reset mode says a new
-- one is due.
function module:ResumeSession()
	self.db.session = nil -- layout before the reset modes
	self.db.sessions = self.db.sessions or {}
	local saved = self.db.sessions[UnitGUID("player")]
	if saved and saved.standings and not ns.Utils.IsSessionExpired(saved, self.db.sessionReset) then
		session.elapsed, session.nextReset, session.standings = saved.elapsed or 0, saved.nextReset, saved.standings
		session.mark = GetTime()
	else
		self:ResetSession()
	end
end

function module:SaveSession()
	self.db.sessions[UnitGUID("player")] = {
		savedAt = GetTime(),
		elapsed = Elapsed(),
		nextReset = session.nextReset,
		standings = session.standings,
	}
end

local function CreateText(parent, justify)
	local text = parent:CreateFontString(nil, "OVERLAY")
	text:SetFontObject(module.font)
	text:SetJustifyH(justify)
	text:SetWordWrap(false)
	return text
end

local function CreateWidget()
	frame = ns:CreateOverlay("ReputationWidget", {
		title = L.EDIT_MODE_NAME,
		module = module,
		width = BASE_WIDTH,
		height = 44,
		default = { point = "TOP", x = 0, y = -230 },
	})
	-- Positions and justification are set by ApplyLayout.
	frame.Name = CreateText(frame, "LEFT")
	frame.Standing = CreateText(frame, "RIGHT")

	local bar = CreateFrame("StatusBar", nil, frame)
	bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
	local track = bar:CreateTexture(nil, "BACKGROUND")
	track:SetAllPoints()
	track:SetColorTexture(0.22, 0.22, 0.24, 1)
	frame.Bar = bar

	frame.Values = CreateText(frame, "LEFT")
	frame.Values:SetTextColor(unpack(DIM_COLOR))
	frame.Rate = CreateText(frame, "RIGHT")
	frame.Rate:SetTextColor(unpack(DIM_COLOR))
end

local function IsVertical()
	return module.db.layout == "VERTICAL"
end

local function HasText(text)
	return (text:GetText() or "") ~= ""
end

-- Custom bar length in pixels, or nil for Auto.
local function BarLength()
	local length = module.db.barLength
	return length > 0 and math.max(length, MIN_BAR_LENGTH) or nil
end

local function PlaceText(text, justify, width, ...)
	text:SetJustifyH(justify)
	text:SetWidth(width)
	text:SetPoint(...)
end

-- Horizontal: faction name and standing, the bar, then values and rate.
local function LayoutHorizontal(size, lineHeight)
	local bar = frame.Bar
	local barTop = PADDING + lineHeight + 2
	local thickness = module.db.barThickness
	bar:SetOrientation("HORIZONTAL")
	bar:SetHeight(thickness)
	bar:SetPoint("TOPLEFT", PADDING, -barTop)
	bar:SetPoint("TOPRIGHT", -PADDING, -barTop)
	PlaceText(frame.Standing, "RIGHT", 0, "TOPRIGHT", -PADDING, -PADDING)
	-- Long faction names are cut before the standing.
	PlaceText(frame.Name, "LEFT", 0, "TOPLEFT", PADDING, -PADDING)
	frame.Name:SetPoint("RIGHT", frame.Standing, "LEFT", -6, 0)
	PlaceText(frame.Values, "LEFT", 0, "TOPLEFT", bar, "BOTTOMLEFT", 0, -4)
	PlaceText(frame.Rate, "RIGHT", 0, "TOPRIGHT", bar, "BOTTOMRIGHT", 0, -4)
	local length = BarLength()
	frame:SetSize(length and length + PADDING * 2 or math.floor(BASE_WIDTH * size / BASE_FONT_SIZE + 0.5),
		barTop + thickness + 4 + lineHeight + PADDING)
end

-- Vertical: the bar on the left, as high as the text column unless it has a
-- length of its own; empty rows take no space.
local function LayoutVertical(size, lineHeight)
	local rows = { frame.Name, frame.Standing }
	for _, text in ipairs({ frame.Values, frame.Rate }) do
		if HasText(text) then
			rows[#rows + 1] = text
		end
	end
	local thickness = module.db.barThickness
	local textLeft = PADDING + thickness + PADDING
	local textWidth = math.floor(VERTICAL_TEXT_WIDTH * size / BASE_FONT_SIZE + 0.5)
	for i, text in ipairs(rows) do
		PlaceText(text, "LEFT", textWidth, "TOPLEFT", textLeft, -(PADDING + (i - 1) * (lineHeight + ROW_GAP)))
	end
	local rowsHeight = #rows * lineHeight + (#rows - 1) * ROW_GAP
	local bar = frame.Bar
	bar:SetOrientation("VERTICAL")
	local barLength = BarLength() or rowsHeight
	bar:SetSize(thickness, barLength)
	bar:SetPoint("TOPLEFT", PADDING, -PADDING)
	frame:SetSize(textLeft + textWidth + PADDING, math.max(rowsHeight, barLength) + PADDING * 2)
end

-- Font, layout and size follow the text size and, vertically, the shown rows.
function module:ApplyLayout()
	local size = self.db.fontSize
	ns:SetOverlayFont(self.font, size, self.db)
	frame.Bar:ClearAllPoints()
	for _, text in ipairs({ frame.Name, frame.Standing, frame.Values, frame.Rate }) do
		text:ClearAllPoints()
	end
	if IsVertical() then
		LayoutVertical(size, size + 2)
	else
		LayoutHorizontal(size, size + 2)
	end
	ns:SetOverlayBackgroundAlpha(frame, self.db.backgroundOpacity / 100)
end

-- Only the vertical layout depends on which rows have text.
function module:GetLayoutKey()
	if IsVertical() then
		return ("V%d%d"):format(HasText(frame.Values) and 1 or 0, HasText(frame.Rate) and 1 or 0)
	end
	return "H"
end

-- At max level with replaceXPWidget on, the widget sits where the XP widget is
-- saved; the XP widget itself is hidden there.
function module:UpdatePlace()
	local replace = self.enabled and self.db.replaceXPWidget and ns.Utils.IsAtMaxLevel()
	ns:SetOverlayPositionKey(frame, replace and XP_WIDGET_KEY or nil)
end

local function StandingLabel(reaction)
	return GetText("FACTION_STANDING_LABEL" .. reaction, UnitSex("player")) or ""
end

function module:Update()
	if not frame then
		return
	end
	local data = self.enabled and C_Reputation.GetWatchedFactionData()
	frame:SetShown(data and data.factionID and data.factionID ~= 0 or false)
	if not frame:IsShown() then
		return
	end
	if self.db.sessionReset == "DAILY" and time() >= (session.nextReset or 0) then
		self:ResetSession()
	end

	-- Thresholds are absolute standings; the top standing has no next one.
	local min, max, value = data.currentReactionThreshold, data.nextReactionThreshold, data.currentStanding
	local maxed = max <= min

	local color = FACTION_BAR_COLORS and FACTION_BAR_COLORS[data.reaction]
	frame.Name:SetText(data.name)
	local standing = StandingLabel(data.reaction)
	if self.db.showPercent and not maxed then
		standing = L.STANDING_PERCENT:format(standing, (value - min) / (max - min) * 100)
	end
	frame.Standing:SetText(standing)
	if color then
		frame.Standing:SetTextColor(color.r, color.g, color.b)
		frame.Bar:SetStatusBarColor(color.r, color.g, color.b)
	end

	frame.Bar:SetMinMaxValues(0, maxed and 1 or max - min)
	frame.Bar:SetValue(maxed and 1 or value - min)
	frame.Values:SetText(maxed and "" or L.VALUES:format(Short(value - min), Short(max - min)))

	local start = session.standings[data.factionID]
	if not start then
		start = value
		session.standings[data.factionID] = value
	end
	local gain = value - start
	local elapsed = Elapsed()
	if self.db.showRate and not maxed and gain > 0 and elapsed >= 60 then
		local perHour = gain / elapsed * 3600
		local timeLeft = SecondsToTime((max - value) / perHour * 3600, true)
		frame.Rate:SetText(L.RATE:format(Short(math.floor(perHour)), timeLeft))
	else
		frame.Rate:SetText("")
	end

	local layoutKey = self:GetLayoutKey()
	if layoutKey ~= self.layoutKey then
		self.layoutKey = layoutKey
		self:ApplyLayout()
	end
end

function module:UpdateTicker()
	local wanted = self.enabled and self.db.showRate
	if wanted and not ticker then
		ticker = C_Timer.NewTicker(REFRESH_SECONDS, function()
			self:Update()
		end)
	elseif not wanted and ticker then
		ticker:Cancel()
		ticker = nil
	end
end

function module:OnOptionChanged(key)
	if key == "fontSize" or key == "backgroundOpacity" or key == "textOutline" or key == "textShadow"
		or key == "layout" or key == "barLength" or key == "barThickness" then
		self:ApplyLayout()
	end
	if key == "replaceXPWidget" then
		self:UpdatePlace()
	end
	self:UpdateTicker()
	self:Update()
end

function module:OnInitialize()
	self.font = CreateFont("QualityOfLifeForeverReputationWidgetFont")
	self.font:SetFont(STANDARD_TEXT_FONT, BASE_FONT_SIZE, "")
	self.font:SetShadowOffset(1, -1)
	self.font:SetShadowColor(0, 0, 0, 0.8)
end

function module:OnEnable()
	if not frame then
		CreateWidget()
	end
	if not session.mark then
		self:ResumeSession()
	end
	self:ApplyLayout()
	self:RegisterEvent("UPDATE_FACTION", self.Update)
	self:RegisterEvent("PLAYER_LOGOUT", self.SaveSession)
	-- The new level is readable only after the event.
	self:RegisterEvent("PLAYER_LEVEL_UP", function()
		C_Timer.After(0, function()
			if self.enabled then
				self:UpdatePlace()
			end
		end)
	end)
	self:UpdatePlace()
	self:UpdateTicker()
	self:Update()
end

function module:OnDisable()
	self:UpdateTicker()
	self:UpdatePlace()
	frame:Hide()
end
