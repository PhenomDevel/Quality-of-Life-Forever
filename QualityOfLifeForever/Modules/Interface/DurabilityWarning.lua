-- luacheck: read globals GetInventoryItemDurability GetInventoryItemLink INVSLOT_FIRST_EQUIPPED INVSLOT_LAST_EQUIPPED PlaySound SOUNDKIT UIErrorsFrame
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Durability warning",
		NOTE = "Reminds you to repair",
		DESC = "Warns you once when an equipped item drops below the durability threshold. After a repair the warning is armed again.",
		THRESHOLD = "Warn below",
		THRESHOLD_DESC = "Durability in percent at which the warning appears; the most worn item counts.",
		SECTION_HOW = "How to warn",
		SCREEN = "Also on screen",
		SCREEN_DESC = "Shows the warning in the middle of the screen as well as in chat.",
		SOUND = "Sound",
		SOUND_DESC = "Plays a sound with the warning.",
		MESSAGE = "Durability low: %s at %d%%. Time to repair.",
	},
	deDE = {
		TITLE = "Haltbarkeits-Warnung",
		NOTE = "Erinnert ans Reparieren",
		DESC = "Warnt dich einmal, wenn ein angelegter Gegenstand unter die Haltbarkeits-Schwelle fällt. Nach einer Reparatur ist die Warnung wieder scharf.",
		THRESHOLD = "Warnen unter",
		THRESHOLD_DESC = "Haltbarkeit in Prozent, ab der die Warnung erscheint; es zählt der am stärksten abgenutzte Gegenstand.",
		SECTION_HOW = "Wie warnen",
		SCREEN = "Auch auf dem Bildschirm",
		SCREEN_DESC = "Zeigt die Warnung zusätzlich zum Chat in der Bildschirmmitte.",
		SOUND = "Ton",
		SOUND_DESC = "Spielt einen Ton zur Warnung.",
		MESSAGE = "Haltbarkeit niedrig: %s bei %d %%. Zeit zum Reparieren.",
	},
})

local function FormatPercent(value)
	return ("%d%%"):format(value)
end

local module = ns:NewModule("DurabilityWarning", {
	title = L.TITLE,
	description = L.DESC,
	note = L.NOTE,
	category = "INTERFACE",
	defaults = {
		threshold = 20,
		screen = true,
		sound = true,
	},
	options = {
		{ key = "threshold", type = "slider", label = L.THRESHOLD, tooltip = L.THRESHOLD_DESC, min = 5, max = 50, step = 5, format = FormatPercent },
		{ type = "header", label = L.SECTION_HOW },
		{ key = "screen", type = "checkbox", label = L.SCREEN, tooltip = L.SCREEN_DESC },
		{ key = "sound", type = "checkbox", label = L.SOUND, tooltip = L.SOUND_DESC },
	},
})

local IsSecret = ns.Utils.IsSecret
-- Set after a warning; cleared once every item is above the threshold again.
local warned = false

-- Lowest durability in percent among equipped items, and that item's slot.
local function FindMostWorn()
	local lowest, lowestSlot
	for slot = INVSLOT_FIRST_EQUIPPED, INVSLOT_LAST_EQUIPPED do
		local current, maximum = GetInventoryItemDurability(slot)
		if current and maximum and maximum > 0 and not IsSecret(current) and not IsSecret(maximum) then
			local percent = current / maximum * 100
			if not lowest or percent < lowest then
				lowest, lowestSlot = percent, slot
			end
		end
	end
	return lowest, lowestSlot
end

function module:Check()
	local lowest, slot = FindMostWorn()
	if not lowest or lowest >= self.db.threshold then
		warned = false
		return
	end
	if warned then
		return
	end
	warned = true
	local message = L.MESSAGE:format(GetInventoryItemLink("player", slot) or "?", math.floor(lowest))
	self:Print(message)
	if self.db.screen and UIErrorsFrame then
		UIErrorsFrame:AddMessage(message, 1, 0.5, 0)
	end
	if self.db.sound then
		PlaySound(SOUNDKIT.RAID_WARNING, "Master")
	end
end

function module:OnOptionChanged(key)
	if key == "threshold" then
		warned = false
		self:Check()
	end
end

function module:OnEnable()
	warned = false
	self:RegisterEvent("UPDATE_INVENTORY_DURABILITY", self.Check)
	self:Check()
end
