-- luacheck: read globals CreateFont STANDARD_TEXT_FONT C_Timer C_QuestLog GetQuestLogRewardXP UnitLevel GetXPExhaustion IsPlayerAtEffectiveMaxLevel AbbreviateNumbers BreakUpLargeNumbers CreateColorFromHexString MainStatusTrackingBarContainer SecondaryStatusTrackingBarContainer StatusTrackingBarInfo
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "XP widget",
		NOTE = "Small movable XP display",
		DESC = "A compact XP bar with level, progress, rested XP, XP from completed quests, XP per hour and time to level. Drag it to move it; scale it in {Edit Mode} (Esc > {Edit Mode}, or right-click the minimap button). Hidden at max level.",
		EDIT_MODE_NAME = "QoL Forever: XP",
		SECTION_SHOW = "Show",
		SECTION_LOOK = "Appearance",
		SECTION_BAR = "Standard XP bar",
		SHOW_RATE = "XP per hour and time to level",
		SHOW_RATE_DESC = "Shows XP per hour and the time to the next level. Counts from login or the last {Reset} in the {Experience bar} module; appears after the first minute with XP. Updated every 3 seconds.",
		SHOW_RESTED = "Rested XP",
		SHOW_RESTED_DESC = "Marks rested XP on the bar and shows it in the text.",
		SHOW_QUESTS = "XP from completed quests",
		SHOW_QUESTS_DESC = "Marks the XP of quests that are ready to turn in on the bar (gold) and shows the sum and number of quests.",
		LAYOUT = "Layout",
		LAYOUT_DESC = "Horizontal: wide, with the bar between the text rows. Vertical: narrow, with the bar on the left filling from bottom to top and the texts stacked next to it.",
		LAYOUT_HORIZONTAL = "Horizontal",
		LAYOUT_VERTICAL = "Vertical",
		FONT_SIZE = "Text size",
		FONT_SIZE_DESC = "Size of the widget's text. The widget grows with it.",
		BG_OPACITY = "Background opacity",
		BG_OPACITY_DESC = "Opacity of the widget's background and border, 0 % (transparent) to 100 %. Text and bar stay as they are.",
		HIDE_BLIZZARD = "Hide the standard XP bar",
		HIDE_BLIZZARD_DESC = "Makes the game's XP bar invisible while the widget is on. Its place stays free, so the action bars don't move; a reputation bar is not affected. The {Experience bar} module then stops updating its text.",
		LEVEL = "Level %d  ·  %.1f%%",
		RATE = "%s/h  ·  %s",
		VALUES = "%s / %s",
		RESTED = "+%s rested",
		QUESTS = "+%s from %d |4quest:quests;",
	},
	deDE = {
		TITLE = "EP-Widget",
		NOTE = "Kleine verschiebbare EP-Anzeige",
		DESC = "Eine kompakte EP-Leiste mit Stufe, Fortschritt, Erholungsbonus, EP aus abgeschlossenen Quests, EP pro Stunde und Zeit bis Level-up. Zum Verschieben ziehen; skalieren im {Bearbeitungsmodus} (Esc > {Bearbeitungsmodus} oder Rechtsklick auf den Minimap-Button). Auf Maximalstufe ausgeblendet.",
		EDIT_MODE_NAME = "QoL Forever: EP",
		SECTION_SHOW = "Anzeigen",
		SECTION_LOOK = "Darstellung",
		SECTION_BAR = "Standard-EP-Leiste",
		SHOW_RATE = "EP pro Stunde und Zeit bis Level-up",
		SHOW_RATE_DESC = "Zeigt EP pro Stunde und die Zeit bis zur nächsten Stufe. Zählt ab dem Einloggen oder dem letzten {Zurücksetzen} im Modul {Erfahrungsleiste}; erscheint nach der ersten Minute mit EP. Wird alle 3 Sekunden aktualisiert.",
		SHOW_RESTED = "Erholungsbonus",
		SHOW_RESTED_DESC = "Markiert den Erholungsbonus auf der Leiste und zeigt ihn im Text.",
		SHOW_QUESTS = "EP aus abgeschlossenen Quests",
		SHOW_QUESTS_DESC = "Markiert die EP von Quests, die abgegeben werden können, auf der Leiste (gold) und zeigt Summe und Anzahl der Quests.",
		LAYOUT = "Ausrichtung",
		LAYOUT_DESC = "Horizontal: breit, die Leiste zwischen den Textzeilen. Vertikal: schmal, die Leiste links wird von unten nach oben gefüllt, die Texte stehen untereinander daneben.",
		LAYOUT_HORIZONTAL = "Horizontal",
		LAYOUT_VERTICAL = "Vertikal",
		FONT_SIZE = "Textgröße",
		FONT_SIZE_DESC = "Schriftgröße des Widgets. Das Widget wächst mit.",
		BG_OPACITY = "Hintergrund-Deckkraft",
		BG_OPACITY_DESC = "Deckkraft von Hintergrund und Rahmen des Widgets, von 0 % (durchsichtig) bis 100 %. Text und Leiste bleiben unverändert.",
		HIDE_BLIZZARD = "Standard-EP-Leiste ausblenden",
		HIDE_BLIZZARD_DESC = "Macht die EP-Leiste des Spiels unsichtbar, solange das Widget an ist. Ihr Platz bleibt frei, die Aktionsleisten verschieben sich also nicht; eine Rufleiste bleibt sichtbar. Das Modul {Erfahrungsleiste} aktualisiert ihren Text dann nicht mehr.",
		LEVEL = "Stufe %d  ·  %.1f %%",
		RATE = "%s/h  ·  %s",
		VALUES = "%s / %s",
		RESTED = "+%s erholt",
		QUESTS = "+%s aus %d |4Quest:Quests;",
	},
})

