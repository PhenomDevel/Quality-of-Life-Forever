local _, ns = ...

local L = ns.L
local Utils = ns.Utils

--------------------------------------------------------------------------------
-- Categories
--------------------------------------------------------------------------------
-- Every module belongs to exactly one category. The sub pages in the settings
-- panel are sorted by localized name. Empty categories are not shown.

ns.categories = {
	{ id = "INTERFACE", name = L.CATEGORY_INTERFACE },
	{ id = "COOLDOWN_MANAGER", name = L.CATEGORY_COOLDOWN_MANAGER },
	{ id = "CHARACTER", name = L.CATEGORY_CHARACTER },
	{ id = "TOOLTIP", name = L.CATEGORY_TOOLTIP },
	{ id = "GRAPHICS", name = L.CATEGORY_GRAPHICS },
	{ id = "MERCHANT", name = L.CATEGORY_MERCHANT },
	{ id = "LOOT", name = L.CATEGORY_LOOT },
	{ id = "QUESTS", name = L.CATEGORY_QUESTS },
	{ id = "SOCIAL", name = L.CATEGORY_SOCIAL },
	{ id = "CHAT", name = L.CATEGORY_CHAT },
	{ id = "MAP", name = L.CATEGORY_MAP },
	{ id = "XP_BAR", name = L.CATEGORY_XP_BAR },
}

table.sort(ns.categories, function(a, b)
	return a.name:lower() < b.name:lower()
end)

local categoryById = {}
for _, category in ipairs(ns.categories) do
	categoryById[category.id] = category
end

--------------------------------------------------------------------------------
-- Module prototype
--------------------------------------------------------------------------------

local Module = {}
Module.__index = Module
ns.ModulePrototype = Module

function Module:IsEnabled()
	return self.enabled
end

function Module:Print(...)
	ns:Notify(...)
end

function Module:Debug(...)
	ns:Debug(("[%s]"):format(self.name), ...)
end

function Module:GetOption(key)
	return self.db[key]
end

-- Changes an option and notifies the module. Prefer this over writing to
-- self.db directly so the settings panel and OnOptionChanged stay in sync.
function Module:SetOption(key, value)
	local setting = self.settings and self.settings[key]
	if setting then
		-- The setting writes into self.db and calls back into OnOptionChanged.
		setting:SetValue(value)
		return
	end
	self.db[key] = value
	ns:NotifyOptionChanged(self, key, value)
end

-- Events ----------------------------------------------------------------------
-- Handlers are either a function or a method name. Without a handler the
-- method with the same name as the event is called: module:MERCHANT_SHOW(...).

function Module:RegisterEvent(event, handler)
	if not self.eventFrame then
		self.eventFrame = CreateFrame("Frame")
		self.eventHandlers = {}
		self.eventFrame:SetScript("OnEvent", function(_, firedEvent, ...)
			local callback = self.eventHandlers[firedEvent]
			if type(callback) == "string" then
				callback = self[callback]
			end
			if callback then
				callback(self, ...)
			end
		end)
	end
	self.eventHandlers[event] = handler or event
	self.eventFrame:RegisterEvent(event)
end

function Module:UnregisterEvent(event)
	if self.eventFrame then
		self.eventFrame:UnregisterEvent(event)
		self.eventHandlers[event] = nil
	end
end

function Module:UnregisterAllEvents()
	if self.eventFrame then
		self.eventFrame:UnregisterAllEvents()
		wipe(self.eventHandlers)
	end
end

-- CVars -----------------------------------------------------------------------
-- The first value seen per CVar is persisted in the module DB and restored on
-- disable, so the user's own setting survives reloads while the module is on.

function Module:SetCVar(name, value)
	local current = C_CVar.GetCVar(name)
	if current == nil then
		self:Debug("unknown CVar", name)
		return false
	end
	local backup = self.db.cvarBackup
	if not backup then
		backup = {}
		self.db.cvarBackup = backup
	end
	if backup[name] == nil then
		backup[name] = current
	end
	if type(value) == "boolean" then
		value = value and "1" or "0"
	end
	C_CVar.SetCVar(name, tostring(value))
	return true
