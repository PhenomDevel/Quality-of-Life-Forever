-- luacheck: read globals CreateFont STANDARD_TEXT_FONT C_Timer GetMoney GetTime UnitGUID time
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Gold widget",
		NOTE = "Your gold, gold this session and per hour",
		DESC = "A small movable display of your gold, how much you gained or spent this session and gold per hour. When a new session starts is up to you: on login, daily or only with {Reset}. Drag it to move it; scale it in {Edit Mode}.",
		EDIT_MODE_NAME = "QoL Forever: Gold widget",
		SECTION_SHOW = "Show",
		SECTION_LOOK = "Appearance",
		SECTION_SESSION = "Session",
		SHOW_SESSION = "Gold this session",
		SHOW_SESSION_DESC = "Shows how much gold you gained (green) or spent (red) this session.",
		SHOW_RATE = "Gold per hour",
		SHOW_RATE_DESC = "Shows the session change per hour; appears after the first minute.",
		FONT_SIZE = "Text size",
		FONT_SIZE_DESC = "Size of the widget's text. The widget grows with it.",
		BG_OPACITY = "Background opacity",
		BG_OPACITY_DESC = "Opacity of the widget's background and border, 0 % (transparent) to 100 %.",
		LAYOUT = "Layout",
		LAYOUT_DESC = "Horizontal: everything in one line. Vertical: gold, session and gold per hour stacked.",
		LAYOUT_HORIZONTAL = "Horizontal",
		LAYOUT_VERTICAL = "Vertical",
		RESET = "Gold this session",
		RESET_DESC = "Starts counting gold this session and gold per hour from now.",
		RESET_BUTTON = "Reset",
		RESET_DONE = "Gold session reset.",
		SESSION = "Session: %s",
		RATE = "%s/h",
	},
	deDE = {
		TITLE = "Gold-Widget",
		NOTE = "Dein Gold, Gold dieser Sitzung und pro Stunde",
		DESC = "Eine kleine verschiebbare Anzeige deines Golds, wie viel du in dieser Sitzung verdient oder ausgegeben hast, und Gold pro Stunde. Wann eine neue Sitzung beginnt, legst du fest: beim Einloggen, täglich oder nur mit {Zurücksetzen}. Zum Verschieben ziehen; skalieren im {Bearbeitungsmodus}.",
		EDIT_MODE_NAME = "QoL Forever: Gold-Widget",
		SECTION_SHOW = "Anzeigen",
		SECTION_LOOK = "Darstellung",
		SECTION_SESSION = "Sitzung",
		SHOW_SESSION = "Gold dieser Sitzung",
		SHOW_SESSION_DESC = "Zeigt, wie viel Gold du in dieser Sitzung verdient (grün) oder ausgegeben (rot) hast.",
		SHOW_RATE = "Gold pro Stunde",
		SHOW_RATE_DESC = "Zeigt die Änderung dieser Sitzung pro Stunde; erscheint nach der ersten Minute.",
		FONT_SIZE = "Textgröße",
		FONT_SIZE_DESC = "Schriftgröße des Widgets. Das Widget wächst mit.",
		BG_OPACITY = "Hintergrund-Deckkraft",
		BG_OPACITY_DESC = "Deckkraft von Hintergrund und Rahmen des Widgets, von 0 % (durchsichtig) bis 100 %.",
		LAYOUT = "Ausrichtung",
		LAYOUT_DESC = "Horizontal: alles in einer Zeile. Vertikal: Gold, Sitzung und Gold pro Stunde untereinander.",
		LAYOUT_HORIZONTAL = "Horizontal",
		LAYOUT_VERTICAL = "Vertikal",
		RESET = "Gold dieser Sitzung",
		RESET_DESC = "Zählt Gold dieser Sitzung und Gold pro Stunde ab jetzt neu.",
		RESET_BUTTON = "Zurücksetzen",
		RESET_DONE = "Gold-Sitzung zurückgesetzt.",
		SESSION = "Sitzung: %s",
		RATE = "%s/h",
	},
})

local function FormatPercent(value)
	return ("%d%%"):format(value)
end

