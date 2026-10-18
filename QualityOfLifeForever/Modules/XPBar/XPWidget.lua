-- luacheck: read globals C_Timer UnitLevel GetXPExhaustion IsPlayerAtEffectiveMaxLevel BreakUpLargeNumbers SecondsToTime CreateColorFromHexString MainStatusTrackingBarContainer SecondaryStatusTrackingBarContainer StatusTrackingBarInfo
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "XP widget",
		NOTE = "Small movable XP display",
		DESC = "A compact XP bar with level, progress, rested XP, XP per hour and time to level. Move and scale it in Edit Mode (Esc > Edit Mode, or right-click the minimap button). Hidden at max level.",
		EDIT_MODE_NAME = "QoL Forever: XP",
		SHOW_RATE = "XP per hour and time to level",
		SHOW_RATE_DESC = "Shows XP per hour and the time to the next level on the right. Counts from login or the last reset in the XP bar options; appears after the first minute with XP.",
		SHOW_RESTED = "Rested XP",
		SHOW_RESTED_DESC = "Marks rested XP on the bar and shows it in the text.",
		HIDE_BLIZZARD = "Hide the standard XP bar",
		HIDE_BLIZZARD_DESC = "Makes the game's XP bar invisible while the widget is on. Its place stays free, so the action bars don't move; a reputation bar is not affected. The XP bar module then stops updating its text.",
		LEVEL = "Level %d  ·  %.1f%%",
		RATE = "%s/h  ·  %s",
		VALUES = "%s / %s",
		RESTED = "+%s rested",
	},
	deDE = {
		TITLE = "EP-Widget",
		NOTE = "Kleine verschiebbare EP-Anzeige",
		DESC = "Eine kompakte EP-Leiste mit Stufe, Fortschritt, Erholungsbonus, EP pro Stunde und Zeit bis Level-up. Verschieben und skalieren im Bearbeitungsmodus (Esc > Bearbeitungsmodus oder Rechtsklick auf den Minimap-Knopf). Auf Maximalstufe ausgeblendet.",
		EDIT_MODE_NAME = "QoL Forever: EP",
		SHOW_RATE = "EP pro Stunde und Zeit bis Level-up",
		SHOW_RATE_DESC = "Zeigt rechts EP pro Stunde und die Zeit bis zur nächsten Stufe. Zählt ab dem Einloggen oder dem letzten Zurücksetzen in den Optionen der Erfahrungsleiste; erscheint nach der ersten Minute mit EP.",
		SHOW_RESTED = "Erholungsbonus",
		SHOW_RESTED_DESC = "Markiert den Erholungsbonus auf der Leiste und zeigt ihn im Text.",
		HIDE_BLIZZARD = "Standard-EP-Leiste ausblenden",
		HIDE_BLIZZARD_DESC = "Macht die EP-Leiste des Spiels unsichtbar, solange das Widget an ist. Ihr Platz bleibt frei, die Aktionsleisten verschieben sich also nicht; eine Rufleiste bleibt sichtbar. Das Modul Erfahrungsleiste aktualisiert ihren Text dann nicht mehr.",
		LEVEL = "Stufe %d  ·  %.1f %%",
		RATE = "%s/h  ·  %s",
		VALUES = "%s / %s",
		RESTED = "+%s erholt",
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
		hideBlizzardBar = false,
	},
	options = {
		{ key = "showRate", type = "checkbox", label = L.SHOW_RATE, tooltip = L.SHOW_RATE_DESC },
		{ key = "showRested", type = "checkbox", label = L.SHOW_RESTED, tooltip = L.SHOW_RESTED_DESC },
		{ key = "hideBlizzardBar", type = "checkbox", label = L.HIDE_BLIZZARD, tooltip = L.HIDE_BLIZZARD_DESC },
	},
})

local XPSession = ns.XPSession
local WIDTH, HEIGHT = 260, 44
local PADDING = 7
local BAR_HEIGHT = 6
local REFRESH_SECONDS = 15
local ACCENT = CreateColorFromHexString("ff" .. ns.color)
local RESTED_COLOR = { 0.4, 0.6, 1, 0.6 }