end

function Module:RestoreCVars()
	local backup = self.db.cvarBackup
	if not backup then
		return
	end
	for name, value in pairs(backup) do
		C_CVar.SetCVar(name, value)
	end
	self.db.cvarBackup = nil
end

-- Hooks -----------------------------------------------------------------------
-- Secure hooks cannot be removed again, so the wrapper checks whether the module
-- is enabled. Hooking the same target twice only replaces the callback.

function Module:SecureHook(target, method, handler)
	if type(target) == "string" then
		target, method, handler = nil, target, method
	end
	self.hooks = self.hooks or {}
	local key = tostring(target or _G) .. "." .. method
	local existing = self.hooks[key]
	if existing then
		existing.handler = handler
		return
	end

	local hook = { handler = handler }
	self.hooks[key] = hook
	local wrapper = function(...)
		if self.enabled then
			hook.handler(self, ...)
		end
	end
	if target then
		hooksecurefunc(target, method, wrapper)
	else
		hooksecurefunc(method, wrapper)
	end
end

function Module:HookScript(frame, script, handler)
	self.hooks = self.hooks or {}
	local key = tostring(frame) .. ":" .. script
	local existing = self.hooks[key]
	if existing then
		existing.handler = handler
		return
	end

	local hook = { handler = handler }
	self.hooks[key] = hook
	frame:HookScript(script, function(...)
		if self.enabled then
			hook.handler(self, ...)
		end
	end)
end

--------------------------------------------------------------------------------
-- Registry
--------------------------------------------------------------------------------

ns.modules = {}
ns.moduleOrder = {}

