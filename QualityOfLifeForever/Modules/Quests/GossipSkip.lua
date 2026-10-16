-- luacheck: read globals C_GossipInfo IsShiftKeyDown
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Skip gossip",
		NOTE = "Hold Shift to see the dialog",
		DESC = "When an NPC offers exactly one dialog option and no quests (flight master, innkeeper, …), that option is selected automatically. Hold Shift while talking to the NPC to see the dialog.",
	},
	deDE = {
		TITLE = "Gespräche überspringen",
		NOTE = "Shift halten, um den Dialog zu sehen",
		DESC = "Bietet ein NPC genau eine Gesprächsoption und keine Quests an (Flugmeister, Gastwirt, …), wird diese automatisch gewählt. Shift beim Ansprechen halten, um den Dialog zu sehen.",
	},
})

local module = ns:NewModule("GossipSkip", {
	title = L.TITLE,
	description = L.DESC,
	note = L.NOTE,
	category = "QUESTS",
})

function module:GOSSIP_SHOW()
	if IsShiftKeyDown() then
		return
	end
	if C_GossipInfo.GetNumAvailableQuests() > 0 or C_GossipInfo.GetNumActiveQuests() > 0 then
		return
	end
	local options = C_GossipInfo.GetOptions()
	if #options ~= 1 then
		return
	end
	local option = options[1]
	-- Options with a failure reason (e.g. not enough money) stay visible.
	if option.gossipOptionID and not option.failureDescription then
		C_GossipInfo.SelectOption(option.gossipOptionID)
	end
end

function module:OnEnable()
	self:RegisterEvent("GOSSIP_SHOW")
end
