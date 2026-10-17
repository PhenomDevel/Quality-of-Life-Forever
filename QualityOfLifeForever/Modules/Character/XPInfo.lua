-- luacheck: read globals C_Timer StatusTrackingBarManager XP_STATUS_BAR_TEXT GameTooltip GameTooltip_SetDefaultAnchor UIParent UnitXP UnitXPMax GetTime SecondsToTime BreakUpLargeNumbers IsPlayerAtEffectiveMaxLevel MainStatusTrackingBarContainer SecondaryStatusTrackingBarContainer NORMAL_FONT_COLOR HIGHLIGHT_FONT_COLOR
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "XP info",
		NOTE = "XP per hour and time to level on the XP bar",
		DESC = "Adds XP per hour, the estimated time to the next level and how many gains like the last one you still need to the tooltip of the experience bar. Counts from login or the last reset.",
		HEADER = "Leveling",
		SESSION = "This session: %s XP (%s per hour)",
		TIME_TO_LEVEL = "Time to level: %s",
		LAST_GAIN = "Last gain: %s XP (%d more to level)",
		NO_DATA = "No XP gained yet",
		RESET = "Session",
		RESET_DESC = "Starts counting XP per hour from now.",
		RESET_BUTTON = "Reset",
		RESET_DONE = "XP session reset.",
		SECTION_BAR = "Experience bar",
		SECTION_SESSION = "Session",
		ALWAYS_TEXT = "Always show XP text",
		ALWAYS_TEXT_DESC = "Shows current / needed XP on the experience bar permanently instead of only on mouseover.",
		RATE_TEXT = "XP per hour and time to level in the text",
		RATE_TEXT_DESC = "Appends XP per hour and the time to the next level to the text on the experience bar. Updated whenever you gain XP.",
		BAR_SUFFIX = " (%s/h, %s)",
	},
	deDE = {
		TITLE = "EP-Infos",
		NOTE = "EP pro Stunde und Zeit bis zum Level-up an der EP-Leiste",
		DESC = "Ergänzt den Tooltip der Erfahrungsleiste um EP pro Stunde, die geschätzte Zeit bis zur nächsten Stufe und wie viele Gewinne wie der letzte dir noch fehlen. Zählt ab dem Einloggen oder dem letzten Zurücksetzen.",
		HEADER = "Leveln",
		SESSION = "Diese Sitzung: %s EP (%s pro Stunde)",
		TIME_TO_LEVEL = "Zeit bis Level-up: %s",
		LAST_GAIN = "Letzter Gewinn: %s EP (noch %d bis Level-up)",
		NO_DATA = "Noch keine EP erhalten",
		RESET = "Sitzung",
		RESET_DESC = "Zählt die EP pro Stunde ab jetzt neu.",
		RESET_BUTTON = "Zurücksetzen",
		RESET_DONE = "EP-Sitzung zurückgesetzt.",
		SECTION_BAR = "Erfahrungsleiste",
		SECTION_SESSION = "Sitzung",
		ALWAYS_TEXT = "EP-Text immer anzeigen",
		ALWAYS_TEXT_DESC = "Zeigt aktuelle / benötigte EP dauerhaft auf der Erfahrungsleiste statt nur beim Überfahren mit der Maus.",
		RATE_TEXT = "EP pro Stunde und Zeit bis Level-up im Text",
		RATE_TEXT_DESC = "Hängt EP pro Stunde und die Zeit bis zur nächsten Stufe an den Text der Erfahrungsleiste an. Wird bei jedem EP-Gewinn aktualisiert.",
		BAR_SUFFIX = " (%s/h, %s)",
	},
})

local module = ns:NewModule("XPInfo", {
	title = L.TITLE,
	description = L.DESC,
	note = L.NOTE,
	category = "CHARACTER",
	defaults = {
		alwaysText = false,
		rateText = false,
	},
	options = {
		{ type = "header", label = L.SECTION_BAR },
		{ key = "alwaysText", type = "checkbox", label = L.ALWAYS_TEXT, tooltip = L.ALWAYS_TEXT_DESC },
		{ key = "rateText", type = "checkbox", label = L.RATE_TEXT, tooltip = L.RATE_TEXT_DESC },
		{ type = "header", label = L.SECTION_SESSION },
		{
			type = "button",
			label = L.RESET,
			buttonText = L.RESET_BUTTON,
			tooltip = L.RESET_DESC,
			onClick = function(self)
				self:ResetSession()
				self:Print(L.RESET_DONE)
			end,
		},
	},
})

