-- luacheck: read globals C_Spell C_SpellBook C_UnitAuras C_Timer UnitClass UnitIsDeadOrGhost IsMounted UnitOnTaxi IsResting InCombatLockdown PlaySound SOUNDKIT
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Missing self-buffs",
		NOTE = "Reminds you of your long-lasting buffs",
		DESC = "Shows a popup out of combat when one of your class's long-lasting buffs is missing, e.g. Arcane Intellect, Inner Fire, Mark of the Wild or Demon Skin. Only buffs you have learned count; for buffs with alternatives (armors, auras, aspects) any one of them is enough.",
		SECTION_WHEN = "When to remind",
		SECTION_HOW = "How to remind",
		NOT_RESTING = "Not in rest areas",
		NOT_RESTING_DESC = "No reminder in inns and cities.",
		SOUND = "Sound",
		SOUND_DESC = "Plays a sound with the reminder.",
		PREVIEW = "Preview",
		PREVIEW_DESC = "Shows the reminder popup with all buffs of your class you have learned.",
		PREVIEW_BUTTON = "Show",
		MESSAGE = "Missing: %s",
		NONE = "No buffs of your class learned yet.",
	},
	deDE = {
		TITLE = "Fehlende Selbst-Buffs",
		NOTE = "Erinnert an deine lang anhaltenden Buffs",
		DESC = "Zeigt außerhalb des Kampfes ein Popup, wenn einer der lang anhaltenden Buffs deiner Klasse fehlt, z. B. Arkane Intelligenz, Inneres Feuer, Mal der Wildnis oder Dämonenhaut. Es zählen nur Buffs, die du gelernt hast; bei Buffs mit Alternativen (Rüstungen, Auren, Aspekte) reicht einer davon.",
		SECTION_WHEN = "Wann erinnern",
		SECTION_HOW = "Wie erinnern",
		NOT_RESTING = "Nicht in Erholungsgebieten",
		NOT_RESTING_DESC = "Keine Erinnerung in Gasthäusern und Städten.",
		SOUND = "Ton",
		SOUND_DESC = "Spielt einen Ton zur Erinnerung.",
		PREVIEW = "Vorschau",
		PREVIEW_DESC = "Zeigt das Erinnerungs-Popup mit allen gelernten Buffs deiner Klasse.",
		PREVIEW_BUTTON = "Anzeigen",
		MESSAGE = "Es fehlt: %s",
		NONE = "Noch keine Buffs deiner Klasse gelernt.",
	},
})

local module = ns:NewModule("MissingBuffs", {
	title = L.TITLE,
	description = L.DESC,
	note = L.NOTE,
	category = "REMINDERS",
	defaults = {
		notResting = true,
		sound = false,
	},
	options = {
		{ type = "header", label = L.SECTION_WHEN },
		{ key = "notResting", type = "checkbox", label = L.NOT_RESTING, tooltip = L.NOT_RESTING_DESC },
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

-- Long-lasting self-buffs by class file name; each entry lists alternatives,
-- any one of them counts. Rank 1 spell IDs from wowhead.com (Classic); the
-- aura is matched by name, so every rank counts.
local BUFFS = {
	DRUID = {
		{ 1126 }, -- Mark of the Wild
	},
	HUNTER = {
		{ 13165, 13163 }, -- Aspect of the Hawk, Aspect of the Monkey
	},
	MAGE = {
		{ 1459 }, -- Arcane Intellect
		{ 168, 7302, 6117 }, -- Frost Armor, Ice Armor, Mage Armor
	},
	PALADIN = {
		{ 465, 7294, 19746 }, -- Devotion, Retribution, Concentration Aura
	},
	PRIEST = {
		{ 1243 }, -- Power Word: Fortitude
		{ 588 }, -- Inner Fire
	},
	SHAMAN = {
		{ 324 }, -- Lightning Shield
	},
	WARLOCK = {
		{ 687, 706 }, -- Demon Skin, Demon Armor
	},
}

-- Debounces UNIT_AURA bursts (e.g. several buffs at once).
local CHECK_DELAY = 1

local IsSecret = ns.Utils.IsSecret
local pending
-- Names of the missing buffs at the last popup; no new popup until it changes.
local lastMissing = ""

local function IsKnown(spellID)
	return C_SpellBook.IsSpellKnown(spellID) == true
end

local function HasBuff(name)
	local aura = C_UnitAuras.GetAuraDataBySpellName("player", name, "HELPFUL")
	return aura ~= nil and not IsSecret(aura)
end

-- Names of known buff groups, all of them or only those without an active
-- aura, plus the icon of the first one.
local function Collect(missingOnly)
	local _, class = UnitClass("player")
	local names, icon = {}, nil
	for _, group in ipairs(BUFFS[class] or {}) do
		local known, active = nil, false
		for _, spellID in ipairs(group) do
			local name = C_Spell.GetSpellName(spellID)
			if name and not IsSecret(name) then
				if IsKnown(spellID) then
					known = known or { name = name, icon = C_Spell.GetSpellTexture(spellID) }
				end
				if HasBuff(name) then
					active = true
				end
			end
		end
		if known and not (missingOnly and active) then
			names[#names + 1] = known.name
			icon = icon or known.icon
		end
	end
	return names, icon
end

local function ShouldCheck(self)
	return not InCombatLockdown() and not UnitIsDeadOrGhost("player") and not IsMounted()
		and not UnitOnTaxi("player") and not (self.db.notResting and IsResting())
end

function module:Remind(names, icon)
	self:Notice(L.MESSAGE:format(table.concat(names, ", ")), icon)
	if self.db.sound then
		PlaySound(SOUNDKIT.RAID_WARNING, "Master")
	end
end

function module:Check()
	pending = nil
	if not self.enabled or not ShouldCheck(self) then
		return
	end
	local names, icon = Collect(true)
	local key = table.concat(names, ", ")
	if key ~= lastMissing and #names > 0 then
		self:Remind(names, icon)
	end
	lastMissing = key
end

function module:QueueCheck()
	if not pending then
		pending = C_Timer.NewTimer(CHECK_DELAY, function()
			self:Check()
		end)
	end
end

function module:Preview()
	local names, icon = Collect(false)
	if #names > 0 then
		self:Remind(names, icon)
	else
		self:Notice(L.NONE)
	end
end

function module:OnEnable()
	lastMissing = ""
	self:RegisterEvent("UNIT_AURA", function(_, unit)
		if unit == "player" then
			self:QueueCheck()
		end
	end)
	for _, event in ipairs({ "PLAYER_REGEN_ENABLED", "PLAYER_ENTERING_WORLD", "PLAYER_UPDATE_RESTING", "PLAYER_MOUNT_DISPLAY_CHANGED", "PLAYER_UNGHOST", "PLAYER_ALIVE", "SPELLS_CHANGED" }) do
		self:RegisterEvent(event, self.QueueCheck)
	end
	self:QueueCheck()
end

function module:OnDisable()
	if pending then
		pending:Cancel()
		pending = nil
	end
end
