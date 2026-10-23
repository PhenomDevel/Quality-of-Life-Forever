-- luacheck: read globals CreateFont STANDARD_TEXT_FONT C_Timer C_Reputation GetTime UnitGUID UnitSex GetText FACTION_BAR_COLORS AbbreviateNumbers BreakUpLargeNumbers SecondsToTime
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Reputation widget",
		NOTE = "Watched faction, progress and reputation per hour",
		DESC = "A small movable display of the faction you watch in the reputation tab: standing, progress, reputation per hour and time to the next standing. Counts from login or the last {Reset} and continues after a /reload. Hidden while no faction is watched. Drag it to move it; scale it in {Edit Mode}.",
		EDIT_MODE_NAME = "QoL Forever: Reputation",
		SECTION_SHOW = "Show",
		SECTION_LOOK = "Appearance",
		SECTION_SESSION = "Session",
		SHOW_RATE = "Reputation per hour and time",
		SHOW_RATE_DESC = "Shows reputation per hour and the time to the next standing; appears after the first minute with a gain.",
		FONT_SIZE = "Text size",
		FONT_SIZE_DESC = "Size of the widget's text. The widget grows with it.",
		BG_OPACITY = "Background opacity",
		BG_OPACITY_DESC = "Opacity of the widget's background and border, 0 % (transparent) to 100 %.",
		RESET = "Reputation per hour",
		RESET_DESC = "Starts counting reputation per hour from now.",
		RESET_BUTTON = "Reset",
		RESET_DONE = "Reputation session reset.",
		VALUES = "%s / %s",
		RATE = "%s/h  ·  %s",
	},
	deDE = {
		TITLE = "Ruf-Widget",
		NOTE = "Beobachtete Fraktion, Fortschritt und Ruf pro Stunde",
		DESC = "Eine kleine verschiebbare Anzeige der Fraktion, die du im Ruf-Reiter beobachtest: Ruf-Stufe, Fortschritt, Ruf pro Stunde und Zeit bis zur nächsten Stufe. Zählt ab dem Einloggen oder dem letzten {Zurücksetzen} und läuft nach einem /reload weiter. Ausgeblendet, solange keine Fraktion beobachtet wird. Zum Verschieben ziehen; skalieren im {Bearbeitungsmodus}.",
		EDIT_MODE_NAME = "QoL Forever: Ruf",
		SECTION_SHOW = "Anzeigen",
		SECTION_LOOK = "Darstellung",
		SECTION_SESSION = "Sitzung",
		SHOW_RATE = "Ruf pro Stunde und Zeit",
		SHOW_RATE_DESC = "Zeigt Ruf pro Stunde und die Zeit bis zur nächsten Ruf-Stufe; erscheint nach der ersten Minute mit Rufgewinn.",
		FONT_SIZE = "Textgröße",
		FONT_SIZE_DESC = "Schriftgröße des Widgets. Das Widget wächst mit.",
		BG_OPACITY = "Hintergrund-Deckkraft",
		BG_OPACITY_DESC = "Deckkraft von Hintergrund und Rahmen des Widgets, von 0 % (durchsichtig) bis 100 %.",
		RESET = "Ruf pro Stunde",
		RESET_DESC = "Zählt den Ruf pro Stunde ab jetzt neu.",
		RESET_BUTTON = "Zurücksetzen",
		RESET_DONE = "Ruf-Sitzung zurückgesetzt.",
		VALUES = "%s / %s",
		RATE = "%s/h  ·  %s",
	},
})

local function FormatPercent(value)
	return ("%d%%"):format(value)
end

