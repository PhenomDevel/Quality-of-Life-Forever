-- luacheck: read globals Enum
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "IDs in tooltips",
		NOTE = "Item and spell IDs for guides and databases",
		DESC = "Adds the ID of items and spells to their tooltips, e.g. to look them up in a database or guide.",
		ITEM_ID = "Item ID: %d",
		SPELL_ID = "Spell ID: %d",
	},
	deDE = {
		TITLE = "IDs in Tooltips",
		NOTE = "Gegenstands- und Zauber-IDs für Guides und Datenbanken",
		DESC = "Ergänzt Tooltips von Gegenständen und Zaubern um ihre ID, z. B. zum Nachschlagen in einer Datenbank oder einem Guide.",
		ITEM_ID = "Gegenstands-ID: %d",
		SPELL_ID = "Zauber-ID: %d",
	},
})

local module = ns:NewModule("TooltipIDs", {
	title = L.TITLE,
	description = L.DESC,
	note = L.NOTE,
	category = "TOOLTIP",
	order = 30,
})

local function AddID(format)
	return function(_, tooltip, data)
		if data and data.id ~= nil and not ns.Utils.IsSecret(data.id) then
			tooltip:AddLine(format:format(data.id), 0.6, 0.6, 0.6)
		end
	end
end

function module:OnInitialize()
	self:AddTooltipPostCall(Enum.TooltipDataType.Item, AddID(L.ITEM_ID))
	self:AddTooltipPostCall(Enum.TooltipDataType.Spell, AddID(L.SPELL_ID))
end
