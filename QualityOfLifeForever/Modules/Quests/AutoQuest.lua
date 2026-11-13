-- luacheck: read globals C_GossipInfo IsShiftKeyDown QuestGetAutoAccept AcknowledgeAutoAcceptQuest AcceptQuest IsQuestCompletable CompleteQuest GetNumQuestChoices GetQuestReward GetQuestMoneyToGet GetNumActiveQuests GetActiveTitle SelectActiveQuest GetNumAvailableQuests GetAvailableQuestInfo SelectAvailableQuest GetQuestID C_QuestLog UnitLevel UnitQuestTrivialLevelRange UnitExists GetTime C_Timer GetObjectiveText GetTitleText
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Auto-quests",
		SECTION_ACTIONS = "Actions",
		SECTION_FILTER = "Filter",
		NOTE = "Accept and turn in quests; hold Shift to pause",
		DESC = "Accepts offered quests and turns in completed ones without clicking. Stops when you have to choose a reward or a quest costs money, and for the rest of the conversation when the game reports an error (e.g. quest log or bags full). Hold Shift while talking to the NPC to do it yourself.",
		ACCEPT = "Accept quests",
		ACCEPT_DESC = "Accepts quests offered by NPCs.",
		TURN_IN = "Turn in quests",
		TURN_IN_DESC = "Turns in completed quests unless a reward has to be chosen.",
		SKIP_TRIVIAL = "Skip gray quests",
		SKIP_TRIVIAL_DESC = "Doesn't accept quests that are gray (far below your level).",
		SKIP_ESCORT = "Skip escort quests",
		SKIP_ESCORT_DESC = "Doesn't accept escort quests, so everyone in your group can accept them before the NPC starts walking. The game doesn't mark escort quests, so they are recognized by their objective (e.g. \"Escort …\", \"Protect …\").",
		ESCORT_SKIPPED = "Escort quest not accepted automatically: %s",
		HALTED = "Auto quests paused for this NPC: the game reported an error (e.g. quest log or bags full). Talk to the NPC again to continue.",
	},
	deDE = {
		TITLE = "Automatische Quests",
		SECTION_ACTIONS = "Aktionen",
		SECTION_FILTER = "Filter",
		NOTE = "Quests annehmen und abgeben; Shift pausiert",
		DESC = "Nimmt angebotene Quests an und gibt abgeschlossene ab, ohne zu klicken. Hält an, wenn eine Belohnung gewählt werden muss oder eine Quest Gold kostet, und für den Rest des Gesprächs, wenn das Spiel einen Fehler meldet (z. B. Questlog oder Taschen voll). Shift beim Ansprechen halten, um es selbst zu machen.",
		ACCEPT = "Quests annehmen",
		ACCEPT_DESC = "Nimmt von NPCs angebotene Quests an.",
		TURN_IN = "Quests abgeben",
		TURN_IN_DESC = "Gibt abgeschlossene Quests ab, außer es muss eine Belohnung gewählt werden.",
		SKIP_TRIVIAL = "Graue Quests auslassen",
		SKIP_TRIVIAL_DESC = "Nimmt keine grauen Quests an (weit unter deiner Stufe).",
		SKIP_ESCORT = "Eskortquests auslassen",
		SKIP_ESCORT_DESC = "Nimmt keine Eskortquests an, damit alle in deiner Gruppe sie annehmen können, bevor der NPC losläuft. Das Spiel kennzeichnet Eskortquests nicht, daher werden sie an ihrem Ziel erkannt (z. B. „Eskortiert …“, „Beschützt …“).",
		ESCORT_SKIPPED = "Eskortquest nicht automatisch angenommen: %s",
		HALTED = "Automatische Quests für diesen NPC pausiert: Das Spiel hat einen Fehler gemeldet (z. B. Questlog oder Taschen voll). Sprich den NPC erneut an, um fortzufahren.",
	},
})

local module = ns:NewModule("AutoQuest", {
	title = L.TITLE,
	description = L.DESC,
	note = L.NOTE,
	category = "QUESTS",
	order = 10,
	defaults = {
		accept = true,
		turnIn = true,
		skipTrivial = true,
		skipEscort = true,
	},
	options = {
		{ type = "header", label = L.SECTION_ACTIONS },
		{ key = "accept", type = "checkbox", label = L.ACCEPT, tooltip = L.ACCEPT_DESC },
		{ key = "turnIn", type = "checkbox", label = L.TURN_IN, tooltip = L.TURN_IN_DESC },
		{ type = "header", label = L.SECTION_FILTER },
		{ key = "skipTrivial", type = "checkbox", label = L.SKIP_TRIVIAL, tooltip = L.SKIP_TRIVIAL_DESC },
		{ key = "skipEscort", type = "checkbox", label = L.SKIP_ESCORT, tooltip = L.SKIP_ESCORT_DESC },
	},
})

