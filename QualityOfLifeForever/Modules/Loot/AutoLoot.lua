local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Auto loot",
		DESC = "Turns on the game's auto loot setting.",
		NOTICE = "Changes the game setting `autoLootDefault`. Disabling restores your previous setting.",
	},
	deDE = {
		TITLE = "Automatisch plündern",
		DESC = "Aktiviert das automatische Plündern des Spiels.",
		NOTICE = "Ändert die Spieleinstellung `autoLootDefault`. Beim Deaktivieren wird deine vorherige Einstellung wiederhergestellt.",
	},
})

local module = ns:NewModule("AutoLoot", {
	title = L.TITLE,
	description = L.DESC,
	notice = L.NOTICE,
	category = "LOOT",
})

function module:OnEnable()
	self:SetCVar("autoLootDefault", true)
end
