local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Class colors in chat",
		DESC = "Colors player names in chat by class.",
		NOTICE = "Changes the game setting `chatClassColorOverride`. Disabling restores your previous setting.",
	},
	deDE = {
		TITLE = "Klassenfarben im Chat",
		DESC = "Färbt Spielernamen im Chat in ihrer Klassenfarbe.",
		NOTICE = "Ändert die Spieleinstellung `chatClassColorOverride`. Beim Deaktivieren wird deine vorherige Einstellung wiederhergestellt.",
	},
})

local module = ns:NewModule("ChatClassColors", {
	title = L.TITLE,
	description = L.DESC,
	notice = L.NOTICE,
	category = "CHAT",
	order = 20,
})

function module:OnEnable()
	self:SetCVar("chatClassColorOverride", 0)
end
