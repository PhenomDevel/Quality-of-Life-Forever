-- luacheck: read globals C_Timer StatusTrackingBarManager GameTooltip GameTooltip_SetDefaultAnchor UIParent BreakUpLargeNumbers IsPlayerAtEffectiveMaxLevel MainStatusTrackingBarContainer SecondaryStatusTrackingBarContainer NORMAL_FONT_COLOR HIGHLIGHT_FONT_COLOR StatusTrackingBarInfo
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Experience bar",
		NOTE = "XP text, XP per hour and time to level",
		DESC = "Improves the experience bar: XP text always visible, XP per hour and the time to the next level in the text and in the tooltip. Counts from login or the last reset and continues after a /reload.",
		NOTICE = "{Always show XP text} changes the game setting `xpBarText`. Turning it off restores your previous setting.",
		SECTION_TEXT = "Text on the bar",
		ALWAYS_TEXT = "Always show XP text",
		ALWAYS_TEXT_DESC = "Shows current / needed XP permanently instead of only on mouseover.",
		RATE_TEXT = "Add XP per hour and time",
		RATE_TEXT_DESC = "Appends XP per hour and the time to the next level to the text, e.g. \"(12,345/h, 1 Hr 5 Min)\". Updated on every XP gain and every 3 seconds; shown after the first minute with XP.",
		SECTION_TOOLTIP = "Tooltip",
		TOOLTIP = "Leveling info in the tooltip",
		TOOLTIP_DESC = "Adds XP this session, XP per hour, time to level and how many gains like the last one you still need.",
		SECTION_SESSION = "Session",
		RESET = "XP per hour",
		RESET_DESC = "Starts counting XP per hour from now.",
		RESET_BUTTON = "Reset",
		RESET_DONE = "XP session reset.",
		SUFFIX = " (%s/h, %s)",
		HEADER = "Leveling",
		SESSION = "This session: %s XP (%s per hour)",
		TIME_TO_LEVEL = "Time to level: %s",
		LAST_GAIN = "Last gain: %s XP (%d more to level)",
		NO_DATA = "No XP gained yet",
	},
	deDE = {
		TITLE = "Erfahrungsleiste",
		NOTE = "EP-Text, EP pro Stunde und Zeit bis Level-up",
		DESC = "Verbessert die Erfahrungsleiste: EP-Text immer sichtbar, EP pro Stunde und Zeit bis zur nächsten Stufe im Text und im Tooltip. Zählt ab dem Einloggen oder dem letzten Zurücksetzen und läuft nach einem /reload weiter.",
		NOTICE = "{EP-Text immer anzeigen} ändert die Spieleinstellung `xpBarText`. Beim Ausschalten wird deine vorherige Einstellung wiederhergestellt.",
		SECTION_TEXT = "Text auf der Leiste",
		ALWAYS_TEXT = "EP-Text immer anzeigen",
		ALWAYS_TEXT_DESC = "Zeigt aktuelle / benötigte EP dauerhaft statt nur beim Überfahren mit der Maus.",
		RATE_TEXT = "EP pro Stunde und Zeit anhängen",
		RATE_TEXT_DESC = "Hängt EP pro Stunde und die Zeit bis zur nächsten Stufe an den Text an, z. B. „(12.345/h, 1 Std. 5 Min.)“. Wird bei jedem EP-Gewinn und alle 3 Sekunden aktualisiert; erscheint nach der ersten Minute mit EP.",
		SECTION_TOOLTIP = "Tooltip",
		TOOLTIP = "Level-Infos im Tooltip",
		TOOLTIP_DESC = "Ergänzt EP dieser Sitzung, EP pro Stunde, Zeit bis Level-up und wie viele Gewinne wie der letzte dir noch fehlen.",
		SECTION_SESSION = "Sitzung",
		RESET = "EP pro Stunde",
		RESET_DESC = "Zählt die EP pro Stunde ab jetzt neu.",
		RESET_BUTTON = "Zurücksetzen",
		RESET_DONE = "EP-Sitzung zurückgesetzt.",
		SUFFIX = " (%s/h, %s)",
		HEADER = "Leveln",
		SESSION = "Diese Sitzung: %s EP (%s pro Stunde)",
		TIME_TO_LEVEL = "Zeit bis Level-up: %s",
		LAST_GAIN = "Letzter Gewinn: %s EP (noch %d bis Level-up)",
		NO_DATA = "Noch keine EP erhalten",
	},
})

local module = ns:NewModule("XPBar", {
	title = L.TITLE,
	description = L.DESC,
	note = L.NOTE,
	notice = L.NOTICE,
	category = "XP_BAR",
	defaults = {
		alwaysText = true,
		rateText = false,
		tooltip = true,
	},
	options = {
		{ type = "header", label = L.SECTION_TEXT },
		{ key = "alwaysText", type = "checkbox", label = L.ALWAYS_TEXT, tooltip = L.ALWAYS_TEXT_DESC },
		{ key = "rateText", type = "checkbox", label = L.RATE_TEXT, tooltip = L.RATE_TEXT_DESC },
		{ type = "header", label = L.SECTION_TOOLTIP },
		{ key = "tooltip", type = "checkbox", label = L.TOOLTIP, tooltip = L.TOOLTIP_DESC },
		{ type = "header", label = L.SECTION_SESSION },
		{
			type = "button",
			label = L.RESET,
			buttonText = L.RESET_BUTTON,
			tooltip = L.RESET_DESC,
			onClick = function(self)
				ns.XPSession.Reset()
				self:RefreshBarText()
				self:Print(L.RESET_DONE)
			end,
		},
	},
})

