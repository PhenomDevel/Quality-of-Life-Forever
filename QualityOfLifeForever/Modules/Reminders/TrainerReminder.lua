-- luacheck: read globals C_Spell C_Trainer Enum UnitGUID UnitLevel IsTradeskillTrainer GetNumTrainerServices GetTrainerServiceInfo GetTrainerServiceCost GetTrainerServiceTypeFilter
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Trainer reminder",
		NOTE = "Tells you on level-up what your class trainer has",
		DESC = "Remembers which skills your class trainer will teach at higher levels. When you reach such a level, a popup lists them with their cost. Needs one visit at your class trainer with the {Unavailable} filter turned on; without that nothing is announced.",
		NEW = "Level %d – new at your class trainer for %s:",
		WAITING = "%d more skill(s) from earlier levels are still waiting at your trainer.",
		FILTER_OFF = "Trainer reminder: turn on the {Unavailable} filter in the trainer window so upcoming skills can be remembered.",
		STATUS_NO_RECORD = "Not ready for this character yet: visit your class trainer once with the {Unavailable} filter turned on.",
	},
	deDE = {
		TITLE = "Lehrer-Erinnerung",
		NOTE = "Meldet beim Level-up, was dein Klassenlehrer hat",
		DESC = "Merkt sich, welche Fähigkeiten dein Klassenlehrer auf höheren Stufen lehrt. Erreichst du eine solche Stufe, listet ein Popup sie mit ihren Kosten auf. Benötigt einen Besuch beim Klassenlehrer mit aktiviertem Filter {Nicht verfügbar}; ohne das wird nichts gemeldet.",
		NEW = "Stufe %d – neu bei deinem Klassenlehrer für %s:",
		WAITING = "%d weitere Fähigkeit(en) früherer Stufen warten noch bei deinem Lehrer.",
		FILTER_OFF = "Lehrer-Erinnerung: Aktiviere im Lehrerfenster den Filter {Nicht verfügbar}, damit kommende Fähigkeiten gemerkt werden können.",
		STATUS_NO_RECORD = "Für diesen Charakter noch nicht bereit: Besuche einmal deinen Klassenlehrer mit aktiviertem Filter {Nicht verfügbar}.",
	},
})

local module = ns:NewModule("TrainerReminder", {
	title = L.TITLE,
	description = L.DESC,
	note = L.NOTE,
	category = "REMINDERS",
	order = 30,
	defaults = {
		-- [player GUID] = { { name, rank, level, cost, icon }, ... }
		characters = {},
	},
	options = {
	},
	status = function(self)
		if not self.db.characters[UnitGUID("player")] then
			return L.STATUS_NO_RECORD
		end
	end,
})

local FormatMoney = ns.Utils.FormatMoney
local IsSecret = ns.Utils.IsSecret

-- Only class trainers: profession trainers need skill ranks, pet trainers
-- cost training points instead of gold.
local function IsClassTrainer()
	if IsTradeskillTrainer() then
		return false
	end
	local trainerType = C_Trainer and C_Trainer.GetTrainerType and C_Trainer.GetTrainerType()
	return not (Enum.TrainerType and trainerType == Enum.TrainerType.Pet)
end

-- Records the skills locked by level. Leaves the old record alone unless
-- the list is complete, i.e. the trainer lists unavailable skills.
function module:Record()
	if not IsClassTrainer() then
		return
	end
	if not GetTrainerServiceTypeFilter("unavailable") then
		if not self.filterHintShown then
			self.filterHintShown = true
			self:Print(L.FILTER_OFF)
		end
		return
	end
	local level = UnitLevel("player")
	local upcoming = {}
	for i = 1, GetNumTrainerServices() do
		local name, serviceType, icon, reqLevel, rank = GetTrainerServiceInfo(i)
		if serviceType == "unavailable" and type(name) == "string" and not IsSecret(name)
			and type(reqLevel) == "number" and reqLevel > level then
			local cost = GetTrainerServiceCost(i)
			upcoming[#upcoming + 1] = {
				name = name,
				rank = rank ~= "" and rank or nil,
				level = reqLevel,
				cost = type(cost) == "number" and cost or 0,
				icon = (type(icon) == "number" or type(icon) == "string") and not IsSecret(icon) and icon or nil,
			}
		end
	end
	self.db.characters[UnitGUID("player")] = upcoming
end

-- Records from before icons were stored, or skills the trainer listed without
-- one, fall back to the spell's icon by name (works for new ranks of spells
-- the character already knows).
local function GetIcon(skill)
	local icon = skill.icon
	if not icon and C_Spell and C_Spell.GetSpellTexture then
		icon = C_Spell.GetSpellTexture(skill.name)
		if IsSecret(icon) then
			icon = nil
		end
	end
	return icon
end

local function WithIcon(icon, text)
	return icon and ("|T%s:0|t %s"):format(icon, text) or text
end

-- Popup text and icon for reaching `level`, or nil without new skills.
function module:BuildNotice(level)
	local upcoming = self.db.characters[UnitGUID("player")]
	if not upcoming then
		return nil
	end
	local names, total, waiting, firstIcon = {}, 0, 0, nil
	for _, skill in ipairs(upcoming) do
		if skill.level == level then
			local text = skill.rank and ("%s (%s)"):format(skill.name, skill.rank) or skill.name
			local icon = GetIcon(skill)
			firstIcon = firstIcon or icon
			names[#names + 1] = WithIcon(icon, text)
			total = total + skill.cost
		elseif skill.level < level then
			waiting = waiting + 1
		end
	end
	if #names == 0 then
		return nil
	end
	local lines = { L.NEW:format(level, FormatMoney(total)) }
	for _, name in ipairs(names) do
		lines[#lines + 1] = name
	end
	if waiting > 0 then
		lines[#lines + 1] = L.WAITING:format(waiting)
	end
	return table.concat(lines, "\n"), firstIcon
end

function module:OnLevelUp(level)
	if type(level) ~= "number" then
		return
	end
	local text, icon = self:BuildNotice(level)
	if text then
		self:Notice(text, icon)
	end
end

function module:OnEnable()
	self.filterHintShown = false
	self:RegisterEvent("TRAINER_SHOW", self.Record)
	self:RegisterEvent("TRAINER_UPDATE", self.Record)
	self:RegisterEvent("PLAYER_LEVEL_UP", self.OnLevelUp)
end
