-- luacheck: read globals C_Trainer Enum UnitGUID UnitLevel IsTradeskillTrainer GetNumTrainerServices GetTrainerServiceInfo GetTrainerServiceCost GetTrainerServiceTypeFilter
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Trainer reminder",
		NOTE = "Tells you on level-up what your class trainer has",
		DESC = "Remembers which skills your class trainer will teach at higher levels. When you reach such a level, a chat message lists them with their cost. Needs one visit at your class trainer with the \"Unavailable\" filter turned on; without that nothing is announced.",
		NEW = "Level %d – new at your class trainer: %s (%s)",
		WAITING = "%d more skill(s) from earlier levels are still waiting at your trainer.",
		FILTER_OFF = "Trainer reminder: turn on the \"Unavailable\" filter in the trainer window so upcoming skills can be remembered.",
	},
	deDE = {
		TITLE = "Lehrer-Erinnerung",
		NOTE = "Meldet beim Level-up, was dein Klassenlehrer hat",
		DESC = "Merkt sich, welche Fähigkeiten dein Klassenlehrer auf höheren Stufen lehrt. Erreichst du eine solche Stufe, listet eine Chatnachricht sie mit ihren Kosten auf. Benötigt einen Besuch beim Klassenlehrer mit aktiviertem Filter „Nicht verfügbar“; ohne das wird nichts gemeldet.",
		NEW = "Stufe %d – neu bei deinem Klassenlehrer: %s (%s)",
		WAITING = "%d weitere Fähigkeit(en) früherer Stufen warten noch bei deinem Lehrer.",
		FILTER_OFF = "Lehrer-Erinnerung: Aktiviere im Lehrerfenster den Filter „Nicht verfügbar“, damit kommende Fähigkeiten gemerkt werden können.",
	},
})

local module = ns:NewModule("TrainerReminder", {
	title = L.TITLE,
	description = L.DESC,
	note = L.NOTE,
	category = "MERCHANT",
	defaults = {
		-- [player GUID] = { { name, rank, level, cost }, ... }
		characters = {},
	},
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
		local name, serviceType, _, reqLevel, rank = GetTrainerServiceInfo(i)
		if serviceType == "unavailable" and type(name) == "string" and not IsSecret(name)
			and type(reqLevel) == "number" and reqLevel > level then
			local cost = GetTrainerServiceCost(i)
			upcoming[#upcoming + 1] = {
				name = name,
				rank = rank ~= "" and rank or nil,
				level = reqLevel,
				cost = type(cost) == "number" and cost or 0,
			}
		end
	end
	self.db.characters[UnitGUID("player")] = upcoming
end

function module:OnLevelUp(level)
	local upcoming = self.db.characters[UnitGUID("player")]
	if not upcoming or type(level) ~= "number" then
		return
	end
	local names, total, waiting = {}, 0, 0
	for _, skill in ipairs(upcoming) do
		if skill.level == level then
			names[#names + 1] = skill.rank and ("%s (%s)"):format(skill.name, skill.rank) or skill.name
			total = total + skill.cost
		elseif skill.level < level then
			waiting = waiting + 1
		end
	end
	if #names == 0 then
		return
	end
	self:Print(L.NEW:format(level, table.concat(names, ", "), FormatMoney(total)))
	if waiting > 0 then
		self:Print(L.WAITING:format(waiting))
	end
end

function module:OnEnable()
	self.filterHintShown = false
	self:RegisterEvent("TRAINER_SHOW", self.Record)
	self:RegisterEvent("TRAINER_UPDATE", self.Record)
	self:RegisterEvent("PLAYER_LEVEL_UP", self.OnLevelUp)
end
