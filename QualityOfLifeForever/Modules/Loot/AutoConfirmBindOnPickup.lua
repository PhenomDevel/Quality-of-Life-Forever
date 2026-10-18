-- luacheck: read globals ConfirmLootSlot IsInGroup
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Auto-confirm BoP loot",
		NOTE = "Only while you are not in a group",
		DESC = "Automatically confirms the \"Bind on Pickup\" loot dialog while you are not in a group.",
	},
	deDE = {
		TITLE = "BoP automatisch bestätigen",
		NOTE = "Nur, solange du in keiner Gruppe bist",
		DESC = "Bestätigt die Abfrage „Beim Aufheben gebunden“ beim Plündern automatisch, solange du in keiner Gruppe bist.",
	},
})

local module = ns:NewModule("AutoConfirmBindOnPickup", {
	title = L.TITLE,
	description = L.DESC,
	note = L.NOTE,
	category = "LOOT",
})

function module:OnEnable()
	self:RegisterEvent("LOOT_BIND_CONFIRM")
end

function module:LOOT_BIND_CONFIRM(slot)
	if IsInGroup() then
		return
	end
	ConfirmLootSlot(slot)
	StaticPopup_Hide("LOOT_BIND")
end
