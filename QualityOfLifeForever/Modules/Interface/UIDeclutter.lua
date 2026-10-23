-- luacheck: read globals UIErrorsFrame ZoneTextFrame SubZoneTextFrame EventToastManagerFrame
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Declutter interface",
		NOTE = "Error messages, zone names, event banners",
		DESC = "Hides on-screen messages and frames you don't need. Every part can be switched on separately.",
		SECTION_MESSAGES = "Hide messages",
		ERRORS = "Red error messages",
		ERRORS_DESC = "Hides messages like \"Ability is not ready yet\" or \"Not enough mana\". Quest progress (yellow) stays.",
		ZONE_TEXT = "Zone names",
		ZONE_TEXT_DESC = "Hides the zone and subzone name in the middle of the screen when you enter an area.",
		TOASTS = "Event banners",
		TOASTS_DESC = "Hides the large banners such as \"Level up\".",
	},
	deDE = {
		TITLE = "Oberfläche aufräumen",
		NOTE = "Fehlermeldungen, Zonennamen, Ereignis-Banner",
		DESC = "Blendet Bildschirmmeldungen und Fenster aus, die du nicht brauchst. Jeder Teil lässt sich einzeln einschalten.",
		SECTION_MESSAGES = "Meldungen ausblenden",
		ERRORS = "Rote Fehlermeldungen",
		ERRORS_DESC = "Blendet Meldungen wie „Fähigkeit ist noch nicht bereit“ oder „Nicht genug Mana“ aus. Questfortschritt (gelb) bleibt.",
		ZONE_TEXT = "Zonennamen",
		ZONE_TEXT_DESC = "Blendet den Zonen- und Gebietsnamen in der Bildschirmmitte beim Betreten eines Gebiets aus.",
		TOASTS = "Ereignis-Banner",
		TOASTS_DESC = "Blendet die großen Banner wie „Stufe erreicht“ aus.",
	},
})

local module = ns:NewModule("UIDeclutter", {
	title = L.TITLE,
	description = L.DESC,
	note = L.NOTE,
	category = "INTERFACE",
	order = 20,
	defaults = {
		errors = true,
		zoneText = false,
		toasts = false,
	},
	options = {
		{ type = "header", label = L.SECTION_MESSAGES },
		{ key = "errors", type = "checkbox", label = L.ERRORS, tooltip = L.ERRORS_DESC },
		{ key = "zoneText", type = "checkbox", label = L.ZONE_TEXT, tooltip = L.ZONE_TEXT_DESC },
		{ key = "toasts", type = "checkbox", label = L.TOASTS, tooltip = L.TOASTS_DESC },
	},
})

-- Option key -> frames hidden whenever they show.
local HIDDEN_ON_SHOW = {
	zoneText = { "ZoneTextFrame", "SubZoneTextFrame" },
	toasts = { "EventToastManagerFrame" },
}

-- Red errors come in via UI_ERROR_MESSAGE; quest progress uses UI_INFO_MESSAGE.
function module:ApplyErrors()
	if not UIErrorsFrame then
		return
	end
	if self.enabled and self.db.errors then
		UIErrorsFrame:UnregisterEvent("UI_ERROR_MESSAGE")
	else
		UIErrorsFrame:RegisterEvent("UI_ERROR_MESSAGE")
	end
end

function module:OnEnable()
	self:ApplyErrors()
	for key, names in pairs(HIDDEN_ON_SHOW) do
		for _, name in ipairs(names) do
			local frame = _G[name]
			if frame then
				self:HookScript(frame, "OnShow", function()
					if self.db[key] then
						frame:Hide()
					end
				end)
			end
		end
	end
end

function module:OnDisable()
	if UIErrorsFrame then
		UIErrorsFrame:RegisterEvent("UI_ERROR_MESSAGE")
	end
end

function module:OnOptionChanged(key)
	if key == "errors" then
		self:ApplyErrors()
	end
end