local function FormatPercent(value)
	return ("%d%%"):format(value)
end

local module = ns:NewModule("XPWidget", {
	title = L.TITLE,
	description = L.DESC,
	note = L.NOTE,
	category = "WIDGETS",
	defaults = {
		showRate = true,
		showRested = true,
		showQuestXP = true,
		layout = "HORIZONTAL",
		fontSize = 11,
		backgroundOpacity = 92,
		hideBlizzardBar = false,
	},
	options = {
		{ type = "header", label = L.SECTION_SHOW },
		{ key = "showRate", type = "checkbox", label = L.SHOW_RATE, tooltip = L.SHOW_RATE_DESC },
		{ key = "showRested", type = "checkbox", label = L.SHOW_RESTED, tooltip = L.SHOW_RESTED_DESC },
		{ key = "showQuestXP", type = "checkbox", label = L.SHOW_QUESTS, tooltip = L.SHOW_QUESTS_DESC },
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
		{ key = "backgroundOpacity", type = "slider", label = L.BG_OPACITY, tooltip = L.BG_OPACITY_DESC, min = 0, max = 100, step = 1, format = FormatPercent },
		{ type = "header", label = L.SECTION_BAR },
		{ key = "hideBlizzardBar", type = "checkbox", label = L.HIDE_BLIZZARD, tooltip = L.HIDE_BLIZZARD_DESC },
	},
})

local XPSession = ns.XPSession
-- Width at the default text size of 11; it scales with the text size.
local BASE_WIDTH, BASE_FONT_SIZE = 260, 11
-- Text column of the vertical layout at the default text size.
local VERTICAL_TEXT_WIDTH = 150
local ROW_GAP = 3
local PADDING = 7
local BAR_HEIGHT = 6
local REFRESH_SECONDS = 3
local ACCENT = CreateColorFromHexString("ff" .. ns.color)
local RESTED_COLOR = { 0.72, 0.5, 1, 0.65 }
local QUEST_COLOR = { 1, 0.78, 0.25, 0.8 }
local QUEST_SCAN_DELAY = 0.5

local frame, ticker

-- The game's own short notation (e.g. 8.9K), as used in Blizzard's UI.
local Short = AbbreviateNumbers or BreakUpLargeNumbers

local function CreateText(parent, justify)
	local text = parent:CreateFontString(nil, "OVERLAY")
	text:SetFontObject(module.font)
	text:SetJustifyH(justify)
	text:SetWordWrap(false)
	return text
end

