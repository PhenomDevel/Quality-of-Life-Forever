-- luacheck: read globals AcceptResurrect C_SummonInfo IsEncounterInProgress UnitAffectingCombat
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Auto-accept summons & resurrections",
		DESC = "Automatically accepts summons and resurrections while you are out of combat and no boss encounter is in progress.",
		SUMMONS = "Summons",
		SUMMONS_DESC = "Accept summons (e.g. warlock summoning, meeting stones).",
		RESURRECTIONS = "Resurrections",
		RESURRECTIONS_DESC = "Accept resurrection spells from other players.",
		NOTIFY = "Notify in chat",
		NOTIFY_DESC = "Print a message when something was accepted.",
		ACCEPTED_SUMMON = "Accepted summon from %s to %s.",
		ACCEPTED_RESURRECT = "Accepted resurrection from %s.",
	},
	deDE = {
		TITLE = "Beschwörung & Wiederbelebung automatisch annehmen",
		DESC = "Nimmt Beschwörungen und Wiederbelebungen automatisch an, solange du nicht im Kampf bist und kein Bosskampf läuft.",
		SUMMONS = "Beschwörungen",
		SUMMONS_DESC = "Beschwörungen annehmen (z. B. Hexenmeister, Versammlungssteine).",
		RESURRECTIONS = "Wiederbelebungen",
		RESURRECTIONS_DESC = "Wiederbelebungszauber anderer Spieler annehmen.",
		NOTIFY = "Im Chat benachrichtigen",
		NOTIFY_DESC = "Gibt eine Nachricht aus, wenn etwas angenommen wurde.",
		ACCEPTED_SUMMON = "Beschwörung von %s nach %s angenommen.",
		ACCEPTED_RESURRECT = "Wiederbelebung von %s angenommen.",
	},
})

local module = ns:NewModule("AutoAcceptSummonResurrect", {
	title = L.TITLE,
	description = L.DESC,
	category = "SOCIAL",
	defaults = {
		summons = true,
		resurrections = true,
		notify = true,
	},
	options = {
		{ key = "summons", type = "checkbox", label = L.SUMMONS, tooltip = L.SUMMONS_DESC },
		{ key = "resurrections", type = "checkbox", label = L.RESURRECTIONS, tooltip = L.RESURRECTIONS_DESC },
		{ key = "notify", type = "checkbox", label = L.NOTIFY, tooltip = L.NOTIFY_DESC },
	},
})

local function InCombat()
	return UnitAffectingCombat("player") or (IsEncounterInProgress and IsEncounterInProgress())
end

function module:OnEnable()
	self:RegisterEvent("CONFIRM_SUMMON")
	self:RegisterEvent("RESURRECT_REQUEST")
end

function module:CONFIRM_SUMMON()
	if not self.db.summons or InCombat() then
		return
	end
	local summoner = C_SummonInfo.GetSummonConfirmSummoner()
	local area = C_SummonInfo.GetSummonConfirmAreaName()
	C_SummonInfo.ConfirmSummon()
	StaticPopup_Hide("CONFIRM_SUMMON")
	if self.db.notify then
		self:Print(L.ACCEPTED_SUMMON:format(tostring(summoner), tostring(area)))
	end
end

function module:RESURRECT_REQUEST(inviter)
	if not self.db.resurrections or InCombat() then
		return
	end
	AcceptResurrect()
	-- Blizzard picks one of these depending on resurrection sickness/timer.
	StaticPopup_Hide("RESURRECT")
	StaticPopup_Hide("RESURRECT_NO_SICKNESS")
	StaticPopup_Hide("RESURRECT_NO_TIMER")
	if self.db.notify then
		self:Print(L.ACCEPTED_RESURRECT:format(tostring(inviter)))
	end
end