--[[
	Creates and registers a new module.

	info = {
		title           = string, shown in the settings panel (localized)
		description     = string, tooltip of the enable checkbox (localized)
		note            = optional short gray line shown below the title (localized)
		category        = one of the ids in ns.categories (default "INTERFACE")
		order           = number, position within the category; lower comes first,
		                  equal values are sorted by title (default 0)
		defaultEnabled  = boolean (default false)
		defaults        = table of option defaults, stored in module.db
		options         = list of option descriptors for the settings panel
		                  { key, type = "checkbox" | "slider" | "dropdown", label, tooltip,
		                    min, max, step, format (slider), values (dropdown) }
		                  { type = "button", label, buttonText, tooltip, onClick(module) }
		                  { type = "header", label } (section title, no value)
		                  Every option may have a `note` (gray line below it).
		combatProtected = boolean, enable/disable is deferred until out of combat
		requiresReload  = boolean, ask for a /reload after disabling
	}

	Callbacks a module may implement:
		OnInitialize()          once, after the saved variables are loaded
		OnEnable()              every time the module gets enabled (also on login)
		OnDisable()             every time the module gets disabled (events are
		                        unregistered and CVars restored afterwards)
		OnOptionChanged(key, value)
]]
function ns:NewModule(name, info)
	assert(type(name) == "string" and name ~= "", "Module name must be a non-empty string")
	assert(not ns.modules[name], ("Module %q is already registered"):format(name))
	info = info or {}

	local category = info.category or "INTERFACE"
	assert(categoryById[category], ("Module %q has unknown category %q"):format(name, tostring(category)))

	local module = setmetatable({
		name = name,
		title = info.title or name,
		description = info.description or "",
		note = info.note,
		category = category,
		order = info.order or 0,
		defaultEnabled = info.defaultEnabled == true,
		defaults = info.defaults or {},
		options = info.options or {},
		combatProtected = info.combatProtected == true,
		requiresReload = info.requiresReload == true,
		enabled = false,
	}, Module)

	ns.modules[name] = module
	ns.moduleOrder[#ns.moduleOrder + 1] = module
	return module
end

function ns:GetModule(name)
	return ns.modules[name]
end

-- Case insensitive lookup for slash commands.
function ns:FindModule(name)
	if not name then
		return nil
	end
	name = name:lower()
	for _, module in ipairs(ns.moduleOrder) do
		if module.name:lower() == name then
			return module
		end
	end
	return nil
end

function ns:IterateModules()
	return ipairs(ns.moduleOrder)
end

local function CompareTitles(a, b)
	return a.title:lower() < b.title:lower()
end

local function CompareOrder(a, b)
	if a.order ~= b.order then
		return a.order < b.order
	end
	return CompareTitles(a, b)
end

-- Modules sorted for display: within a category by `order`, then by
-- localized title; across all categories by title only.
function ns:GetSortedModules(category)
	local modules = {}
	for _, module in ipairs(ns.moduleOrder) do
		if not category or module.category == category then
			modules[#modules + 1] = module
		end
	end
	table.sort(modules, category and CompareOrder or CompareTitles)
	return modules
end

--------------------------------------------------------------------------------
-- Lifecycle
--------------------------------------------------------------------------------

local pendingCombat = {}

local function CanChangeState(module)
	return not module.combatProtected or not InCombatLockdown()
end

local function Enable(module)
	if module.enabled then
		return
	end
	module.enabled = true
	ns:Debug("Enabling", module.name)
	if module.OnEnable then
		Utils.SafeCall(module.OnEnable, module)
	end
end

local function Disable(module)
	if not module.enabled then
		return
	end
	module.enabled = false
	ns:Debug("Disabling", module.name)
	module:UnregisterAllEvents()
	if module.OnDisable then
		Utils.SafeCall(module.OnDisable, module)
	end
	Utils.SafeCall(module.RestoreCVars, module)
end

-- Brings the runtime state of a module in line with its saved `enabled` flag.
function ns:ApplyModuleState(module)
	if not CanChangeState(module) then
		if not pendingCombat[module] then
			pendingCombat[module] = true
			ns:Print(L.COMBAT_QUEUED:format(module.title))
		end
		return
	end
	pendingCombat[module] = nil

	local wasEnabled = module.enabled
	if module.db.enabled then
		Enable(module)
	else
		Disable(module)
		if wasEnabled and module.requiresReload then
			ns:RequestReload(module)
		end
	end
end

ns:RegisterEvent("PLAYER_REGEN_ENABLED", function()
	for module in pairs(pendingCombat) do
		ns:ApplyModuleState(module)
	end
end)

-- Single entry point for turning a module on or off (settings panel, slash
-- commands, ...). Keeps the settings panel checkbox in sync.
function ns:SetModuleEnabled(module, enabled)
	enabled = not not enabled
	local setting = module.settings and module.settings.enabled
	if setting and setting:GetValue() ~= enabled then
		-- Writes module.db.enabled and calls back into ApplyModuleState.
		setting:SetValue(enabled)
	else
		module.db.enabled = enabled
		ns:ApplyModuleState(module)
	end
end

function ns:NotifyOptionChanged(module, key, value)
	ns:Debug(("[%s]"):format(module.name), key, "=", tostring(value))
	if module.enabled and module.OnOptionChanged then
		Utils.SafeCall(module.OnOptionChanged, module, key, value)
	end
end

function ns:InitializeModules()
	for _, module in ipairs(ns.moduleOrder) do
		module.db = ns:GetModuleDB(module)
		if module.OnInitialize then
			Utils.SafeCall(module.OnInitialize, module)
		end
	end
end

function ns:EnableModules()
	for _, module in ipairs(ns.moduleOrder) do
		ns:ApplyModuleState(module)
	end
end

function ns:RequestReload(module)
	if not StaticPopupDialogs or not StaticPopup_Show then
		return
	end
	StaticPopupDialogs.QOLFOREVER_RELOAD = StaticPopupDialogs.QOLFOREVER_RELOAD or {
		text = L.RELOAD_REQUIRED,
		button1 = ACCEPT,
		button2 = CANCEL,
		OnAccept = function()
			ReloadUI()
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
	}
	StaticPopup_Show("QOLFOREVER_RELOAD", module.title)
end
