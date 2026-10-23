-- luacheck: read globals C_ClassTalents C_Timer PlaySound SOUNDKIT TalentMicroButton UnitGUID time
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Talent point reminder",
		NOTE = "Reminds you of unspent talent points",
		DESC = "Reminds you with a popup when you log in with unspent talent points or leave them unspent for a while after a level-up, and shows their number on the talent button of the micro menu.",
		SECTION_WHEN = "When to remind",
		LEVEL_UP = "After a level-up",
		LEVEL_UP_DESC = "Reminds you when talent points from a level-up are still unspent after the time below.",
		LEVEL_UP_DELAY = "Remind after",
		LEVEL_UP_DELAY_DESC = "How long after a level-up the reminder appears if the points are still unspent.",
		MINUTES = "%d min",
		LOGIN = "On login",
		LOGIN_DESC = "Reminds you after logging in if you have unspent talent points.",
		SECTION_HOW = "How to remind",
		SOUND = "Sound",
		SOUND_DESC = "Plays a sound with the reminder.",
		BADGE = "Number on talent button",
		BADGE_DESC = "Shows the number of unspent talent points on the talent button of the micro menu.",
		MESSAGE = "You have %d unspent talent point(s).",
		MESSAGE_UNKNOWN = "You have unspent talent points.",
		PREVIEW = "Preview",
		PREVIEW_DESC = "Shows the reminder popup, with your current number of unspent points.",
		PREVIEW_BUTTON = "Show",
	},
	deDE = {
		TITLE = "Talentpunkt-Erinnerung",
		NOTE = "Erinnert an freie Talentpunkte",
		DESC = "Erinnert dich mit einem Popup, wenn du mit freien Talentpunkten einloggst oder sie nach einem Level-up eine Weile nicht verteilst, und zeigt ihre Anzahl auf der Talent-Taste des Mikromenüs.",
		SECTION_WHEN = "Wann erinnern",
		LEVEL_UP = "Nach einem Level-up",
		LEVEL_UP_DESC = "Erinnert dich, wenn die Talentpunkte eines Level-ups nach der unten eingestellten Zeit noch nicht verteilt sind.",
		LEVEL_UP_DELAY = "Erinnern nach",
		LEVEL_UP_DELAY_DESC = "Wie lange nach einem Level-up die Erinnerung erscheint, wenn die Punkte noch nicht verteilt sind.",
		MINUTES = "%d Min.",
		LOGIN = "Beim Einloggen",
		LOGIN_DESC = "Erinnert dich nach dem Einloggen, wenn du freie Talentpunkte hast.",
		SECTION_HOW = "Wie erinnern",
		SOUND = "Ton",
		SOUND_DESC = "Spielt einen Ton zur Erinnerung.",
		BADGE = "Anzahl auf der Talent-Taste",
		BADGE_DESC = "Zeigt die Anzahl freier Talentpunkte auf der Talent-Taste des Mikromenüs.",
		MESSAGE = "Du hast %d freie(n) Talentpunkt(e).",
		MESSAGE_UNKNOWN = "Du hast freie Talentpunkte.",
		PREVIEW = "Vorschau",
		PREVIEW_DESC = "Zeigt das Erinnerungs-Popup mit deiner aktuellen Anzahl freier Punkte.",
		PREVIEW_BUTTON = "Anzeigen",
	},
})

local function FormatMinutes(value)
	return L.MINUTES:format(value)
end

local module = ns:NewModule("TalentReminder", {
	title = L.TITLE,
	description = L.DESC,
	note = L.NOTE,
	category = "REMINDERS",
	order = 40,
	defaults = {
		levelUp = true,
		levelUpDelay = 60,
		login = true,
		sound = false,
		badge = true,
		-- [player GUID] = time() of the level-up whose points are still unspent
		pending = {},
	},
	options = {
		{ type = "header", label = L.SECTION_WHEN },
		{ key = "login", type = "checkbox", label = L.LOGIN, tooltip = L.LOGIN_DESC },
		{ key = "levelUp", type = "checkbox", label = L.LEVEL_UP, tooltip = L.LEVEL_UP_DESC },
		{ key = "levelUpDelay", type = "slider", label = L.LEVEL_UP_DELAY, tooltip = L.LEVEL_UP_DELAY_DESC, min = 5, max = 120, step = 5, format = FormatMinutes },
		{ type = "header", label = L.SECTION_HOW },
		{ key = "sound", type = "checkbox", label = L.SOUND, tooltip = L.SOUND_DESC },
		{ key = "badge", type = "checkbox", label = L.BADGE, tooltip = L.BADGE_DESC },
		{
			type = "button",
			label = L.PREVIEW,
			buttonText = L.PREVIEW_BUTTON,
			tooltip = L.PREVIEW_DESC,
			onClick = function(self)
				self:Remind(true)
			end,
		},
	},
})