local XPSession = ns.XPSession
-- The permanent text is only rewritten on XP gains (hovering rewrites it on
-- enter); the ticker keeps rate and time to level current in between.
local REFRESH_SECONDS = 3
local expBars = {}
local ticker

-- Bar text -------------------------------------------------------------------

-- Runs after Blizzard wrote "current / max" into the bar text.
function module:AppendRate(bar)
	if not self.db.rateText or ns.blizzardXPBarHidden then
		return
	end
	local perHour = XPSession.GetPerHour()
	local text = bar.OverlayFrame and bar.OverlayFrame.Text
	local current = text and text:GetText()
	if not perHour or not current or ns.Utils.IsSecret(current) then
		return
	end
	local timeToLevel = XPSession.FormatTimeToLevel() or ""
	text:SetText(current .. L.SUFFIX:format(BreakUpLargeNumbers(math.floor(perHour)), timeToLevel))
end

-- Lets Blizzard rewrite the base text, which re-runs AppendRate via the hook.
-- Skipped while the XP widget hides the bar.
function module:RefreshBarText()
	if ns.blizzardXPBarHidden then
		return
	end
	for _, bar in ipairs(expBars) do
		-- Unset until the bar's first update (e.g. at max level).
		if bar.currXP and bar.maxBar then
			bar:UpdateCurrentText()
		end
	end
end

local function RefreshTextVisibility()
	if StatusTrackingBarManager then
		StatusTrackingBarManager:UpdateBarTextVisibility()
	end
end

function module:ApplyAlwaysText()
	if self.db.alwaysText then
		self:SetCVar("xpBarText", 1)
	else
		self:RestoreCVars()
	end
	RefreshTextVisibility()
end

function module:UpdateTicker()
	local wanted = self.enabled and self.db.rateText and not ns.blizzardXPBarHidden
	if wanted and not ticker then
		ticker = C_Timer.NewTicker(REFRESH_SECONDS, function()
			self:RefreshBarText()
		end)
	elseif not wanted and ticker then
		ticker:Cancel()
		ticker = nil
	end
end

-- Tooltip --------------------------------------------------------------------

local function AddLine(text)
	GameTooltip:AddLine(text, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
end

function module:AddTooltipLines()
	if not self.db.tooltip or (IsPlayerAtEffectiveMaxLevel and IsPlayerAtEffectiveMaxLevel()) then
		return
	end
	local xp, maxXP = XPSession.Read()
	if not xp or maxXP <= 0 then
		return
	end
	if not GameTooltip:IsShown() then
		GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
	else
		GameTooltip:AddLine(" ")
	end
	GameTooltip:AddLine(L.HEADER, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)

	local perHour = XPSession.GetPerHour()
	if not perHour then
		AddLine(L.NO_DATA)
	else
		AddLine(L.SESSION:format(BreakUpLargeNumbers(XPSession.GetSessionXP()), BreakUpLargeNumbers(math.floor(perHour))))
		AddLine(L.TIME_TO_LEVEL:format(XPSession.FormatTimeToLevel() or ""))
	end
	local lastGain = XPSession.GetLastGain()
	if lastGain then
		AddLine(L.LAST_GAIN:format(BreakUpLargeNumbers(lastGain), math.ceil((maxXP - xp) / lastGain)))
	end
	GameTooltip:Show()
end

-- Lifecycle ------------------------------------------------------------------

function module:OnOptionChanged(key)
	if key == "alwaysText" then
		self:ApplyAlwaysText()
	elseif key == "rateText" then
		self:UpdateTicker()
		self:RefreshBarText()
	end
end

function module:OnEnable()
	wipe(expBars)
	for _, container in ipairs({ MainStatusTrackingBarContainer, SecondaryStatusTrackingBarContainer }) do
		-- Looked up by index: isExpBar is also set on the pet XP bar template.
		local bar = container and container.bars and container.bars[StatusTrackingBarInfo.BarsEnum.Experience]
		if bar then
			expBars[#expBars + 1] = bar
			self:SecureHook(bar, "UpdateCurrentText", self.AppendRate)
			self:HookScript(bar, "OnEnter", self.AddTooltipLines)
		end
	end
	XPSession.RegisterListener(self, function()
		if self.enabled and self.db.rateText then
			self:RefreshBarText()
		end
	end)
	self:ApplyAlwaysText()
	self:UpdateTicker()
	self:RefreshBarText()
end

function module:OnDisable()
	-- The CVar is restored after OnDisable returns; the hooks are already off.
	C_Timer.After(0, RefreshTextVisibility)
	self:UpdateTicker()
	self:RefreshBarText()
end
