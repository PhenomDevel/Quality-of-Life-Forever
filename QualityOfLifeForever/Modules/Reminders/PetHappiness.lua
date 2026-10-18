-- luacheck: read globals C_PetInfo HasPetUI InCombatLockdown PlaySound SOUNDKIT PET_HAPPINESS1 PET_HAPPINESS2
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Pet happiness warning",
		NOTE = "Reminds you to feed your hunter pet",
		DESC = "Warns you with a popup when your hunter pet's happiness drops and tells you what it eats. An unhappy pet deals less damage and loses loyalty.",
		WARN_AT = "Warn at happiness",
		WARN_AT_DESC = "Happiness level at which the warning appears.",
		NEUTRAL = "Content (yellow)",
		MAD = "Unhappy (red)",
		SECTION_WHEN = "When to warn",
		SECTION_HOW = "How to warn",
		SOUND = "Sound",
		SOUND_DESC = "Plays a sound with the warning.",
		AFTER_COMBAT = "Remind after combat",
		AFTER_COMBAT_DESC = "Repeats the warning after each fight while the pet is still at or below the level.",
		MESSAGE = "Your pet is %s (%d%% damage). Feed it: %s",
		ANY_FOOD = "any food",
		PREVIEW = "Preview",
		PREVIEW_DESC = "Shows the warning popup, with your current pet if you have one out.",
		PREVIEW_BUTTON = "Show",
	},
	deDE = {
		TITLE = "Begleiter-Zufriedenheit",
		NOTE = "Erinnert ans Füttern deines Jäger-Begleiters",
		DESC = "Warnt dich mit einem Popup, wenn die Zufriedenheit deines Jäger-Begleiters sinkt, und zeigt, was er frisst. Ein unzufriedener Begleiter macht weniger Schaden und verliert Treue.",
		WARN_AT = "Warnen ab Zufriedenheit",
		WARN_AT_DESC = "Zufriedenheitsstufe, ab der die Warnung erscheint.",
		NEUTRAL = "Zufrieden (gelb)",
		MAD = "Unglücklich (rot)",
		SECTION_WHEN = "Wann warnen",
		SECTION_HOW = "Wie warnen",
		SOUND = "Ton",
		SOUND_DESC = "Spielt einen Ton zur Warnung.",
		AFTER_COMBAT = "Nach dem Kampf erinnern",
		AFTER_COMBAT_DESC = "Wiederholt die Warnung nach jedem Kampf, solange der Begleiter auf oder unter der Stufe ist.",
		MESSAGE = "Dein Begleiter ist %s (%d %% Schaden). Füttere ihn: %s",
		ANY_FOOD = "beliebiges Futter",
		PREVIEW = "Vorschau",
		PREVIEW_DESC = "Zeigt das Warn-Popup, mit deinem aktuellen Begleiter, falls einer draußen ist.",
		PREVIEW_BUTTON = "Anzeigen",
	},
})

-- C_PetInfo.GetPetHappiness: 1 = mad, 2 = neutral, 3 = happy
-- (Forever Blizzard_FrameXML/PetHappiness.lua).
local MAD, NEUTRAL = 1, 2
local HAPPINESS_TEXT = { [MAD] = PET_HAPPINESS1, [NEUTRAL] = PET_HAPPINESS2 }

local IsSecret = ns.Utils.IsSecret

-- Happiness and damage percentage of the active hunter pet, or nil.
local function GetHappiness()
	local _, isHunterPet = HasPetUI()
	if not isHunterPet then
		return nil
	end
	local happiness, damagePercentage = C_PetInfo.GetPetHappiness()
	if type(happiness) ~= "number" or IsSecret(happiness) or IsSecret(damagePercentage) then
		return nil
	end
	return happiness, damagePercentage or 0
end

local function GetDiet()
	local _, isHunterPet = HasPetUI()
	local diet = isHunterPet and C_PetInfo.GetPetFoodTypes()
	if type(diet) == "table" and #diet > 0 then
		return table.concat(diet, ", ")
	end
	return L.ANY_FOOD
end

local module = ns:NewModule("PetHappiness", {
	title = L.TITLE,
	description = L.DESC,
	note = L.NOTE,
	category = "REMINDERS",
	defaults = {
		warnAt = NEUTRAL,
		sound = true,
		afterCombat = true,
	},
	options = {
		{ type = "header", label = L.SECTION_WHEN },
		{
			key = "warnAt",
			type = "dropdown",
			label = L.WARN_AT,
			tooltip = L.WARN_AT_DESC,
			values = {
				{ value = NEUTRAL, label = L.NEUTRAL },
				{ value = MAD, label = L.MAD },
			},
		},
		{ key = "afterCombat", type = "checkbox", label = L.AFTER_COMBAT, tooltip = L.AFTER_COMBAT_DESC },
		{ type = "header", label = L.SECTION_HOW },
		{ key = "sound", type = "checkbox", label = L.SOUND, tooltip = L.SOUND_DESC },
		{
			type = "button",
			label = L.PREVIEW,
			buttonText = L.PREVIEW_BUTTON,
			tooltip = L.PREVIEW_DESC,
			onClick = function(self)
				local happiness, damagePercentage = GetHappiness()
				-- Without a pet: a content pet deals normal damage.
				self:Warn(happiness or NEUTRAL, damagePercentage or 100)
			end,
		},
	},
})

local ICON = "Interface\\Icons\\Ability_Hunter_BeastTraining"
local lastHappiness

function module:Warn(happiness, damagePercentage)
	self:Notice(L.MESSAGE:format(HAPPINESS_TEXT[happiness] or "", damagePercentage, GetDiet()), ICON)
	if self.db.sound then
		PlaySound(SOUNDKIT.RAID_WARNING, "Master")
	end
end

-- Warns when happiness drops to or below the level, including a pet that is
-- summoned while already unhappy; not again while it stays there.
function module:Check()
	local happiness, damagePercentage = GetHappiness()
	if not happiness then
		lastHappiness = nil
		return
	end
	local dropped = lastHappiness == nil or happiness < lastHappiness
	lastHappiness = happiness
	if dropped and happiness <= self.db.warnAt then
		self:Warn(happiness, damagePercentage)
	end
end

function module:OnCombatEnd()
	if not self.db.afterCombat then
		return
	end
	local happiness, damagePercentage = GetHappiness()
	if happiness and happiness <= self.db.warnAt then
		self:Warn(happiness, damagePercentage)
	end
end

function module:OnEnable()
	lastHappiness = nil
	self:RegisterEvent("UNIT_HAPPINESS", self.Check)
	self:RegisterEvent("UNIT_PET", function(_, unit)
		if unit == "player" then
			lastHappiness = nil
			self:Check()
		end
	end)
	self:RegisterEvent("PLAYER_REGEN_ENABLED", self.OnCombatEnd)
	if not InCombatLockdown() then
		self:Check()
	end
end
