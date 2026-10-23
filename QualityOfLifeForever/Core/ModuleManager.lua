local _, ns = ...

local L = ns.L
local Utils = ns.Utils

--------------------------------------------------------------------------------
-- Categories
--------------------------------------------------------------------------------
-- Every module belongs to exactly one category. The pages in the options
-- window are sorted by localized name. Empty categories are not shown.

ns.categories = {
	{ id = "QUESTS", name = L.CATEGORY_QUESTS },
	{ id = "LOOT", name = L.CATEGORY_LOOT },
	{ id = "MERCHANT", name = L.CATEGORY_MERCHANT },
	{ id = "BAGS", name = L.CATEGORY_BAGS },
	{ id = "WIDGETS", name = L.CATEGORY_WIDGETS },
	{ id = "TOOLTIP", name = L.CATEGORY_TOOLTIP },
	{ id = "CHAT", name = L.CATEGORY_CHAT },
	{ id = "MAP", name = L.CATEGORY_MAP },
	{ id = "REMINDERS", name = L.CATEGORY_REMINDERS },
	{ id = "ACTION_BARS", name = L.CATEGORY_ACTION_BARS },
	{ id = "COOLDOWN_MANAGER", name = L.CATEGORY_COOLDOWN_MANAGER },
	{ id = "CHARACTER", name = L.CATEGORY_CHARACTER },
	{ id = "SOCIAL", name = L.CATEGORY_SOCIAL },
	{ id = "GRAPHICS", name = L.CATEGORY_GRAPHICS },
	{ id = "INTERFACE", name = L.CATEGORY_INTERFACE },
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

-- Popup out of combat (see Core/Notices.lua); key defaults to the module, so
-- a newer notice of the same module replaces an older one.
function Module:Notice(text, icon, key)
	ns:ShowNotice({ key = key or self.name, title = self.title, text = text, icon = icon })
end

function Module:Debug(...)
	ns:Debug(("[%s]"):format(self.name), ...)
end

function Module:GetOption(key)
	return self.db[key]
end

-- Changes an option and notifies the module. Prefer this over writing to
-- self.db directly so the options window and OnOptionChanged stay in sync.
function Module:SetOption(key, value)
	self.db[key] = value
	ns:NotifyOptionChanged(self, key, value)
	ns:RefreshOptionValues()
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
-- Secure hooks, script hooks, tooltip post-calls and Edit Mode callbacks cannot
-- be removed again, so the wrappers check whether the module is enabled and
-- mark it as `hooked`: disabling it then offers a reload to drop them for good.
-- Hooking the same target twice only replaces the callback.

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
	self.hooked = true
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
	self.hooked = true
	frame:HookScript(script, function(...)
		if self.enabled then
			hook.handler(self, ...)
		end
	end)
end

-- handler(module, tooltip, data); call once per data type (e.g. in OnInitialize).
function Module:AddTooltipPostCall(dataType, handler)
	self.hooked = true
	TooltipDataProcessor.AddTooltipPostCall(dataType, function(...)
		if self.enabled then
			handler(self, ...)
		end
	end)
end

-- LibEditMode "enter"/"exit"/"layout" callbacks; handler(module, ...).
function Module:RegisterEditModeCallback(event, handler)
	self.editModeCallbacks = self.editModeCallbacks or {}
	local existing = self.editModeCallbacks[event]
	if existing then
		existing.handler = handler
		return
	end

	local callback = { handler = handler }
	self.editModeCallbacks[event] = callback
	self.hooked = true
	ns.LibEditMode:RegisterCallback(event, function(...)
		if self.enabled then
			callback.handler(self, ...)
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
		title           = string, shown in the options window (localized)
		description     = string, tooltip of the module title (localized)
		note            = optional short gray line shown below the title (localized)
		notice          = optional hint the user should not miss, e.g. which game
		                  settings the module changes (localized); always shown
		status          = optional function(module) returning a hint while the module
		                  still lacks something to work (e.g. data it records), else nil
		category        = one of the ids in ns.categories (default "INTERFACE")
		order           = number, position within the category; lower comes first,
		                  equal values are sorted by title (default 0)
		defaultEnabled  = boolean (default false)
		defaults        = table of option defaults, stored in module.db
		options         = list of option descriptors for the options window
		                  { key, type = "checkbox" | "slider" | "dropdown", label, tooltip,
		                    min, max, step, format (slider), values (dropdown) }
		                  { key, type = "text", label, tooltip, multiline, placeholder, maxLetters }
		                  { type = "button", label, buttonText, tooltip, onClick(module) }
		                  { type = "header", label } (section title, no value)
		                  Every option may have a `note` (gray line below it).
		combatProtected = boolean, enable/disable is deferred until out of combat
		requiresReload  = boolean, ask for a /reload after disabling
	}

	Callbacks a module may implement:
		OnInitialize()          once, right before the module is enabled for the
		                        first time (never for modules that stay disabled)
		OnEnable()              every time the module gets enabled (also on login)
		OnDisable()             every time the module gets disabled (events are
		                        unregistered and CVars restored afterwards)
		OnOptionChanged(key, value)
		OnOptionsShown(shown)   the options window opened (true) or closed (false)
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
		notice = info.notice,
		status = info.status,
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

-- Deferred until the first enable, so a disabled module creates no frames,
-- hooks or callbacks at all.
local function Initialize(module)
	if module.initialized then
		return
	end
	module.initialized = true
	if module.OnInitialize then
		Utils.SafeCall(module.OnInitialize, module)
	end
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
	if module.db.enabled then
		Initialize(module)
	end
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
		elseif wasEnabled and module.hooked then
			ns:RequestReload(module, L.RELOAD_TO_UNLOAD)
		end
	end
end

ns:RegisterEvent("PLAYER_REGEN_ENABLED", function()
	for module in pairs(pendingCombat) do
		ns:ApplyModuleState(module)
	end
end)

-- Single entry point for turning a module on or off (options window, slash
-- commands, ...). Rebuilds the options window, whose layout depends on it.
function ns:SetModuleEnabled(module, enabled)
	module.db.enabled = not not enabled
	ns:ApplyModuleState(module)
	ns:RefreshOptions()
end

function ns:NotifyOptionChanged(module, key, value)
	ns:Debug(("[%s]"):format(module.name), key, "=", tostring(value))
	if module.enabled and module.OnOptionChanged then
		Utils.SafeCall(module.OnOptionChanged, module, key, value)
	end
	-- Shared overlay option, see ns:TitleOption().
	if key == "showTitle" then
		ns:UpdateOverlayTitles()
	end
end

function ns:InitializeModules()
	for _, module in ipairs(ns.moduleOrder) do
		module.db = ns:GetModuleDB(module)
	end
end

function ns:EnableModules()
	for _, module in ipairs(ns.moduleOrder) do
		ns:ApplyModuleState(module)
	end
end

function ns:RequestReload(module, text)
	if not StaticPopupDialogs or not StaticPopup_Show then
		return
	end
	StaticPopupDialogs.QOLFOREVER_RELOAD = StaticPopupDialogs.QOLFOREVER_RELOAD or {
		button1 = ACCEPT,
		button2 = CANCEL,
		OnAccept = function()
			ReloadUI()
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
	}
	StaticPopupDialogs.QOLFOREVER_RELOAD.text = text or L.RELOAD_REQUIRED
	StaticPopup_Show("QOLFOREVER_RELOAD", module.title)
end
