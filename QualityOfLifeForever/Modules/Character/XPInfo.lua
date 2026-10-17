-- luacheck: read globals GameTooltip GameTooltip_SetDefaultAnchor UIParent UnitXP UnitXPMax GetTime SecondsToTime BreakUpLargeNumbers IsPlayerAtEffectiveMaxLevel MainStatusTrackingBarContainer SecondaryStatusTrackingBarContainer NORMAL_FONT_COLOR HIGHLIGHT_FONT_COLOR
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
	},
})

local module = ns:NewModule("XPInfo", {
	title = L.TITLE,
	description = L.DESC,
	note = L.NOTE,
	category = "CHARACTER",
	options = {
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

	local elapsed = GetTime() - sessionStart
	if sessionXP <= 0 or elapsed < MIN_SESSION_SECONDS then
		AddLine(L.NO_DATA)
	else
		local perHour = sessionXP / elapsed * 3600
		AddLine(L.SESSION:format(BreakUpLargeNumbers(sessionXP), BreakUpLargeNumbers(math.floor(perHour))))
		AddLine(L.TIME_TO_LEVEL:format(SecondsToTime((maxXP - xp) / perHour * 3600, true)))
	end
	if lastGain then
		AddLine(L.LAST_GAIN:format(BreakUpLargeNumbers(lastGain), math.ceil((maxXP - xp) / lastGain)))
	end
	GameTooltip:Show()
end

function module:HookBars()
	for _, container in ipairs({ MainStatusTrackingBarContainer, SecondaryStatusTrackingBarContainer }) do
		for _, bar in pairs(container and container.bars or {}) do
			if bar.isExpBar then
				self:HookScript(bar, "OnEnter", self.AddTooltipLines)
			end
		end
	end
end

function module:OnEnable()
	-- XP gained while the module was off isn't counted, so start fresh.
	self:ResetSession()
	self:HookBars()
	self:RegisterEvent("PLAYER_XP_UPDATE", self.OnXPUpdate)
end