local function CreateWidget()
	frame = ns:CreateOverlay("XPWidget", {
		title = L.EDIT_MODE_NAME,
		width = BASE_WIDTH,
		height = 44,
		default = { point = "TOP", x = 0, y = -120 },
	})

	-- Positions and justification are set by ApplyLayout.
	frame.Level = CreateText(frame, "LEFT")
	frame.Rate = CreateText(frame, "RIGHT")
	frame.Rate:SetTextColor(0.72, 0.72, 0.74)

	local bar = CreateFrame("StatusBar", nil, frame)
	bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
	bar:SetStatusBarColor(ACCENT:GetRGB())
	local track = bar:CreateTexture(nil, "BACKGROUND")
	track:SetAllPoints()
	track:SetColorTexture(0.22, 0.22, 0.24, 1)
	-- Segments after the current XP: completed quests on top of rested XP.
	bar.Rested = bar:CreateTexture(nil, "ARTWORK", nil, -2)
	bar.Rested:SetColorTexture(unpack(RESTED_COLOR))
	bar.Quests = bar:CreateTexture(nil, "ARTWORK", nil, -1)
	bar.Quests:SetColorTexture(unpack(QUEST_COLOR))
	frame.Bar = bar

	frame.Values = CreateText(frame, "LEFT")
	frame.Values:SetTextColor(0.72, 0.72, 0.74)
	frame.Rested = CreateText(frame, "RIGHT")
	frame.Rested:SetTextColor(RESTED_COLOR[1], RESTED_COLOR[2], RESTED_COLOR[3])
	frame.Quests = CreateText(frame, "RIGHT")
	frame.Quests:SetTextColor(QUEST_COLOR[1], QUEST_COLOR[2], QUEST_COLOR[3])
end

local function AtMaxLevel()
	return IsPlayerAtEffectiveMaxLevel and IsPlayerAtEffectiveMaxLevel()
end

local function IsVertical()
	return module.db.layout == "VERTICAL"
end

local function HasText(text)
	return (text:GetText() or "") ~= ""
end

-- Shows `segment` from the current XP over `amount` more XP, clipped at the bar
-- end; along the width, or the height in the vertical layout.
local function SetSegment(segment, xp, amount, maxXP)
	if not amount or amount <= 0 then
		segment:Hide()
		return
	end
	local vertical = IsVertical()
	local length = vertical and frame.Bar:GetHeight() or frame.Bar:GetWidth()
	local from = xp / maxXP * length
	local size = math.max(1, math.min(1, (xp + amount) / maxXP) * length - from)
	segment:ClearAllPoints()
	if vertical then
		segment:SetPoint("LEFT")
		segment:SetPoint("RIGHT")
		segment:SetPoint("BOTTOM", frame.Bar, "BOTTOM", 0, from)
		segment:SetHeight(size)
	else
		segment:SetPoint("TOP")
		segment:SetPoint("BOTTOM")
		segment:SetPoint("LEFT", frame.Bar, "LEFT", from, 0)
		segment:SetWidth(size)
	end
	segment:Show()
end

local function GetRested(self)
	local rested = self.db.showRested and GetXPExhaustion()
	if not rested or ns.Utils.IsSecret(rested) or rested <= 0 then
		return nil
	end
	return rested
end

-- Completed quests -------------------------------------------------------------
-- The quest log changes often (QUEST_LOG_UPDATE), so scans are batched.

local questXP, questCount = 0, 0
local questScan

local function IsDone(questID)
	return C_QuestLog.ReadyForTurnIn(questID) or C_QuestLog.IsComplete(questID)
end

local function ScanQuests()
	local total, count = 0, 0
	for index = 1, C_QuestLog.GetNumQuestLogEntries() do
		local info = C_QuestLog.GetInfo(index)
		if info and not info.isHeader and info.questID and IsDone(info.questID) then
			local reward = GetQuestLogRewardXP(info.questID)
			if type(reward) == "number" and not ns.Utils.IsSecret(reward) and reward > 0 then
				total, count = total + reward, count + 1
			end
		end
	end
	questXP, questCount = total, count
end

function module:QueueQuestScan()
	if questScan or not self.db.showQuestXP then
		return
	end
	questScan = C_Timer.NewTimer(QUEST_SCAN_DELAY, function()
		questScan = nil
		if self.enabled then
			ScanQuests()
			self:Update()
		end
	end)
end

-- Rows that are shown decide the size: in the horizontal layout only a 4th
-- row for quest XP below rested XP, in the vertical one every optional row.
function module:GetLayoutKey()
	if IsVertical() then
		return ("V%d%d%d"):format(HasText(frame.Rested) and 1 or 0, HasText(frame.Quests) and 1 or 0, HasText(frame.Rate) and 1 or 0)
	end
	return (HasText(frame.Rested) and HasText(frame.Quests)) and "H4" or "H3"
end

