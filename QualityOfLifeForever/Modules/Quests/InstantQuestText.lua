local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Instant quest text",
		DESC = "Shows quest text at once instead of fading it in (CVar questFadingDisable). Disabling restores your previous setting.",
		UNSUPPORTED = "Instant quest text is not supported by this client (CVar questFadingDisable missing).",
	},
	deDE = {
		TITLE = "Questtext sofort anzeigen",
		DESC = "Zeigt Questtexte sofort statt sie einzublenden (CVar questFadingDisable). Beim Deaktivieren wird die vorherige Einstellung wiederhergestellt.",
		UNSUPPORTED = "Sofortiger Questtext wird von diesem Client nicht unterstützt (CVar questFadingDisable fehlt).",
	},
})

local module = ns:NewModule("InstantQuestText", {
	title = L.TITLE,
	description = L.DESC,
	category = "QUESTS",
})

function module:OnEnable()
	if not self:SetCVar("questFadingDisable", true) then
		ns:Print(L.UNSUPPORTED)
	end
end