-- An error right after an automated action (quest log or bags full, ...)
-- halts the automation until the NPC conversation ends; otherwise the NPC
-- would offer the same quest again and the action would repeat endlessly.
local ERROR_WINDOW = 1.5
local lastAction = 0
local halted = false

local function Act(action, ...)
	lastAction = GetTime()
	action(...)
end

local function Paused()
	return halted or IsShiftKeyDown()
end

function module:UI_ERROR_MESSAGE()
	if not halted and GetTime() - lastAction < ERROR_WINDOW then
		halted = true
		self:Print(L.HALTED)
	end
end

-- Gossip and quest frames close and reopen while switching between them, so
-- the conversation only counts as ended once no NPC is targeted anymore.
function module:OnConversationClosed()
	C_Timer.After(0.2, function()
		if not UnitExists("npc") then
			halted = false
		end
	end)
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

-- Escort quests. Neither the quest API nor the quest tags mark them, so the
-- objective text of the open quest window is matched against the verbs
-- escort quests use. Both client languages are checked, the words don't
-- occur in the other language's objectives.
local ESCORT_WORDS = {
	"escort", "protect", "accompany",
	"eskort", "beschütz", "begleit", "geleit",
}

local function IsEscort()
	local text = ((GetObjectiveText() or "") .. " " .. (GetTitleText() or "")):lower()
	for _, word in ipairs(ESCORT_WORDS) do
		if text:find(word, 1, true) then
			return true
		end
	end
	return false
end

-- Escort quests found in the quest window are remembered, so the NPC's quest
-- list doesn't open them again when you go back to it.
local skippedEscorts = {}

function module:Skip(questID, questLevel, flag)
	if self.db.skipEscort and questID and skippedEscorts[questID] then
		return true
	end
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
				Act(C_GossipInfo.SelectActiveQuest, quest.questID)
				return
			end
		end
	end
	if self.db.accept then
		for _, quest in ipairs(C_GossipInfo.GetAvailableQuests()) do
			if not self:Skip(quest.questID, quest.questLevel, quest.isTrivial) then
				Act(C_GossipInfo.SelectAvailableQuest, quest.questID)
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
				Act(SelectActiveQuest, i)
				return
			end
		end
	end
	if self.db.accept then
		for i = 1, GetNumAvailableQuests() do
			local isTrivial, _, _, _, questID = GetAvailableQuestInfo(i)
			if not self:Skip(questID, nil, isTrivial) then
				Act(SelectAvailableQuest, i)
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
		Act(AcknowledgeAutoAcceptQuest)
		return
	end
	local questID = GetQuestID()
	if self.db.skipEscort and IsEscort() then
		if questID and not skippedEscorts[questID] then
			skippedEscorts[questID] = true
			self:Print(L.ESCORT_SKIPPED:format(GetTitleText() or ""))
		end
	elseif not self:Skip(questID) then
		-- NPCs with a single quest open the quest window directly.
		Act(AcceptQuest)
	end
end

function module:QUEST_PROGRESS()
	if Paused() or not self.db.turnIn then
		return
	end
	if IsQuestCompletable() and GetQuestMoneyToGet() == 0 then
		Act(CompleteQuest)
	end
end

function module:QUEST_COMPLETE()
	if Paused() or not self.db.turnIn then
		return
	end
	local choices = GetNumQuestChoices()
	if choices <= 1 and GetQuestMoneyToGet() == 0 then
		Act(GetQuestReward, choices)
	end
end

function module:OnEnable()
	halted = false
	for _, event in ipairs({ "GOSSIP_SHOW", "QUEST_GREETING", "QUEST_DETAIL", "QUEST_PROGRESS", "QUEST_COMPLETE", "UI_ERROR_MESSAGE" }) do
		self:RegisterEvent(event)
	end
	self:RegisterEvent("GOSSIP_CLOSED", self.OnConversationClosed)
	self:RegisterEvent("QUEST_FINISHED", self.OnConversationClosed)
end
