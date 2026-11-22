local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Profession cooldowns",
		NOTE = "Tells you at login which cooldowns are ready",
		DESC = "Once after logging in, a popup lists the profession cooldowns of this character that are ready, e.g. Mooncloth, transmutes or the Salt Shaker. Only recipes your character knows (and the Salt Shaker while you have it) count; nothing is shown when none is ready. Recipes the addon doesn't know yet are picked up from the profession window after their first craft.",
		READY = "Profession cooldowns ready:",
	},
	deDE = {
		TITLE = "Berufs-Cooldowns",
		NOTE = "Meldet beim Einloggen bereite Cooldowns",
		DESC = "Einmal nach dem Einloggen listet ein Popup die Berufs-Cooldowns dieses Charakters, die bereit sind, z. B. Mondstoff, Transmutationen oder den Salzstreuer. Es zählen nur Rezepte, die dein Charakter kennt (und der Salzstreuer, solange du ihn hast); ist keiner bereit, kommt nichts. Rezepte, die das Addon noch nicht kennt, werden nach dem ersten Herstellen aus dem Berufsfenster übernommen.",
		READY = "Berufs-Cooldowns bereit:",
	},
})

local module = ns:NewModule("ProfessionCooldownReminder", {
	title = L.TITLE,
	description = L.DESC,
	note = L.NOTE,
	category = "REMINDERS",
	order = 60,
	defaults = {},
	options = {},
})

local ProfessionCooldowns = ns.ProfessionCooldowns

local function WithIcon(icon, text)
	return icon and ("|T%s:0|t %s"):format(icon, text) or text
end

function module:OnScan(initial)
	if not initial then
		return
	end
	local lines, firstIcon = { L.READY }, nil
	for _, cooldown in ipairs(ProfessionCooldowns.GetCooldowns(ProfessionCooldowns.GetCurrentCharacter())) do
		if cooldown.readyAt == 0 then
			firstIcon = firstIcon or cooldown.icon
			lines[#lines + 1] = WithIcon(cooldown.icon, cooldown.name)
		end
	end
	if #lines > 1 then
		self:Notice(table.concat(lines, "\n"), firstIcon)
	end
end

function module:OnEnable()
	ProfessionCooldowns.Acquire(self, self.OnScan)
end

function module:OnDisable()
	ProfessionCooldowns.Release(self)
end
