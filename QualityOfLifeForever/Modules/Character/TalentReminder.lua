-- luacheck: read globals C_ClassTalents C_Timer PlaySound SOUNDKIT UIErrorsFrame TalentMicroButton
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Talent point reminder",
		NOTE = "Reminds you of unspent talent points",
		DESC = "Reminds you of unspent talent points after a level-up and when you log in, and shows their number on the talent button of the micro menu.",
		SECTION_WHEN = "When to remind",
		LEVEL_UP = "After a level-up",
		LEVEL_UP_DESC = "Reminds you when a level-up leaves you with unspent talent points.",
		LOGIN = "On login",
		LOGIN_DESC = "Reminds you after logging in if you have unspent talent points.",
		SECTION_HOW = "How to remind",
		SCREEN = "Also on screen",
		SCREEN_DESC = "Shows the reminder in the middle of the screen as well as in chat.",
		SOUND = "Sound",
		SOUND_DESC = "Plays a sound with the reminder.",
		BADGE = "Number on talent button",
		BADGE_DESC = "Shows the number of unspent talent points on the talent button of the micro menu.",
		MESSAGE = "You have %d unspent talent point(s).",
		MESSAGE_UNKNOWN = "You have unspent talent points.",
	},
	deDE = {
		TITLE = "Talentpunkt-Erinnerung",
		NOTE = "Erinnert an freie Talentpunkte",
		DESC = "Erinnert dich nach einem Level-up und beim Einloggen an freie Talentpunkte und zeigt ihre Anzahl auf der Talent-Taste des Mikromenüs.",
		SECTION_WHEN = "Wann erinnern",
		LEVEL_UP = "Nach einem Level-up",
		LEVEL_UP_DESC = "Erinnert dich, wenn du nach einem Level-up freie Talentpunkte hast.",
		LOGIN = "Beim Einloggen",
		LOGIN_DESC = "Erinnert dich nach dem Einloggen, wenn du freie Talentpunkte hast.",
		SECTION_HOW = "Wie erinnern",
		SCREEN = "Auch auf dem Bildschirm",
		SCREEN_DESC = "Zeigt die Erinnerung zusätzlich zum Chat in der Bildschirmmitte.",
		SOUND = "Ton",
		SOUND_DESC = "Spielt einen Ton zur Erinnerung.",
		BADGE = "Anzahl auf der Talent-Taste",
		BADGE_DESC = "Zeigt die Anzahl freier Talentpunkte auf der Talent-Taste des Mikromenüs.",
		MESSAGE = "Du hast %d freie(n) Talentpunkt(e).",
		MESSAGE_UNKNOWN = "Du hast freie Talentpunkte.",
	},
})

local module = ns:NewModule("TalentReminder", {
	title = L.TITLE,
	description = L.DESC,
	note = L.NOTE,
	category = "CHARACTER",
	defaults = {
		levelUp = true,
		login = true,
		screen = true,
		sound = false,
		badge = true,
	},
	options = {
		{ type = "header", label = L.SECTION_WHEN },
		{ key = "levelUp", type = "checkbox", label = L.LEVEL_UP, tooltip = L.LEVEL_UP_DESC },
		{ key = "login", type = "checkbox", label = L.LOGIN, tooltip = L.LOGIN_DESC },
		{ type = "header", label = L.SECTION_HOW },
		{ key = "screen", type = "checkbox", label = L.SCREEN, tooltip = L.SCREEN_DESC },
		{ key = "sound", type = "checkbox", label = L.SOUND, tooltip = L.SOUND_DESC },
		{ key = "badge", type = "checkbox", label = L.BADGE, tooltip = L.BADGE_DESC },
	},
})

-- The new point arrives shortly after PLAYER_LEVEL_UP; the login check
-- waits until the chat is ready.
local LEVEL_UP_DELAY = 1
local LOGIN_DELAY = 5

local badge

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

function module:Remind()
	local hasUnspent, count = Unspent()
	if not hasUnspent then
		return
	end
	local message = count and L.MESSAGE:format(count) or L.MESSAGE_UNKNOWN
	self:Print(message)
	if self.db.screen and UIErrorsFrame then
		UIErrorsFrame:AddMessage(message, 1, 0.82, 0)
	end
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

function module:PLAYER_LEVEL_UP()
	C_Timer.After(LEVEL_UP_DELAY, function()
		if not self.enabled then
			return
		end
		self:UpdateBadge()
		if self.db.levelUp then
			self:Remind()
		end
	end)
end

function module:PLAYER_ENTERING_WORLD(isInitialLogin)
	self:UpdateBadge()
	if isInitialLogin and self.db.login then
		C_Timer.After(LOGIN_DELAY, function()
			if self.enabled then
				self:Remind()
			end
		end)
	end
end

function module:OnOptionChanged()
	self:UpdateBadge()
end

function module:OnEnable()
	self:RegisterEvent("PLAYER_LEVEL_UP")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	for _, event in ipairs({ "PLAYER_TALENT_UPDATE", "TRAIT_CONFIG_UPDATED", "CHARACTER_POINTS_CHANGED" }) do
		self:RegisterEvent(event, self.UpdateBadge)
	end
	self:UpdateBadge()
end

function module:OnDisable()
	self:UpdateBadge()
end
