local _, ns = ...

local L = ns.L

local module = ns:NewModule("FastLoot", {
	title = L.FAST_LOOT_TITLE,
	description = L.FAST_LOOT_DESC,
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
