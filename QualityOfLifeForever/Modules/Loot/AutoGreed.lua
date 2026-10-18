-- luacheck: read globals GetLootRollItemInfo GetLootRollItemLink RollOnLoot
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Auto greed",
		NOTE = "Greed on green items in group loot",
		DESC = "Rolls {Greed} for you on green items in group loot. {Bind on Pickup} items are always left to you.",
		MAX_QUALITY = "Items up to",
		MAX_QUALITY_DESC = "Highest quality that is rolled automatically.",
		UNCOMMON = "Uncommon (green)",
		RARE = "Rare (blue)",
		SKIP_NEED = "Not on items you can need",
		SKIP_NEED_DESC = "Leaves items your character can use to you, so you can roll {Need} on upgrades.",
		ANNOUNCE = "Message in chat",
		ANNOUNCE_DESC = "Prints each item you rolled greed on.",
		ROLLED = "Greed: %s",
	},
	deDE = {
		TITLE = "Automatisch Gier",
		NOTE = "Gier auf grüne Gegenstände beim Gruppenplündern",
		DESC = "Würfelt beim Gruppenplündern für dich {Gier} auf grüne Gegenstände. Gegenstände, die {Beim Aufheben gebunden} werden, bleiben immer dir überlassen.",
		MAX_QUALITY = "Gegenstände bis",
		MAX_QUALITY_DESC = "Höchste Qualität, auf die automatisch gewürfelt wird.",
		UNCOMMON = "Selten (grün)",
		RARE = "Rar (blau)",
		SKIP_NEED = "Nicht bei Bedarf möglich",
		SKIP_NEED_DESC = "Überlässt dir Gegenstände, die dein Charakter benutzen kann, damit du bei Verbesserungen {Bedarf} würfeln kannst.",
		ANNOUNCE = "Nachricht im Chat",
		ANNOUNCE_DESC = "Gibt jeden Gegenstand aus, auf den Gier gewürfelt wurde.",
		ROLLED = "Gier: %s",
	},
})

local module = ns:NewModule("AutoGreed", {
	title = L.TITLE,
	description = L.DESC,
	note = L.NOTE,
	category = "LOOT",
	defaults = {
		maxQuality = 2,
		skipNeed = false,
		announce = true,
	},
	options = {
		{
			key = "maxQuality",
			type = "dropdown",
			label = L.MAX_QUALITY,
			tooltip = L.MAX_QUALITY_DESC,
			values = {
				{ value = 2, label = L.UNCOMMON },
				{ value = 3, label = L.RARE },
			},
		},
		{ key = "skipNeed", type = "checkbox", label = L.SKIP_NEED, tooltip = L.SKIP_NEED_DESC },
		{ key = "announce", type = "checkbox", label = L.ANNOUNCE, tooltip = L.ANNOUNCE_DESC },
	},
})

-- RollOnLoot roll types.
local GREED = 2
local MIN_QUALITY = 2

function module:START_LOOT_ROLL(rollID)
	local _, _, _, quality, bindOnPickUp, canNeed, canGreed = GetLootRollItemInfo(rollID)
	if not quality or quality < MIN_QUALITY or quality > self.db.maxQuality then
		return
	end
	if bindOnPickUp or not canGreed or (canNeed and self.db.skipNeed) then
		return
	end
	-- Read before rolling: the roll is gone once the server accepts it.
	local link = GetLootRollItemLink(rollID)
	RollOnLoot(rollID, GREED)
	if self.db.announce and link then
		self:Print(L.ROLLED:format(link))
	end
end

function module:OnEnable()
	self:RegisterEvent("START_LOOT_ROLL")
end
