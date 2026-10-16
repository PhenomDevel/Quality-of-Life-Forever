--[[
	Template for a new module. Copy this file to
	QualityOfLifeForever/Modules/<Category>/<ModuleName>.lua, add it to
	QualityOfLifeForever.toc (above Core\Bootstrap.lua) and add the strings to
	Locales/enUS.lua and Locales/deDE.lua.

	See docs/MODULES.md for the full API.
]]

local _, ns = ...

local L = ns.L

local module = ns:NewModule("MyModule", {
	title = L.MY_MODULE_TITLE,
	description = L.MY_MODULE_DESC,
	category = "INTERFACE", -- see ns.categories in Core/ModuleManager.lua
	defaultEnabled = false,
	defaults = {
		someToggle = true,
		someAmount = 5,
		someMode = "fast",
	},
	options = {
		{
			key = "someToggle",
			type = "checkbox",
			label = L.MY_MODULE_SOME_TOGGLE,
			tooltip = L.MY_MODULE_SOME_TOGGLE_DESC,
		},
		{
			key = "someAmount",
			type = "slider",
			label = L.MY_MODULE_SOME_AMOUNT,
			tooltip = L.MY_MODULE_SOME_AMOUNT_DESC,
			min = 1,
			max = 10,
			step = 1,
		},
		{
			key = "someMode",
			type = "dropdown",
			label = L.MY_MODULE_SOME_MODE,
			tooltip = L.MY_MODULE_SOME_MODE_DESC,
			values = {
				{ value = "fast", label = L.MY_MODULE_MODE_FAST },
				{ value = "slow", label = L.MY_MODULE_MODE_SLOW },
			},
		},
	},
})

-- Optional: runs once after the saved variables are available.
function module:OnInitialize()
end

-- Runs whenever the module is switched on (also on login if it is enabled).
function module:OnEnable()
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	-- Secure hooks stay installed but only call back while the module is enabled.
	-- self:SecureHook("SomeBlizzardFunction", self.OnSomeBlizzardFunction)
end

-- Runs whenever the module is switched off. Events are unregistered
-- automatically; undo everything else you changed (frames, CVars, ...).
function module:OnDisable()
end

-- Called while the module is enabled and one of its options changed.
function module:OnOptionChanged(key, value)
	self:Debug("option changed", key, value)
end

function module:PLAYER_ENTERING_WORLD(isInitialLogin, isReloadingUi)
	if self.db.someToggle then
		self:Print("Hello", isInitialLogin, isReloadingUi)
	end
end