-- The new point arrives shortly after PLAYER_LEVEL_UP; the login check
-- waits until the chat and talent data are ready.
local LEVEL_UP_DELAY = 1
local LOGIN_DELAY = 5
local ICON = "Interface\\Icons\\INV_Misc_Book_11"

local badge, timer

-- Returns whether points are unspent and how many (nil if unknown).
local function Unspent()
	if not (C_ClassTalents and C_ClassTalents.HasUnspentTalentPoints) then
		return false
	end
	local hasUnspent, classPoints, specPoints = C_ClassTalents.HasUnspentTalentPoints()
	if not hasUnspent then
		return false
	end
	local count = (classPoints or 0) + (specPoints or 0)
	return true, count > 0 and count or nil
end

-- `preview` shows the popup even without unspent points.
function module:Remind(preview)
	local hasUnspent, count = Unspent()
	if not hasUnspent and not preview then
		return
	end
	if not hasUnspent then
		count = 1
	end
	self:Notice(count and L.MESSAGE:format(count) or L.MESSAGE_UNKNOWN, ICON)
	if self.db.sound then
		PlaySound(SOUNDKIT.RAID_WARNING, "Master")
	end
end

function module:UpdateBadge()
	if not TalentMicroButton then
		return
	end
	local hasUnspent, count = Unspent()
	if not (self.enabled and self.db.badge and hasUnspent) then
		if badge then
			badge:Hide()
		end
		return
	end
	if not badge then
		badge = TalentMicroButton:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
		badge:SetPoint("TOPRIGHT", TalentMicroButton, "TOPRIGHT", 0, -2)
		badge:SetTextColor(1, 0.82, 0)
	end
	badge:SetText(count or "!")
	badge:Show()
end

function module:CancelTimer()
	if timer then
		timer:Cancel()
		timer = nil
	end
end

-- Runs the level-up reminder for the pending level-up of this character;
-- the time is saved, so it survives a /reload.
function module:SchedulePending()
	self:CancelTimer()
	local since = self.db.pending[UnitGUID("player")]
	if not since or not self.db.levelUp then
		return
	end
	local remaining = math.max(since + self.db.levelUpDelay * 60 - time(), 0)
	timer = C_Timer.NewTimer(remaining, function()
		timer = nil
		self.db.pending[UnitGUID("player")] = nil
		self:Remind()
	end)
end

-- Points spent: nothing left to remind of.
function module:OnTalentsChanged()
	self:UpdateBadge()
	if not Unspent() and self.db.pending[UnitGUID("player")] then
		self.db.pending[UnitGUID("player")] = nil
		self:CancelTimer()
	end
end

function module:PLAYER_LEVEL_UP()
	C_Timer.After(LEVEL_UP_DELAY, function()
		if not self.enabled then
			return
		end
		self:UpdateBadge()
		local guid = UnitGUID("player")
		-- The reminder counts from the oldest unspent level-up.
		if Unspent() and not self.db.pending[guid] then
			self.db.pending[guid] = time()
			self:SchedulePending()
		end
	end)
end

function module:PLAYER_ENTERING_WORLD(isInitialLogin)
	self:UpdateBadge()
	if isInitialLogin and self.db.login then
		C_Timer.After(LOGIN_DELAY, function()
			if not self.enabled then
				return
			end
			-- The login reminder covers a level-up from an earlier session.
			self.db.pending[UnitGUID("player")] = nil
			self:CancelTimer()
			self:Remind()
		end)
	end
end

function module:OnOptionChanged(key)
	self:UpdateBadge()
	if key == "levelUp" or key == "levelUpDelay" then
		self:SchedulePending()
	end
end

function module:OnEnable()
	self:RegisterEvent("PLAYER_LEVEL_UP")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	for _, event in ipairs({ "PLAYER_TALENT_UPDATE", "TRAIT_CONFIG_UPDATED", "CHARACTER_POINTS_CHANGED" }) do
		self:RegisterEvent(event, self.OnTalentsChanged)
	end
	self:UpdateBadge()
	self:SchedulePending()
end

function module:OnDisable()
	self:CancelTimer()
	self:UpdateBadge()
end
