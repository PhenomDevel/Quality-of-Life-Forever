local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Free bag slots",
		NOTE = "Free slots on the backpack button",
		DESC = "Turns on the game's own count of free bag slots on the backpack button.",
		NOTICE = "Changes the game setting `displayFreeBagSlots`. Disabling restores your previous setting.",
	},
	deDE = {
		TITLE = "Freie Taschenplätze",
		NOTE = "Freie Plätze am Rucksack-Button",
		DESC = "Schaltet die spieleigene Anzeige freier Taschenplätze auf dem Rucksack-Button ein.",
		NOTICE = "Ändert die Spieleinstellung `displayFreeBagSlots`. Beim Deaktivieren wird deine vorherige Einstellung wiederhergestellt.",
	},
})

local module = ns:NewModule("BagFreeSlots", {
	title = L.TITLE,
	description = L.DESC,
	note = L.NOTE,
	notice = L.NOTICE,
	category = "BAGS",
})

function module:OnEnable()
	self:SetCVar("displayFreeBagSlots", true)
end