function module:Update()
	if not frame then
		return
	end
	frame:SetShown(self.enabled and not AtMaxLevel())
	if not frame:IsShown() then
		return
	end
	local xp, maxXP = XPSession.Read()
	if not xp or maxXP <= 0 then
		-- Secret or not loaded yet; keep the last values.
		return
	end
	frame.Level:SetText(L.LEVEL:format(UnitLevel("player"), xp / maxXP * 100))
	frame.Bar:SetMinMaxValues(0, maxXP)
	frame.Bar:SetValue(xp)
	frame.Values:SetText(L.VALUES:format(Short(xp), Short(maxXP)))
	local rested = GetRested(self)
	frame.Rested:SetText(rested and L.RESTED:format(Short(rested)) or "")
	local quests = self.db.showQuestXP and questXP > 0 and questXP or nil
	frame.Quests:SetText(quests and L.QUESTS:format(Short(quests), questCount) or "")
	local perHour = self.db.showRate and XPSession.GetPerHour()
	if perHour then
		local timeToLevel = XPSession.FormatTimeToLevel() or ""
		frame.Rate:SetText(L.RATE:format(Short(math.floor(perHour)), timeToLevel))
	else
		frame.Rate:SetText("")
	end

	local layoutKey = self:GetLayoutKey()
	if layoutKey ~= self.layoutKey then
		self.layoutKey = layoutKey
		self:ApplyLayout()
	end
	-- After the layout, which sets the bar length.
	SetSegment(frame.Bar.Rested, xp, rested, maxXP)
	SetSegment(frame.Bar.Quests, xp, quests, maxXP)
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

-- Standard XP bar ---------------------------------------------------------------
-- Made invisible through the alpha of its container (bar, frame art and
-- dividers together) instead of Hide(): its shown state feeds the action bar
-- layout, which addon code must not change. Blizzard fades the container in
-- when it switches bars, so the alpha is re-applied after that.

local CONTAINERS = { "MainStatusTrackingBarContainer", "SecondaryStatusTrackingBarContainer" }
local hiddenContainers = {}

local function ShowsPlayerXP(container)
	local bar = container.GetShownBar and container:GetShownBar()
	return bar ~= nil and bar.barIndex == StatusTrackingBarInfo.BarsEnum.Experience, bar
end

function module:IsBlizzardBarHidden()
	return self.enabled and self.db.hideBlizzardBar
end

function module:UpdateBlizzardBar()
	local hide = self:IsBlizzardBarHidden()
	for _, name in ipairs(CONTAINERS) do
		local container = _G[name]
		if container then
			local showsXP, bar = ShowsPlayerXP(container)
			if hide and showsXP then
				hiddenContainers[container] = true
				container:SetAlpha(0)
				bar:EnableMouse(false)
			elseif hiddenContainers[container] then
				hiddenContainers[container] = nil
				container:SetAlpha(1)
				for _, containerBar in pairs(container.bars or {}) do
					containerBar:EnableMouse(true)
				end
			end
		end
	end
	ns.blizzardXPBarHidden = hide
	-- The XP bar module skips its text updates while the bar is invisible.
	local xpBar = ns:GetModule("XPBar")
	if xpBar and xpBar.enabled then
		xpBar:UpdateTicker()
		xpBar:RefreshBarText()
	end
end

function module:HookContainers()
	for _, name in ipairs(CONTAINERS) do
		local container = _G[name]
		if container then
			self:SecureHook(container, "ApplyPendingBarToShow", self.UpdateBlizzardBar)
			if container.FadeInAnimation then
				self:HookScript(container.FadeInAnimation, "OnFinished", self.UpdateBlizzardBar)
			end
		end
	end
end

local function PlaceText(text, justify, width, ...)
	text:SetJustifyH(justify)
	text:SetWidth(width)
	text:SetPoint(...)
end

-- Horizontal: level and rate, the bar, then values with rested XP and quest XP
-- (in a 4th row below rested XP when both are shown).
local function LayoutHorizontal(size, lineHeight)
	local bar = frame.Bar
	local barTop = PADDING + lineHeight + 2
	bar:SetOrientation("HORIZONTAL")
	bar:SetHeight(BAR_HEIGHT)
	bar:SetPoint("TOPLEFT", PADDING, -barTop)
	bar:SetPoint("TOPRIGHT", -PADDING, -barTop)
	PlaceText(frame.Level, "LEFT", 0, "TOPLEFT", PADDING, -PADDING)
	PlaceText(frame.Rate, "RIGHT", 0, "TOPRIGHT", -PADDING, -PADDING)
	PlaceText(frame.Values, "LEFT", 0, "TOPLEFT", bar, "BOTTOMLEFT", 0, -4)
	PlaceText(frame.Rested, "RIGHT", 0, "TOPRIGHT", bar, "BOTTOMRIGHT", 0, -4)
	local height = barTop + BAR_HEIGHT + 4 + lineHeight + PADDING
	if HasText(frame.Rested) and HasText(frame.Quests) then
		PlaceText(frame.Quests, "RIGHT", 0, "TOPRIGHT", frame.Rested, "BOTTOMRIGHT", 0, -ROW_GAP)
		height = height + lineHeight + ROW_GAP
	else
		PlaceText(frame.Quests, "RIGHT", 0, "TOPRIGHT", bar, "BOTTOMRIGHT", 0, -4)
	end
	frame:SetSize(math.floor(BASE_WIDTH * size / BASE_FONT_SIZE + 0.5), height)
