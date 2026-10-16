-- luacheck: read globals InCombatLockdown
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Nameplates",
		NOTE = "Range, stacking and friendly nameplates",
		DESC = "Settings for the nameplates above units. Changes made in combat apply when combat ends.",
		DISTANCE = "Range",
		DISTANCE_DESC = "Maximum distance in yards at which nameplates are shown. The client may cap high values.",
		MOTION = "Arrangement",
		MOTION_DESC = "How nameplates of nearby units are arranged.",
		OVERLAPPING = "Overlapping",
		STACKING = "Stacking",
		FRIENDS = "Friendly players",
		FRIENDS_DESC = "Also shows nameplates for friendly players.",
	},
	deDE = {
		TITLE = "Namensplaketten",
		NOTE = "Reichweite, Stapeln und freundliche Plaketten",
		DESC = "Einstellungen für die Namensplaketten über Einheiten. Änderungen im Kampf werden nach dem Kampf übernommen.",
		DISTANCE = "Reichweite",
		DISTANCE_DESC = "Maximale Entfernung in Metern, bis zu der Namensplaketten angezeigt werden. Der Client kann hohe Werte begrenzen.",
		MOTION = "Anordnung",
		MOTION_DESC = "Wie die Namensplaketten nahe beieinander stehender Einheiten angeordnet werden.",
		OVERLAPPING = "Überlappend",
		STACKING = "Gestapelt",
		FRIENDS = "Freundliche Spieler",
		FRIENDS_DESC = "Zeigt auch Namensplaketten für freundliche Spieler.",
	},
})

local function FormatYards(value)
	return ("%d"):format(value)
end

local module = ns:NewModule("Nameplates", {
	title = L.TITLE,
	description = L.DESC,
	note = L.NOTE,
	category = "INTERFACE",
	-- Nameplate CVars can't be changed in combat.
	combatProtected = true,
	defaults = {
		distance = 40,
		motion = "1",
		friends = false,
	},
	options = {
		{ key = "distance", type = "slider", label = L.DISTANCE, tooltip = L.DISTANCE_DESC, min = 10, max = 60, step = 5, format = FormatYards },
		{
			key = "motion",
			type = "dropdown",
			label = L.MOTION,
			tooltip = L.MOTION_DESC,
			values = {
				{ value = "0", label = L.OVERLAPPING },
				{ value = "1", label = L.STACKING },
			},
		},
		{ key = "friends", type = "checkbox", label = L.FRIENDS, tooltip = L.FRIENDS_DESC },
	},
})

function module:Apply()
	if InCombatLockdown() then
		self:RegisterEvent("PLAYER_REGEN_ENABLED", self.Apply)
		return
	end
	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	self:SetCVar("nameplateMaxDistance", self.db.distance)
	self:SetCVar("nameplateMotion", self.db.motion)
	self:SetCVar("nameplateShowFriends", self.db.friends)
end

function module:OnEnable()
	self:Apply()
end

function module:OnOptionChanged()
	self:Apply()
end