local frame, ticker

local function CreateText(parent, justify)
	local text = parent:CreateFontString(nil, "OVERLAY")
	text:SetFontObject(ns.overlayFont)
	text:SetJustifyH(justify)
	text:SetWordWrap(false)
	return text
end

local function CreateWidget()
	frame = ns:CreateOverlay("XPWidget", {
		title = L.EDIT_MODE_NAME,
		width = WIDTH,
		height = HEIGHT,
		default = { point = "TOP", x = 0, y = -120 },
	})

	frame.Level = CreateText(frame, "LEFT")
	frame.Level:SetPoint("TOPLEFT", PADDING, -PADDING)
	frame.Rate = CreateText(frame, "RIGHT")
	frame.Rate:SetPoint("TOPRIGHT", -PADDING, -PADDING)
	frame.Rate:SetTextColor(0.72, 0.72, 0.74)

	local bar = CreateFrame("StatusBar", nil, frame)
	bar:SetPoint("TOPLEFT", PADDING, -(PADDING + 14))
	bar:SetPoint("TOPRIGHT", -PADDING, -(PADDING + 14))
	bar:SetHeight(BAR_HEIGHT)
	bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
	bar:SetStatusBarColor(ACCENT:GetRGB())
	local track = bar:CreateTexture(nil, "BACKGROUND")
	track:SetAllPoints()
	track:SetColorTexture(0.22, 0.22, 0.24, 1)
	-- Rested XP: from the end of the current XP up to current + rested.
	bar.Rested = bar:CreateTexture(nil, "ARTWORK", nil, -1)
	bar.Rested:SetColorTexture(unpack(RESTED_COLOR))
	bar.Rested:SetPoint("TOP")
	bar.Rested:SetPoint("BOTTOM")
	frame.Bar = bar

	frame.Values = CreateText(frame, "LEFT")
	frame.Values:SetPoint("BOTTOMLEFT", PADDING, PADDING - 2)
	frame.Values:SetTextColor(0.72, 0.72, 0.74)
	frame.Rested = CreateText(frame, "RIGHT")
	frame.Rested:SetPoint("BOTTOMRIGHT", -PADDING, PADDING - 2)
	frame.Rested:SetTextColor(RESTED_COLOR[1], RESTED_COLOR[2], RESTED_COLOR[3])
end

local function AtMaxLevel()
	return IsPlayerAtEffectiveMaxLevel and IsPlayerAtEffectiveMaxLevel()
end

function module:UpdateRested(xp, maxXP)
	local bar = frame.Bar
	local rested = self.db.showRested and GetXPExhaustion()
	if not rested or ns.Utils.IsSecret(rested) or rested <= 0 then
		bar.Rested:Hide()
		frame.Rested:SetText("")
		return
	end
	local width = bar:GetWidth()
	local from = xp / maxXP * width
	local to = math.min(1, (xp + rested) / maxXP) * width
	bar.Rested:SetPoint("LEFT", bar, "LEFT", from, 0)
	bar.Rested:SetWidth(math.max(1, to - from))
	bar.Rested:Show()
	frame.Rested:SetText(L.RESTED:format(BreakUpLargeNumbers(rested)))
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
	frame.Values:SetText(L.VALUES:format(BreakUpLargeNumbers(xp), BreakUpLargeNumbers(maxXP)))
	self:UpdateRested(xp, maxXP)

	local perHour = self.db.showRate and XPSession.GetPerHour()
	if perHour then
		local timeToLevel = SecondsToTime(XPSession.GetTimeToLevel() or 0, true)
		frame.Rate:SetText(L.RATE:format(BreakUpLargeNumbers(math.floor(perHour)), timeToLevel))
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

function module:OnOptionChanged(key)
	if key == "hideBlizzardBar" then
		self:UpdateBlizzardBar()
		return
	end
	self:UpdateTicker()
	self:Update()
end

function module:OnEnable()
	if not frame then
		CreateWidget()
	end
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