end

-- Vertical: the bar on the left as high as the text column; empty optional
-- rows take no space.
local function LayoutVertical(size, lineHeight)
	local rows = { frame.Level, frame.Values }
	for _, text in ipairs({ frame.Rested, frame.Quests, frame.Rate }) do
		if HasText(text) then
			rows[#rows + 1] = text
		end
	end
	local textLeft = PADDING + BAR_HEIGHT + PADDING
	local textWidth = math.floor(VERTICAL_TEXT_WIDTH * size / BASE_FONT_SIZE + 0.5)
	for i, text in ipairs(rows) do
		PlaceText(text, "LEFT", textWidth, "TOPLEFT", textLeft, -(PADDING + (i - 1) * (lineHeight + ROW_GAP)))
	end
	local contentHeight = #rows * lineHeight + (#rows - 1) * ROW_GAP
	local bar = frame.Bar
	bar:SetOrientation("VERTICAL")
	bar:SetSize(BAR_HEIGHT, contentHeight)
	bar:SetPoint("TOPLEFT", PADDING, -PADDING)
	frame:SetSize(textLeft + textWidth + PADDING, contentHeight + PADDING * 2)
end

-- Font, layout and size follow the text size and the shown rows.
function module:ApplyLayout()
	local size = self.db.fontSize
	self.font:SetFont(STANDARD_TEXT_FONT, size, "")
	frame.Bar:ClearAllPoints()
	for _, text in ipairs({ frame.Level, frame.Rate, frame.Values, frame.Rested, frame.Quests }) do
		text:ClearAllPoints()
	end
	if IsVertical() then
		LayoutVertical(size, size + 2)
	else
		LayoutHorizontal(size, size + 2)
	end
	ns:SetOverlayBackgroundAlpha(frame, self.db.backgroundOpacity / 100)
end

function module:OnOptionChanged(key)
	if key == "fontSize" or key == "showQuestXP" or key == "backgroundOpacity" or key == "layout" then
		self:ApplyLayout()
	end
	if key == "hideBlizzardBar" then
		self:UpdateBlizzardBar()
		return
	end
	if key == "showQuestXP" then
		self:QueueQuestScan()
	end
	self:UpdateTicker()
	self:Update()
end

function module:OnInitialize()
	self.font = CreateFont("QualityOfLifeForeverXPWidgetFont")
	self.font:SetFont(STANDARD_TEXT_FONT, BASE_FONT_SIZE, "")
	self.font:SetShadowOffset(1, -1)
	self.font:SetShadowColor(0, 0, 0, 0.8)
end

function module:OnEnable()
	if not frame then
		CreateWidget()
	end
	self:ApplyLayout()
	XPSession.RegisterListener(self, function()
		if self.enabled then
			self:Update()
		end
	end)
	-- XPSession only reports gains; these cover level-ups, rested and resets.
	self:RegisterEvent("PLAYER_XP_UPDATE", self.Update)
	self:RegisterEvent("PLAYER_LEVEL_UP", function()
		C_Timer.After(0, function()
			self:Update()
		end)
	end)
	self:RegisterEvent("UPDATE_EXHAUSTION", self.Update)
	self:RegisterEvent("QUEST_LOG_UPDATE", self.QueueQuestScan)
	self:RegisterEvent("QUEST_TURNED_IN", self.QueueQuestScan)
	self:QueueQuestScan()
	self:UpdateTicker()
	self:Update()
	self:HookContainers()
	self:UpdateBlizzardBar()
end

function module:OnDisable()
	XPSession.RegisterListener(self, nil)
	self:UpdateTicker()
	self:UpdateBlizzardBar()
	frame:Hide()
end
