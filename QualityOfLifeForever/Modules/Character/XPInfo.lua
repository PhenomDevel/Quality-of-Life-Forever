-- luacheck: read globals GameTooltip GameTooltip_SetDefaultAnchor UIParent SecondsToTime BreakUpLargeNumbers IsPlayerAtEffectiveMaxLevel MainStatusTrackingBarContainer SecondaryStatusTrackingBarContainer NORMAL_FONT_COLOR HIGHLIGHT_FONT_COLOR
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "XP info",
		NOTE = "XP per hour and time to level in the XP bar tooltip",
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
		NOTE = "EP pro Stunde und Zeit bis zum Level-up im Tooltip der EP-Leiste",
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
				ns.XPSession.Reset()
				self:Print(L.RESET_DONE)
			end,
		},
	},
})

local XPSession = ns.XPSession

local function AddLine(text)
	GameTooltip:AddLine(text, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
end

function module:AddTooltipLines()
	if IsPlayerAtEffectiveMaxLevel and IsPlayerAtEffectiveMaxLevel() then
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
		AddLine(L.TIME_TO_LEVEL:format(SecondsToTime(XPSession.GetTimeToLevel(), true)))
	end
	local lastGain = XPSession.GetLastGain()
	if lastGain then
		AddLine(L.LAST_GAIN:format(BreakUpLargeNumbers(lastGain), math.ceil((maxXP - xp) / lastGain)))
	end
	GameTooltip:Show()
end

function module:OnEnable()
	for _, container in ipairs({ MainStatusTrackingBarContainer, SecondaryStatusTrackingBarContainer }) do
		for _, bar in pairs(container and container.bars or {}) do
			if bar.isExpBar then
				self:HookScript(bar, "OnEnter", self.AddTooltipLines)
			end
		end
	end
end