local module = ns:NewModule("GoldWidget", {
	title = L.TITLE,
	description = L.DESC,
	note = L.NOTE,
	category = "WIDGETS",
	order = 20,
	defaults = {
		showSession = true,
		sessionReset = "LOGIN",
		showRate = true,
		layout = "HORIZONTAL",
		fontSize = 11,
		backgroundOpacity = 92,
		textOutline = "NONE",
		textShadow = true,
		showTitle = false,
	},
	options = {
		{ type = "header", label = L.SECTION_SHOW },
		{ key = "showSession", type = "checkbox", label = L.SHOW_SESSION, tooltip = L.SHOW_SESSION_DESC },
		{ key = "showRate", type = "checkbox", label = L.SHOW_RATE, tooltip = L.SHOW_RATE_DESC },
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

-- Sizes at the default text size of 11; they scale with the text size.
local BASE_WIDTH, BASE_FONT_SIZE = 200, 11
local PADDING = 7
local ROW_GAP = 3
local COLUMN_GAP = 12
local REFRESH_SECONDS = 5
local GAIN_COLOR = { 0.45, 0.9, 0.45 }
local LOSS_COLOR = { 1, 0.45, 0.45 }
local NEUTRAL_COLOR = { 0.72, 0.72, 0.74 }

local frame, ticker
-- money: gold at the session start; elapsed: online seconds before `mark`
-- (GetTime() of this login or the last save); nextReset: time() of the next
-- daily reset.
local session = {}

local function Money()
	local money = GetMoney()
	if ns.Utils.IsSecret(money) then
		return nil
	end
	return money
end

local function FormatSigned(copper)
	local text = ns.Utils.FormatMoney(math.floor(math.abs(copper)))
	return (copper < 0 and "-" or "+") .. text
end

function module:ResetSession()
	session.money = Money()
	session.elapsed, session.mark = 0, GetTime()
	session.nextReset = ns.Utils.NextDailyReset()
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
	if saved and saved.money and not ns.Utils.IsSessionExpired(saved, self.db.sessionReset) then
		session.money, session.elapsed, session.nextReset = saved.money, saved.elapsed or 0, saved.nextReset
		session.mark = GetTime()
	else
		self:ResetSession()
	end
end

function module:SaveSession()
	self.db.sessions[UnitGUID("player")] = {
		savedAt = GetTime(),
		elapsed = Elapsed(),
		money = session.money,
		nextReset = session.nextReset,
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
	frame = ns:CreateOverlay("GoldWidget", {
		title = L.EDIT_MODE_NAME,
		module = module,
		width = BASE_WIDTH,
		height = 40,
		default = { point = "TOP", x = 0, y = -180 },
	})
	-- Positions are set by ApplyLayout.
	frame.Money = CreateText(frame, "LEFT")
	frame.Session = CreateText(frame, "LEFT")
	frame.Rate = CreateText(frame, "LEFT")
	frame.Rate:SetTextColor(unpack(NEUTRAL_COLOR))
end

local function IsVertical()
	return module.db.layout == "VERTICAL"
end

-- Shown texts in display order.
local function ShownTexts()
	local texts = { frame.Money }
	if module.db.showSession then
		texts[#texts + 1] = frame.Session
	end
	if module.db.showRate then
		texts[#texts + 1] = frame.Rate
	end
	return texts
end

local function Scaled(value)
	return math.floor(value * module.db.fontSize / BASE_FONT_SIZE + 0.5)
end

-- The width follows the texts but only grows until the next ApplyLayout, so
-- the widget doesn't twitch with every coin.
function module:FitWidth()
	local texts, vertical = ShownTexts(), IsVertical()
	local width = vertical and 0 or Scaled(COLUMN_GAP) * (#texts - 1)
	for _, text in ipairs(texts) do
		local textWidth = text:GetUnboundedStringWidth()
		width = vertical and math.max(width, textWidth) or width + textWidth
	end
	width = math.max(math.ceil(width) + PADDING * 2, Scaled(BASE_WIDTH / 2))
	if width > (frame.fitWidth or 0) then
		frame.fitWidth = width
		frame:SetWidth(width)
	end
end

-- Font, positions and height follow the text size, layout and shown texts.
function module:ApplyLayout()
	local size = self.db.fontSize
	ns:SetOverlayFont(self.font, size, self.db)
	frame.Session:SetShown(self.db.showSession)
	frame.Rate:SetShown(self.db.showRate)

	local texts, vertical = ShownTexts(), IsVertical()
	for i, text in ipairs(texts) do
		text:ClearAllPoints()
		if i == 1 then
			text:SetPoint("TOPLEFT", PADDING, -PADDING)
		elseif vertical then
			text:SetPoint("TOPLEFT", texts[i - 1], "BOTTOMLEFT", 0, -ROW_GAP)
		else
			text:SetPoint("LEFT", texts[i - 1], "RIGHT", Scaled(COLUMN_GAP), 0)
		end
	end
	local rows = vertical and #texts or 1
	frame:SetHeight(PADDING * 2 + rows * (size + 2) + (rows - 1) * ROW_GAP)
	ns:SetOverlayBackgroundAlpha(frame, self.db.backgroundOpacity / 100)

	frame.fitWidth = 0
	self:FitWidth()
	-- String widths pick up the new font size only on the next frame.
	C_Timer.After(0, function()
		if self.enabled then
			self:FitWidth()
		end
	end)
end

function module:Update()
	if not frame or not self.enabled then
		return
	end
	local money = Money()
	if not money then
		return
	end
	if self.db.sessionReset == "DAILY" and time() >= (session.nextReset or 0) then
		self:ResetSession()
	end
	session.money = session.money or money
	frame.Money:SetText(ns.Utils.FormatMoney(money))

	local delta = money - session.money
	if self.db.showSession then
		local color = delta > 0 and GAIN_COLOR or delta < 0 and LOSS_COLOR or NEUTRAL_COLOR
		frame.Session:SetText(L.SESSION:format(delta == 0 and "0" or FormatSigned(delta)))
		frame.Session:SetTextColor(unpack(color))
	end

	local elapsed = Elapsed()
	if self.db.showRate and elapsed >= 60 and delta ~= 0 then
		frame.Rate:SetText(L.RATE:format(FormatSigned(delta / elapsed * 3600)))
	else
		frame.Rate:SetText("")
	end
	self:FitWidth()
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
	if key == "fontSize" or key == "showSession" or key == "showRate" or key == "backgroundOpacity" or key == "layout"
		or key == "textOutline" or key == "textShadow" then
		self:ApplyLayout()
	end
	self:UpdateTicker()
	self:Update()
end

function module:OnInitialize()
	self.font = CreateFont("QualityOfLifeForeverGoldWidgetFont")
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
	self:RegisterEvent("PLAYER_MONEY", self.Update)
	self:RegisterEvent("PLAYER_LOGOUT", self.SaveSession)
	frame:Show()
	self:UpdateTicker()
	self:Update()
end

function module:OnDisable()
	self:UpdateTicker()
	frame:Hide()
end
