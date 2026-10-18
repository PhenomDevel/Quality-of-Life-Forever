-- luacheck: read globals CombatText_LoadUI
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Combat text",
		NOTE = "Switch damage and healing numbers on or off",
		DESC = "Chooses which combat text the game shows. Switch the whole module quickly with `/qol toggle CombatText`.",
		NOTICE = "Changes the game settings `floatingCombatTextCombatDamage_v2`, `floatingCombatTextCombatHealing_v2` and `enableFloatingCombatText`. Disabling restores your previous settings.",
		SECTION_TARGET = "Numbers on your target",
		DAMAGE = "Damage",
		DAMAGE_DESC = "Damage you deal, shown above the target.",
		HEALING = "Healing",
		HEALING_DESC = "Healing you do, shown above the target.",
		SECTION_SELF = "Your character",
		SCROLLING = "Scrolling combat text",
		SCROLLING_DESC = "Damage taken, heals received, procs and similar events scrolling above your character.",
	},
	deDE = {
		TITLE = "Kampftext",
		NOTE = "Schadens- und Heilzahlen ein- oder ausschalten",
		DESC = "Legt fest, welcher Kampftext im Spiel angezeigt wird. Das ganze Modul lässt sich schnell mit `/qol toggle CombatText` umschalten.",
		NOTICE = "Ändert die Spieleinstellungen `floatingCombatTextCombatDamage_v2`, `floatingCombatTextCombatHealing_v2` und `enableFloatingCombatText`. Beim Deaktivieren werden deine vorherigen Einstellungen wiederhergestellt.",
		SECTION_TARGET = "Zahlen am Ziel",
		DAMAGE = "Schaden",
		DAMAGE_DESC = "Von dir verursachter Schaden, über dem Ziel angezeigt.",
		HEALING = "Heilung",
		HEALING_DESC = "Von dir gewirkte Heilung, über dem Ziel angezeigt.",
		SECTION_SELF = "Dein Charakter",
		SCROLLING = "Scrollender Kampftext",
		SCROLLING_DESC = "Erlittener Schaden, erhaltene Heilung, Procs und Ähnliches, die über deinem Charakter aufsteigen.",
	},
})

local module = ns:NewModule("CombatText", {
	title = L.TITLE,
	description = L.DESC,
	note = L.NOTE,
	notice = L.NOTICE,
	category = "INTERFACE",
	defaults = {
		damage = false,
		healing = false,
		scrolling = false,
	},
	options = {
		{ type = "header", label = L.SECTION_TARGET },
		{ key = "damage", type = "checkbox", label = L.DAMAGE, tooltip = L.DAMAGE_DESC },
		{ key = "healing", type = "checkbox", label = L.HEALING, tooltip = L.HEALING_DESC },
		{ type = "header", label = L.SECTION_SELF },
		{ key = "scrolling", type = "checkbox", label = L.SCROLLING, tooltip = L.SCROLLING_DESC },
	},
})

local CVARS = {
	damage = "floatingCombatTextCombatDamage_v2",
	healing = "floatingCombatTextCombatHealing_v2",
	scrolling = "enableFloatingCombatText",
}

function module:Apply()
	for key, cvar in pairs(CVARS) do
		self:SetCVar(cvar, self.db[key])
	end
	-- Blizzard_CombatText is load-on-demand and only loaded once the game
	-- option is turned on through the settings panel.
	if self.db.scrolling and CombatText_LoadUI then
		CombatText_LoadUI()
	end
end

function module:OnEnable()
	self:Apply()
end

function module:OnOptionChanged()
	self:Apply()
end
