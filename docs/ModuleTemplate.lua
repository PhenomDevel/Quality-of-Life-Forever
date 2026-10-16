-- luacheck: read globals SomeBlizzardApi
--[[
	Template for a new module. Copy to
	QualityOfLifeForever/Modules/<Category>/<ModuleName>.lua and add it to the
	category section in QualityOfLifeForever.toc. See docs/MODULES.md.
]]

local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "My module",
		DESC = "What the module does.",
		SOME_TOGGLE = "Some toggle",
		SOME_TOGGLE_DESC = "What the toggle does.",
		SOME_AMOUNT = "Some amount",
		SOME_MODE = "Some mode",
		MODE_FAST = "Fast",
		MODE_SLOW = "Slow",
		APPLY = "Apply",
	},
	deDE = {
		TITLE = "Mein Modul",
		DESC = "Was das Modul macht.",
		SOME_TOGGLE = "Ein Schalter",
		SOME_TOGGLE_DESC = "Was der Schalter macht.",
		SOME_AMOUNT = "Eine Menge",
		SOME_MODE = "Ein Modus",
		MODE_FAST = "Schnell",
		MODE_SLOW = "Langsam",
		APPLY = "Anwenden",
	},
})

local module = ns:NewModule("MyModule", {
	title = L.TITLE,
	description = L.DESC,
	category = "INTERFACE",
	defaultEnabled = false,
	defaults = {
		someToggle = true,
		someAmount = 5,
		someMode = "fast",
	},
	options = {
		{ key = "someToggle", type = "checkbox", label = L.SOME_TOGGLE, tooltip = L.SOME_TOGGLE_DESC },
		{ key = "someAmount", type = "slider", label = L.SOME_AMOUNT, min = 1, max = 10, step = 1 },
		{
			key = "someMode",
			type = "dropdown",
			label = L.SOME_MODE,
			values = {
				{ value = "fast", label = L.MODE_FAST },
				{ value = "slow", label = L.MODE_SLOW },
			},
		},
		{
			type = "button",
			label = L.APPLY,
			buttonText = L.APPLY,
			onClick = function(self)
				self:SetCVar("someCVar", self.db.someAmount)
			end,
		},
	},
})

function module:OnEnable()
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	-- self:SecureHook("SomeBlizzardFunction", self.OnSomeBlizzardFunction)
end

-- Events are unregistered and CVars restored automatically after this.
function module:OnDisable()
end

function module:OnOptionChanged(key, value)
	self:Debug("option changed", key, value)
end

function module:PLAYER_ENTERING_WORLD(isInitialLogin)
	if self.db.someToggle and isInitialLogin then
		SomeBlizzardApi()
	end
end