local IsSecret = ns.Utils.IsSecret
-- Below this the rate is too noisy to show.
local MIN_SESSION_SECONDS = 60

local sessionStart, sessionXP, lastXP, lastMaxXP, lastGain
local expBars = {}

local function ReadXP()
	local xp, maxXP = UnitXP("player"), UnitXPMax("player")
	if IsSecret(xp) or IsSecret(maxXP) then
		return nil
	end
	return xp, maxXP
end

function module:ResetSession()
	sessionStart = GetTime()
	sessionXP = 0
	lastGain = nil
	lastXP, lastMaxXP = ReadXP()
end

-- Only arithmetic per update; everything else happens when the tooltip shows.
function module:OnXPUpdate(unit)
	if unit and unit ~= "player" then
		return
	end
	local xp, maxXP = ReadXP()
	if not xp or not lastXP then
		lastXP, lastMaxXP = xp, maxXP
		return
	end
	local gain
	if xp >= lastXP then
		gain = xp - lastXP
	else
		-- Level up: the rest of the old level plus the progress in the new one.
		gain = (lastMaxXP - lastXP) + xp
	end
	if gain > 0 then
		sessionXP = sessionXP + gain
		lastGain = gain
	end
	lastXP, lastMaxXP = xp, maxXP
	if self.db.rateText then
		self:RefreshBarText()
	end
end

-- XP per hour, or nil while the session is too short to tell.
local function GetPerHour()
	local elapsed = GetTime() - sessionStart
	if sessionXP <= 0 or elapsed < MIN_SESSION_SECONDS then
		return nil
	end
	return sessionXP / elapsed * 3600
end

local function AddLine(text)
	GameTooltip:AddLine(text, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
end

function module:AddTooltipLines()
	if IsPlayerAtEffectiveMaxLevel and IsPlayerAtEffectiveMaxLevel() then
		return
	end
	local xp, maxXP = ReadXP()
	if not xp or maxXP <= 0 then
		return
	end
	if not GameTooltip:IsShown() then
		GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
	else
		GameTooltip:AddLine(" ")
	end
	GameTooltip:AddLine(L.HEADER, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)

	local perHour = GetPerHour()
	if not perHour then
		AddLine(L.NO_DATA)
	else
		AddLine(L.SESSION:format(BreakUpLargeNumbers(sessionXP), BreakUpLargeNumbers(math.floor(perHour))))
		AddLine(L.TIME_TO_LEVEL:format(SecondsToTime((maxXP - xp) / perHour * 3600, true)))
	end
	if lastGain then
		AddLine(L.LAST_GAIN:format(BreakUpLargeNumbers(lastGain), math.ceil((maxXP - xp) / lastGain)))
	end
	GameTooltip:Show()
end

-- Runs after Blizzard wrote "current / max" into the bar text.
function module:AppendRate(bar)
	if not self.db.rateText then
		return
	end
	local perHour = GetPerHour()
	local xp, maxXP = ReadXP()
	local text = bar.OverlayFrame and bar.OverlayFrame.Text
	local current = text and text:GetText()
	if not perHour or not xp or not current or IsSecret(current) then
		return
	end
	local timeToLevel = SecondsToTime((maxXP - xp) / perHour * 3600, true)
	text:SetText(current .. L.BAR_SUFFIX:format(BreakUpLargeNumbers(math.floor(perHour)), timeToLevel))
end

-- Lets Blizzard rewrite the base text, which re-runs AppendRate via the hook.
function module:RefreshBarText()
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

function module:HookBars()
	wipe(expBars)
	for _, container in ipairs({ MainStatusTrackingBarContainer, SecondaryStatusTrackingBarContainer }) do
		for _, bar in pairs(container and container.bars or {}) do
			if bar.isExpBar then
				expBars[#expBars + 1] = bar
				self:HookScript(bar, "OnEnter", self.AddTooltipLines)
				self:SecureHook(bar, "UpdateCurrentText", self.AppendRate)
			end
		end
	end
end

function module:OnOptionChanged(key)
	if key == "alwaysText" then
		self:ApplyAlwaysText()
	elseif key == "rateText" then
		self:RefreshBarText()
	end
end

function module:OnEnable()
	-- XP gained while the module was off isn't counted, so start fresh.
	self:ResetSession()
	self:HookBars()
	self:RegisterEvent("PLAYER_XP_UPDATE", self.OnXPUpdate)
	self:ApplyAlwaysText()
	self:RefreshBarText()
end

function module:OnDisable()
	-- The CVar is restored after OnDisable returns; the hook is already off.
	C_Timer.After(0, RefreshTextVisibility)
	self:RefreshBarText()
end
