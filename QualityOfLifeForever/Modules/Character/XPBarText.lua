-- luacheck: read globals C_Timer StatusTrackingBarManager SecondsToTime BreakUpLargeNumbers MainStatusTrackingBarContainer SecondaryStatusTrackingBarContainer
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "XP bar text",
		NOTE = "Current / needed XP always on the bar",
		DESC = "Shows current / needed XP on the experience bar permanently instead of only on mouseover. Optionally adds XP per hour and the time to the next level. Disabling restores your previous setting.",
		RATE = "Add XP per hour and time",
		RATE_DESC = "Appends XP per hour and the time to the next level to the text, e.g. \"(12,345/h, 1 Hr 5 Min)\". Updated whenever you gain XP; shown after the first minute with XP.",
		SUFFIX = " (%s/h, %s)",
	},
	deDE = {
		TITLE = "EP-Leistentext",
		NOTE = "Aktuelle / benötigte EP immer auf der Leiste",
		DESC = "Zeigt aktuelle / benötigte EP dauerhaft auf der Erfahrungsleiste statt nur beim Überfahren mit der Maus. Optional mit EP pro Stunde und der Zeit bis zur nächsten Stufe. Beim Deaktivieren wird deine vorherige Einstellung wiederhergestellt.",
		RATE = "EP pro Stunde und Zeit anhängen",
		RATE_DESC = "Hängt EP pro Stunde und die Zeit bis zur nächsten Stufe an den Text an, z. B. „(12.345/h, 1 Std. 5 Min.)“. Wird bei jedem EP-Gewinn aktualisiert; erscheint nach der ersten Minute mit EP.",
		SUFFIX = " (%s/h, %s)",
	},
})

local module = ns:NewModule("XPBarText", {
	title = L.TITLE,
	description = L.DESC,
	note = L.NOTE,
	category = "CHARACTER",
	defaults = {
		rate = false,
	},
	options = {
		{ key = "rate", type = "checkbox", label = L.RATE, tooltip = L.RATE_DESC },
	},
})

local XPSession = ns.XPSession
local expBars = {}

-- Runs after Blizzard wrote "current / max" into the bar text.
function module:AppendRate(bar)
	if not self.db.rate then
		return
	end
	local perHour = XPSession.GetPerHour()
	local text = bar.OverlayFrame and bar.OverlayFrame.Text
	local current = text and text:GetText()
	if not perHour or not current or ns.Utils.IsSecret(current) then
		return
	end
	local timeToLevel = SecondsToTime(XPSession.GetTimeToLevel() or 0, true)
	text:SetText(current .. L.SUFFIX:format(BreakUpLargeNumbers(math.floor(perHour)), timeToLevel))
end

-- Lets Blizzard rewrite the base text, which re-runs AppendRate via the hook.
local function RefreshBarText()
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

function module:OnOptionChanged()
	RefreshBarText()
end

function module:OnEnable()
	wipe(expBars)
	for _, container in ipairs({ MainStatusTrackingBarContainer, SecondaryStatusTrackingBarContainer }) do
		for _, bar in pairs(container and container.bars or {}) do
			if bar.isExpBar then
				expBars[#expBars + 1] = bar
				self:SecureHook(bar, "UpdateCurrentText", self.AppendRate)
			end
		end
	end
	XPSession.RegisterListener(self, function()
		if self.enabled and self.db.rate then
			RefreshBarText()
		end
	end)
	-- Blizzard's own "always show XP text" setting.
	self:SetCVar("xpBarText", 1)
	RefreshTextVisibility()
	RefreshBarText()
end

function module:OnDisable()
	-- The CVar is restored after OnDisable returns; the hook is already off.
	C_Timer.After(0, RefreshTextVisibility)
	RefreshBarText()
end
