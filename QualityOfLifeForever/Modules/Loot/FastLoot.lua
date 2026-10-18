-- luacheck: read globals GetCVarBool GetNumLootItems IsModifiedClick LootSlot
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Fast loot",
		NOTE = "Needs auto loot",
		DESC = "Loots all items instantly when auto loot is on instead of waiting for the loot window. Auto loot comes from the game setting or the {Auto loot} module.",
	},
	deDE = {
		TITLE = "Schnelles Plündern",
		NOTE = "Braucht automatisches Plündern",
		DESC = "Plündert bei aktivem automatischem Plündern alle Gegenstände sofort, ohne auf das Beutefenster zu warten. Automatisches Plündern kommt aus der Spieleinstellung oder dem Modul {Automatisch plündern}.",
	},
})

local module = ns:NewModule("FastLoot", {
	title = L.TITLE,
	description = L.DESC,
	note = L.NOTE,
	category = "LOOT",
	defaultEnabled = false,
})

-- LOOT_READY can fire several times for the same loot window.
local LOOT_THROTTLE = 0.3

function module:OnEnable()
	self:RegisterEvent("LOOT_READY")
end

local function IsAutoLootActive(autoLoot)
	if autoLoot ~= nil then
		return autoLoot
	end
	return GetCVarBool("autoLootDefault") ~= IsModifiedClick("AUTOLOOTTOGGLE")
end

function module:LOOT_READY(autoLoot)
	if not IsAutoLootActive(autoLoot) then
		return
	end
	local now = GetTime()
	if self.lastLoot and now - self.lastLoot < LOOT_THROTTLE then
		return
	end
	self.lastLoot = now

	for slot = GetNumLootItems(), 1, -1 do
		LootSlot(slot)
	end
end
