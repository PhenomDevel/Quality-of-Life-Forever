local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Class colors in chat",
		DESC = "Colors player names in chat by class (CVar chatClassColorOverride = 0). Disabling restores your previous setting.",
	},
	deDE = {
		TITLE = "Klassenfarben im Chat",
		DESC = "Färbt Spielernamen im Chat in ihrer Klassenfarbe (CVar chatClassColorOverride = 0). Beim Deaktivieren wird die vorherige Einstellung wiederhergestellt.",
	},
})

local module = ns:NewModule("ChatClassColors", {
	title = L.TITLE,
	description = L.DESC,
	category = "CHAT",
})

function module:OnEnable()
	self:SetCVar("chatClassColorOverride", 0)
end
