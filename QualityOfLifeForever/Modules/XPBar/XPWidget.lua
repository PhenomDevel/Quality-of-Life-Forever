-- luacheck: read globals CreateFont STANDARD_TEXT_FONT C_Timer C_QuestLog GetQuestLogRewardXP UnitLevel GetXPExhaustion IsPlayerAtEffectiveMaxLevel AbbreviateNumbers BreakUpLargeNumbers SecondsToTime CreateColorFromHexString MainStatusTrackingBarContainer SecondaryStatusTrackingBarContainer StatusTrackingBarInfo
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "XP widget",
		NOTE = "Small movable XP display",
		DESC = "A compact XP bar with level, progress, rested XP, XP from completed quests, XP per hour and time to level. Drag it to move it; scale it in Edit Mode (Esc > Edit Mode, or right-click the minimap button). Hidden at max level.",
		EDIT_MODE_NAME = "QoL Forever: XP",
		SHOW_RATE = "XP per hour and time to level",
		SHOW_RATE_DESC = "Shows XP per hour and the time to the next level on the right. Counts from login or the last reset in the XP bar options; appears after the first minute with XP. Updated every 3 seconds.",
		SHOW_RESTED = "Rested XP",
		SHOW_RESTED_DESC = "Marks rested XP on the bar and shows it in the text.",
		SHOW_QUESTS = "XP from completed quests",
		SHOW_QUESTS_DESC = "Marks the XP of quests that are ready to turn in on the bar (gold) and shows the sum and number of quests.",
		FONT_SIZE = "Text size",
		FONT_SIZE_DESC = "Size of the widget's text. The widget grows with it.",
		HIDE_BLIZZARD = "Hide the standard XP bar",
		HIDE_BLIZZARD_DESC = "Makes the game's XP bar invisible while the widget is on. Its place stays free, so the action bars don't move; a reputation bar is not affected. The XP bar module then stops updating its text.",
		LEVEL = "Level %d  ·  %.1f%%",
		RATE = "%s/h  ·  %s",
		VALUES = "%s / %s",
		RESTED = "+%s rested",
		QUESTS = "+%s from %d |4quest:quests;",
	},
	deDE = {
		TITLE = "EP-Widget",
		NOTE = "Kleine verschiebbare EP-Anzeige",
		DESC = "Eine kompakte EP-Leiste mit Stufe, Fortschritt, Erholungsbonus, EP aus abgeschlossenen Quests, EP pro Stunde und Zeit bis Level-up. Zum Verschieben ziehen; skalieren im Bearbeitungsmodus (Esc > Bearbeitungsmodus oder Rechtsklick auf den Minimap-Knopf). Auf Maximalstufe ausgeblendet.",
		EDIT_MODE_NAME = "QoL Forever: EP",
		SHOW_RATE = "EP pro Stunde und Zeit bis Level-up",
		SHOW_RATE_DESC = "Zeigt rechts EP pro Stunde und die Zeit bis zur nächsten Stufe. Zählt ab dem Einloggen oder dem letzten Zurücksetzen in den Optionen der Erfahrungsleiste; erscheint nach der ersten Minute mit EP. Wird alle 3 Sekunden aktualisiert.",
		SHOW_RESTED = "Erholungsbonus",
		SHOW_RESTED_DESC = "Markiert den Erholungsbonus auf der Leiste und zeigt ihn im Text.",
		SHOW_QUESTS = "EP aus abgeschlossenen Quests",
		SHOW_QUESTS_DESC = "Markiert die EP von Quests, die abgegeben werden können, auf der Leiste (gold) und zeigt Summe und Anzahl der Quests.",
		FONT_SIZE = "Textgröße",
		FONT_SIZE_DESC = "Schriftgröße des Widgets. Das Widget wächst mit.",
		HIDE_BLIZZARD = "Standard-EP-Leiste ausblenden",
		HIDE_BLIZZARD_DESC = "Macht die EP-Leiste des Spiels unsichtbar, solange das Widget an ist. Ihr Platz bleibt frei, die Aktionsleisten verschieben sich also nicht; eine Rufleiste bleibt sichtbar. Das Modul Erfahrungsleiste aktualisiert ihren Text dann nicht mehr.",
		LEVEL = "Stufe %d  ·  %.1f %%",
		RATE = "%s/h  ·  %s",
		VALUES = "%s / %s",
		RESTED = "+%s erholt",
		QUESTS = "+%s aus %d |4Quest:Quests;",
	},
})

local module = ns:NewModule("XPWidget", {
	title = L.TITLE,
	description = L.DESC,
	note = L.NOTE,
	category = "XP_BAR",
	defaults = {
		showRate = true,
		showRested = true,
		showQuestXP = true,
		fontSize = 11,
		hideBlizzardBar = false,
	},
	options = {
		{ key = "showRate", type = "checkbox", label = L.SHOW_RATE, tooltip = L.SHOW_RATE_DESC },
		{ key = "showRested", type = "checkbox", label = L.SHOW_RESTED, tooltip = L.SHOW_RESTED_DESC },
		{ key = "showQuestXP", type = "checkbox", label = L.SHOW_QUESTS, tooltip = L.SHOW_QUESTS_DESC },
		{ key = "fontSize", type = "slider", label = L.FONT_SIZE, tooltip = L.FONT_SIZE_DESC, min = 8, max = 20, step = 1 },
		{ key = "hideBlizzardBar", type = "checkbox", label = L.HIDE_BLIZZARD, tooltip = L.HIDE_BLIZZARD_DESC },
	},
})

