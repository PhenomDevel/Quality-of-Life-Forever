-- luacheck: read globals CreateFont STANDARD_TEXT_FONT C_Timer GetMoney GetTime UnitGUID
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Gold widget",
		NOTE = "Your gold, gold this session and per hour",
		DESC = "A small movable display of your gold, how much you gained or spent this session and gold per hour. Counts from login or the last {Reset} and continues after a /reload. Drag it to move it; scale it in {Edit Mode}.",
		EDIT_MODE_NAME = "QoL Forever: Gold",
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
		DESC = "Eine kleine verschiebbare Anzeige deines Golds, wie viel du in dieser Sitzung verdient oder ausgegeben hast, und Gold pro Stunde. Zählt ab dem Einloggen oder dem letzten {Zurücksetzen} und läuft nach einem /reload weiter. Zum Verschieben ziehen; skalieren im {Bearbeitungsmodus}.",
		EDIT_MODE_NAME = "QoL Forever: Gold",
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
	defaults = {
		showSession = true,
		showRate = true,
		fontSize = 11,
		backgroundOpacity = 92,
	},
	options = {
		{ type = "header", label = L.SECTION_SHOW },
		{ key = "showSession", type = "checkbox", label = L.SHOW_SESSION, tooltip = L.SHOW_SESSION_DESC },
		{ key = "showRate", type = "checkbox", label = L.SHOW_RATE, tooltip = L.SHOW_RATE_DESC },
		{ type = "header", label = L.SECTION_LOOK },
		{ key = "fontSize", type = "slider", label = L.FONT_SIZE, tooltip = L.FONT_SIZE_DESC, min = 8, max = 20, step = 1 },
		{ key = "backgroundOpacity", type = "slider", label = L.BG_OPACITY, tooltip = L.BG_OPACITY_DESC, min = 0, max = 100, step = 1, format = FormatPercent },
		{ type = "header", label = L.SECTION_SESSION },
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
local BASE_WIDTH, BASE_FONT_SIZE = 200, 11
local PADDING = 7
local ROW_GAP = 3
local REFRESH_SECONDS = 5
-- A /reload keeps the session if the character comes back within this time.
local RESUME_SECONDS = 600
local GAIN_COLOR = { 0.45, 0.9, 0.45 }
local LOSS_COLOR = { 1, 0.45, 0.45 }
local NEUTRAL_COLOR = { 0.72, 0.72, 0.74 }

local frame, ticker
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
	session.start = GetTime()
	session.money = Money()
end

-- Picks up the session saved on logout when it's the same character shortly
-- after (a /reload), otherwise starts a new one.
function module:ResumeSession()
	local saved = self.db.session
	self.db.session = nil
	local age = saved and GetTime() - saved.savedAt
	if age and age >= 0 and age < RESUME_SECONDS and saved.guid == UnitGUID("player") then
		session.start, session.money = saved.start, saved.money
	else
		self:ResetSession()
	end
end

function module:SaveSession()
	self.db.session = {
		guid = UnitGUID("player"),
		savedAt = GetTime(),
		start = session.start,
		money = session.money,
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
		width = BASE_WIDTH,
		height = 40,
		default = { point = "TOP", x = 0, y = -180 },
	})
	frame.Money = CreateText(frame, "LEFT")
	frame.Money:SetPoint("TOPLEFT", PADDING, -PADDING)
	frame.Rate = CreateText(frame, "RIGHT")
	frame.Rate:SetPoint("TOPRIGHT", -PADDING, -PADDING)
	frame.Rate:SetTextColor(unpack(NEUTRAL_COLOR))
	frame.Session = CreateText(frame, "LEFT")
	frame.Session:SetPoint("TOPLEFT", frame.Money, "BOTTOMLEFT", 0, -ROW_GAP)
end

-- Font and size follow the text size; the session row only takes space while shown.
function module:ApplyLayout()
	local size = self.db.fontSize
	self.font:SetFont(STANDARD_TEXT_FONT, size, "")
	local lineHeight = size + 2
	local rows = self.db.showSession and 2 or 1
	frame:SetSize(math.floor(BASE_WIDTH * size / BASE_FONT_SIZE + 0.5), PADDING * 2 + rows * lineHeight + (rows - 1) * ROW_GAP)
	ns:SetOverlayBackgroundAlpha(frame, self.db.backgroundOpacity / 100)
end

function module:Update()
	if not frame or not self.enabled then
		return
	end
	local money = Money()
	if not money then
		return
	end
	session.money = session.money or money
	frame.Money:SetText(ns.Utils.FormatMoney(money))

	local delta = money - session.money
	if self.db.showSession then
		local color = delta > 0 and GAIN_COLOR or delta < 0 and LOSS_COLOR or NEUTRAL_COLOR
		frame.Session:SetText(L.SESSION:format(delta == 0 and "0" or FormatSigned(delta)))
		frame.Session:SetTextColor(unpack(color))
		frame.Session:Show()
	else
		frame.Session:Hide()
	end

	local elapsed = GetTime() - session.start
	if self.db.showRate and elapsed >= 60 and delta ~= 0 then
		frame.Rate:SetText(L.RATE:format(FormatSigned(delta / elapsed * 3600)))
	else
		frame.Rate:SetText("")
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
	if key == "fontSize" or key == "showSession" or key == "backgroundOpacity" then
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
	if not session.start then
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
