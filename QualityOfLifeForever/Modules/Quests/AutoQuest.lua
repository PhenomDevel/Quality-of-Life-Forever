-- luacheck: read globals C_GossipInfo IsShiftKeyDown QuestGetAutoAccept AcknowledgeAutoAcceptQuest AcceptQuest IsQuestCompletable CompleteQuest GetNumQuestChoices GetQuestReward GetQuestMoneyToGet GetNumActiveQuests GetActiveTitle SelectActiveQuest GetNumAvailableQuests GetAvailableQuestInfo SelectAvailableQuest GetQuestID C_QuestLog UnitLevel UnitQuestTrivialLevelRange
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Auto quests",
		NOTE = "Accept and turn in quests; hold Shift to pause",
		DESC = "Accepts offered quests and turns in completed ones without clicking. Stops when you have to choose a reward or a quest costs money. Hold Shift while talking to the NPC to do it yourself.",
		ACCEPT = "Accept quests",
		ACCEPT_DESC = "Accepts quests offered by NPCs.",
		TURN_IN = "Turn in quests",
		TURN_IN_DESC = "Turns in completed quests unless a reward has to be chosen.",
		SKIP_TRIVIAL = "Skip low-level quests",
		SKIP_TRIVIAL_DESC = "Doesn't accept quests that are gray (far below your level).",
	},
	deDE = {
		TITLE = "Automatische Quests",
		NOTE = "Quests annehmen und abgeben; Shift pausiert",
		DESC = "Nimmt angebotene Quests an und gibt abgeschlossene ab, ohne zu klicken. Hält an, wenn eine Belohnung gewählt werden muss oder eine Quest Gold kostet. Shift beim Ansprechen halten, um es selbst zu machen.",
		ACCEPT = "Quests annehmen",
		ACCEPT_DESC = "Nimmt von NPCs angebotene Quests an.",
		TURN_IN = "Quests abgeben",
		TURN_IN_DESC = "Gibt abgeschlossene Quests ab, außer es muss eine Belohnung gewählt werden.",
		SKIP_TRIVIAL = "Niedrigstufige Quests auslassen",
		SKIP_TRIVIAL_DESC = "Nimmt keine grauen Quests an (weit unter deiner Stufe).",
	},
})

local module = ns:NewModule("AutoQuest", {
	title = L.TITLE,
	description = L.DESC,
	note = L.NOTE,
	category = "QUESTS",
	defaults = {
		accept = true,
		turnIn = true,
		skipTrivial = true,
	},
	options = {
		{ key = "accept", type = "checkbox", label = L.ACCEPT, tooltip = L.ACCEPT_DESC },
		{ key = "turnIn", type = "checkbox", label = L.TURN_IN, tooltip = L.TURN_IN_DESC },
		{ key = "skipTrivial", type = "checkbox", label = L.SKIP_TRIVIAL, tooltip = L.SKIP_TRIVIAL_DESC },
	},
})

local function Paused()
	return IsShiftKeyDown()
end

-- Gray quests. The flag from the NPC list isn't reliable in Forever, so the
-- quest ID and the level are checked as well.
local function IsTrivial(questID, questLevel, flag)
	if flag then
		return true
	end
	if questID and C_QuestLog.IsQuestTrivial(questID) then
		return true
	end
	if questLevel and questLevel > 0 then
		return UnitLevel("player") - questLevel > UnitQuestTrivialLevelRange("player")
	end
	return false
end

function module:Skip(questID, questLevel, flag)
	return self.db.skipTrivial and IsTrivial(questID, questLevel, flag)
end

-- Gossip NPCs: turn in the first completed quest, else pick the first
-- acceptable one. Incomplete active quests are never selected, so this can't
-- loop.
function module:GOSSIP_SHOW()
	if Paused() then
		return
	end
	if self.db.turnIn then
		for _, quest in ipairs(C_GossipInfo.GetActiveQuests()) do
			if quest.isComplete then
				C_GossipInfo.SelectActiveQuest(quest.questID)
				return
			end
		end
	end
	if self.db.accept then
		for _, quest in ipairs(C_GossipInfo.GetAvailableQuests()) do
			if not self:Skip(quest.questID, quest.questLevel, quest.isTrivial) then
				C_GossipInfo.SelectAvailableQuest(quest.questID)
				return
			end
		end
	end
end

-- Quest greeting NPCs (no gossip) use the index based API.
function module:QUEST_GREETING()
	if Paused() then
		return
	end
	if self.db.turnIn then
		for i = 1, GetNumActiveQuests() do
			local _, isComplete = GetActiveTitle(i)
			if isComplete then
				SelectActiveQuest(i)
				return
			end
		end
	end
	if self.db.accept then
		for i = 1, GetNumAvailableQuests() do
			local isTrivial, _, _, _, questID = GetAvailableQuestInfo(i)
			if not self:Skip(questID, nil, isTrivial) then
				SelectAvailableQuest(i)
				return
			end
		end
	end
end

function module:QUEST_DETAIL()
	if Paused() or not self.db.accept then
		return
	end
	if QuestGetAutoAccept() then
		AcknowledgeAutoAcceptQuest()
	elseif not self:Skip(GetQuestID()) then
		-- NPCs with a single quest open the quest window directly.
		AcceptQuest()
	end
end

function module:QUEST_PROGRESS()
	if Paused() or not self.db.turnIn then
		return
	end
	if IsQuestCompletable() and GetQuestMoneyToGet() == 0 then
		CompleteQuest()
	end
end

function module:QUEST_COMPLETE()
	if Paused() or not self.db.turnIn then
		return
	end
	local choices = GetNumQuestChoices()
	if choices <= 1 and GetQuestMoneyToGet() == 0 then
		GetQuestReward(choices)
	end
end

function module:OnEnable()
	for _, event in ipairs({ "GOSSIP_SHOW", "QUEST_GREETING", "QUEST_DETAIL", "QUEST_PROGRESS", "QUEST_COMPLETE" }) do
		self:RegisterEvent(event)
	end
end