local XPSession = ns.XPSession
-- Width at the default text size of 11; it scales with the text size.
local BASE_WIDTH, BASE_FONT_SIZE = 260, 11
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

	frame.Level = CreateText(frame, "LEFT")
	frame.Level:SetPoint("TOPLEFT", PADDING, -PADDING)
	frame.Rate = CreateText(frame, "RIGHT")
	frame.Rate:SetPoint("TOPRIGHT", -PADDING, -PADDING)
	frame.Rate:SetTextColor(0.72, 0.72, 0.74)

	local bar = CreateFrame("StatusBar", nil, frame)
	bar:SetHeight(BAR_HEIGHT)
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
	for _, segment in ipairs({ bar.Rested, bar.Quests }) do
		segment:SetPoint("TOP")
		segment:SetPoint("BOTTOM")
	end
	frame.Bar = bar

	frame.Values = CreateText(frame, "LEFT")
	frame.Values:SetPoint("TOPLEFT", bar, "BOTTOMLEFT", 0, -4)
	frame.Values:SetTextColor(0.72, 0.72, 0.74)
	frame.Rested = CreateText(frame, "RIGHT")
	frame.Rested:SetPoint("TOPRIGHT", bar, "BOTTOMRIGHT", 0, -4)
	frame.Rested:SetTextColor(RESTED_COLOR[1], RESTED_COLOR[2], RESTED_COLOR[3])

	-- Anchored in UpdateQuests: next to the values, or below rested XP.
	frame.Quests = CreateText(frame, "RIGHT")
	frame.Quests:SetTextColor(QUEST_COLOR[1], QUEST_COLOR[2], QUEST_COLOR[3])
end

local function AtMaxLevel()
	return IsPlayerAtEffectiveMaxLevel and IsPlayerAtEffectiveMaxLevel()
end

-- Shows `segment` from the current XP over `amount` more XP, clipped at the bar end.
local function SetSegment(segment, xp, amount, maxXP)
	if not amount or amount <= 0 then
		segment:Hide()
		return
	end
	local width = frame.Bar:GetWidth()
	local from = xp / maxXP * width
	local to = math.min(1, (xp + amount) / maxXP) * width
	segment:SetPoint("LEFT", frame.Bar, "LEFT", from, 0)
	segment:SetWidth(math.max(1, to - from))
	segment:Show()
end

function module:UpdateRested(xp, maxXP)
	local rested = self.db.showRested and GetXPExhaustion()
	if not rested or ns.Utils.IsSecret(rested) or rested <= 0 then
		rested = nil
	end
	SetSegment(frame.Bar.Rested, xp, rested, maxXP)
	frame.Rested:SetText(rested and L.RESTED:format(Short(rested)) or "")
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

function module:UpdateQuests(xp, maxXP)
	local amount = self.db.showQuestXP and questXP > 0 and questXP or nil
	SetSegment(frame.Bar.Quests, xp, amount, maxXP)
	frame.Quests:SetText(amount and L.QUESTS:format(Short(amount), questCount) or "")
	-- Shares the values row with rested XP; only both together need a 4th row.
	local belowRested = amount ~= nil and (frame.Rested:GetText() or "") ~= ""
	frame.Quests:ClearAllPoints()
	if belowRested then
		frame.Quests:SetPoint("TOPRIGHT", frame.Rested, "BOTTOMRIGHT", 0, -3)
	else
		frame.Quests:SetPoint("TOPRIGHT", frame.Bar, "BOTTOMRIGHT", 0, -4)
	end
	return belowRested
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
	self:UpdateRested(xp, maxXP)
	local extraRow = self:UpdateQuests(xp, maxXP)
	if extraRow ~= self.extraRow then
		self.extraRow = extraRow
		self:ApplyLayout()
	end

	local perHour = self.db.showRate and XPSession.GetPerHour()
	if perHour then
		local timeToLevel = SecondsToTime(XPSession.GetTimeToLevel() or 0, true)
		frame.Rate:SetText(L.RATE:format(Short(math.floor(perHour)), timeToLevel))
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

-- Font, size and bar position follow the text size. A 4th row is only added
-- while rested XP and quest XP are both shown.
function module:ApplyLayout()
	local size = self.db.fontSize
	self.font:SetFont(STANDARD_TEXT_FONT, size, "")
	local lineHeight = size + 2
	local barTop = PADDING + lineHeight + 2
	frame.Bar:ClearAllPoints()
	frame.Bar:SetPoint("TOPLEFT", PADDING, -barTop)
	frame.Bar:SetPoint("TOPRIGHT", -PADDING, -barTop)
	local height = barTop + BAR_HEIGHT + 4 + lineHeight + PADDING
	if self.extraRow then
		height = height + lineHeight + 3
	end
	frame:SetSize(math.floor(BASE_WIDTH * size / BASE_FONT_SIZE + 0.5), height)
end

function module:OnOptionChanged(key)
	if key == "fontSize" or key == "showQuestXP" then
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