local module = ns:NewModule("ReputationWidget", {
	title = L.TITLE,
	description = L.DESC,
	note = L.NOTE,
	category = "WIDGETS",
	defaults = {
		showRate = true,
		fontSize = 11,
		backgroundOpacity = 92,
		textOutline = "NONE",
		textShadow = true,
		showTitle = false,
	},
	options = {
		{ type = "header", label = L.SECTION_SHOW },
		{ key = "showRate", type = "checkbox", label = L.SHOW_RATE, tooltip = L.SHOW_RATE_DESC },
		{ type = "header", label = L.SECTION_LOOK },
		{ key = "fontSize", type = "slider", label = L.FONT_SIZE, tooltip = L.FONT_SIZE_DESC, min = 8, max = 20, step = 1 },
		{ key = "backgroundOpacity", type = "slider", label = L.BG_OPACITY, tooltip = L.BG_OPACITY_DESC, min = 0, max = 100, step = 1, format = FormatPercent },
		ns:TitleOption(),
		ns:TextOutlineOption(),
		ns:TextShadowOption(),
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
local BASE_WIDTH, BASE_FONT_SIZE = 260, 11
local PADDING = 7
local BAR_HEIGHT = 6
local REFRESH_SECONDS = 5
-- A /reload keeps the session if the character comes back within this time.
local RESUME_SECONDS = 600
local DIM_COLOR = { 0.72, 0.72, 0.74 }

local frame, ticker
-- Session start time and, per faction ID, the standing when it was first seen.
local session = { standings = {} }

-- The game's own short notation (e.g. 8.9K), as used in Blizzard's UI.
local Short = AbbreviateNumbers or BreakUpLargeNumbers

function module:ResetSession()
	session.start = GetTime()
	session.standings = {}
end

-- Picks up the session saved on logout when it's the same character shortly
-- after (a /reload), otherwise starts a new one.
function module:ResumeSession()
	local saved = self.db.session
	self.db.session = nil
	local age = saved and GetTime() - saved.savedAt
	if age and age >= 0 and age < RESUME_SECONDS and saved.guid == UnitGUID("player") then
		session.start, session.standings = saved.start, saved.standings or {}
	else
		self:ResetSession()
	end
end

function module:SaveSession()
	self.db.session = {
		guid = UnitGUID("player"),
		savedAt = GetTime(),
		start = session.start,
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
	frame.Standing = CreateText(frame, "RIGHT")
	frame.Standing:SetPoint("TOPRIGHT", -PADDING, -PADDING)
	-- Long faction names are cut before the standing.
	frame.Name = CreateText(frame, "LEFT")
	frame.Name:SetPoint("TOPLEFT", PADDING, -PADDING)
	frame.Name:SetPoint("RIGHT", frame.Standing, "LEFT", -6, 0)

	local bar = CreateFrame("StatusBar", nil, frame)
	bar:SetHeight(BAR_HEIGHT)
	bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
	local track = bar:CreateTexture(nil, "BACKGROUND")
	track:SetAllPoints()
	track:SetColorTexture(0.22, 0.22, 0.24, 1)
	frame.Bar = bar

	frame.Values = CreateText(frame, "LEFT")
	frame.Values:SetPoint("TOPLEFT", bar, "BOTTOMLEFT", 0, -4)
	frame.Values:SetTextColor(unpack(DIM_COLOR))
	frame.Rate = CreateText(frame, "RIGHT")
	frame.Rate:SetPoint("TOPRIGHT", bar, "BOTTOMRIGHT", 0, -4)
	frame.Rate:SetTextColor(unpack(DIM_COLOR))
end

-- Font, size and bar position follow the text size.
function module:ApplyLayout()
	local size = self.db.fontSize
	ns:SetOverlayFont(self.font, size, self.db)
	local lineHeight = size + 2
	local barTop = PADDING + lineHeight + 2
	frame.Bar:ClearAllPoints()
	frame.Bar:SetPoint("TOPLEFT", PADDING, -barTop)
	frame.Bar:SetPoint("TOPRIGHT", -PADDING, -barTop)
	frame:SetSize(math.floor(BASE_WIDTH * size / BASE_FONT_SIZE + 0.5), barTop + BAR_HEIGHT + 4 + lineHeight + PADDING)
	ns:SetOverlayBackgroundAlpha(frame, self.db.backgroundOpacity / 100)
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

	local color = FACTION_BAR_COLORS and FACTION_BAR_COLORS[data.reaction]
	frame.Name:SetText(data.name)
	frame.Standing:SetText(StandingLabel(data.reaction))
	if color then
		frame.Standing:SetTextColor(color.r, color.g, color.b)
		frame.Bar:SetStatusBarColor(color.r, color.g, color.b)
	end

	-- Thresholds are absolute standings; the top standing has no next one.
	local min, max, value = data.currentReactionThreshold, data.nextReactionThreshold, data.currentStanding
	local maxed = max <= min
	frame.Bar:SetMinMaxValues(0, maxed and 1 or max - min)
	frame.Bar:SetValue(maxed and 1 or value - min)
	frame.Values:SetText(maxed and "" or L.VALUES:format(Short(value - min), Short(max - min)))

	local start = session.standings[data.factionID]
	if not start then
		start = value
		session.standings[data.factionID] = value
	end
	local gain = value - start
	local elapsed = GetTime() - session.start
	if self.db.showRate and not maxed and gain > 0 and elapsed >= 60 then
		local perHour = gain / elapsed * 3600
		local timeLeft = SecondsToTime((max - value) / perHour * 3600, true)
		frame.Rate:SetText(L.RATE:format(Short(math.floor(perHour)), timeLeft))
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
	if key == "fontSize" or key == "backgroundOpacity" or key == "textOutline" or key == "textShadow" then
		self:ApplyLayout()
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
	if not session.start then
		self:ResumeSession()
	end
	self:ApplyLayout()
	self:RegisterEvent("UPDATE_FACTION", self.Update)
	self:RegisterEvent("PLAYER_LOGOUT", self.SaveSession)
	self:UpdateTicker()
	self:Update()
end

function module:OnDisable()
	self:UpdateTicker()
	frame:Hide()
end
