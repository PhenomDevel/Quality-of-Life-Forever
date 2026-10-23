-- luacheck: read globals GetInventoryItemDurability GetInventoryItemLink GetInventoryItemTexture INVSLOT_FIRST_EQUIPPED INVSLOT_LAST_EQUIPPED PlaySound SOUNDKIT
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Durability warning",
		NOTE = "Reminds you to repair",
		DESC = "Warns you once with a popup when an equipped item drops below the durability threshold. After a repair the warning is armed again.",
		THRESHOLD = "Warn below",
		THRESHOLD_DESC = "Durability in percent at which the warning appears; the most worn item counts.",
		SECTION_HOW = "How to warn",
		SOUND = "Sound",
		SOUND_DESC = "Plays a sound with the warning.",
		MESSAGE = "Durability low: %s at %d%%. Time to repair.",
		PREVIEW = "Preview",
		PREVIEW_DESC = "Shows the warning popup with your most worn item.",
		PREVIEW_BUTTON = "Show",
	},
	deDE = {
		TITLE = "Haltbarkeits-Warnung",
		NOTE = "Erinnert ans Reparieren",
		DESC = "Warnt dich einmal mit einem Popup, wenn ein angelegter Gegenstand unter die Haltbarkeits-Schwelle fällt. Nach einer Reparatur ist die Warnung wieder scharf.",
		THRESHOLD = "Warnen unter",
		THRESHOLD_DESC = "Haltbarkeit in Prozent, ab der die Warnung erscheint; es zählt der am stärksten abgenutzte Gegenstand.",
		SECTION_HOW = "Wie warnen",
		SOUND = "Ton",
		SOUND_DESC = "Spielt einen Ton zur Warnung.",
		MESSAGE = "Haltbarkeit niedrig: %s bei %d %%. Zeit zum Reparieren.",
		PREVIEW = "Vorschau",
		PREVIEW_DESC = "Zeigt das Warn-Popup mit deinem am stärksten abgenutzten Gegenstand.",
		PREVIEW_BUTTON = "Anzeigen",
	},
})

local function FormatPercent(value)
	return ("%d%%"):format(value)
end

local module = ns:NewModule("DurabilityWarning", {
	title = L.TITLE,
	description = L.DESC,
	note = L.NOTE,
	category = "REMINDERS",
	order = 10,
	defaults = {
		threshold = 20,
		sound = true,
	},
	options = {
		{ key = "threshold", type = "slider", label = L.THRESHOLD, tooltip = L.THRESHOLD_DESC, min = 5, max = 50, step = 5, format = FormatPercent },
		{ type = "header", label = L.SECTION_HOW },
		{ key = "sound", type = "checkbox", label = L.SOUND, tooltip = L.SOUND_DESC },
		{
			type = "button",
			label = L.PREVIEW,
			buttonText = L.PREVIEW_BUTTON,
			tooltip = L.PREVIEW_DESC,
			onClick = function(self)
				self:Preview()
			end,
		},
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
	self:Warn(lowest, slot)
end

function module:Warn(percent, slot)
	local message = L.MESSAGE:format(GetInventoryItemLink("player", slot) or "?", math.floor(percent))
	self:Notice(message, GetInventoryItemTexture("player", slot))
	if self.db.sound then
		PlaySound(SOUNDKIT.RAID_WARNING, "Master")
	end
end

function module:Preview()
	local lowest, slot = FindMostWorn()
	if slot then
		self:Warn(lowest, slot)
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
