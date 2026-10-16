--[[
	Minimal mock of the WoW client API, just enough to load the addon outside
	the game and exercise the core framework and modules.

	Every call to WoWMock.Boot() creates a fresh, isolated global environment,
	loads all files listed in the .toc and returns a handle to drive it.
]]

local WoWMock = {}

local ADDON_NAME = "QualityOfLifeForever"

local function ReadTocFiles(addonDir)
	local tocPath = addonDir .. "/" .. ADDON_NAME .. ".toc"
	local handle = assert(io.open(tocPath, "r"), "Cannot open " .. tocPath)
	local files = {}
	for line in handle:lines() do
		line = line:gsub("\r", ""):match("^%s*(.-)%s*$")
		if line ~= "" and not line:match("^#") then
			files[#files + 1] = line:gsub("\\", "/")
		end
	end
	handle:close()
	return files
end

local function CreateEnvironment(state)
	local env = setmetatable({}, { __index = _G })
	env._G = env

	-- Frames & events ----------------------------------------------------------
	local frames = {}

	local Frame = {}
	Frame.__index = Frame
	function Frame:RegisterEvent(event)
		self.events[event] = true
	end
	function Frame:UnregisterEvent(event)
		self.events[event] = nil
	end
	function Frame:UnregisterAllEvents()
		self.events = {}
	end
	function Frame:IsEventRegistered(event)
		return self.events[event] == true
	end
	function Frame:SetScript(script, handler)
		self.scripts[script] = handler
	end
	function Frame:HookScript(script, handler)
		local previous = self.scripts[script]
		self.scripts[script] = function(...)
			if previous then
				previous(...)
			end
			handler(...)
		end
	end

	env.CreateFrame = function()
		local frame = setmetatable({ events = {}, scripts = {} }, Frame)
		frames[#frames + 1] = frame
		return frame
	end

	state.FireEvent = function(event, ...)
		for _, frame in ipairs(frames) do
			if frame.events[event] and frame.scripts.OnEvent then
				-- Like the client: an error in one frame's handler is reported
				-- and does not stop the event from reaching other frames.
				local ok, err = pcall(frame.scripts.OnEvent, frame, event, ...)
				if not ok then
					state.errors[#state.errors + 1] = err
				end
			end
		end
	end

	state.CountEventListeners = function(event)
		local count = 0
		for _, frame in ipairs(frames) do
			if frame.events[event] then
				count = count + 1
			end
		end
		return count
	end

	-- General ------------------------------------------------------------------
	state.messages = {}
	state.errors = {}
	state.popups = {}
	state.reloads = 0
	state.inCombat = false
	state.time = 0

	env.GetLocale = function()
		return state.locale or "enUS"
	end
	env.C_AddOns = {
		GetAddOnMetadata = function()
			return "@project-version@"
		end,
	}
	env.DEFAULT_CHAT_FRAME = {
		AddMessage = function(_, message)
			state.messages[#state.messages + 1] = message
		end,
	}
	env.geterrorhandler = function()
		return function(err)
			state.errors[#state.errors + 1] = err
			return err
		end
	end
	env.wipe = function(tbl)
		for key in pairs(tbl) do
			tbl[key] = nil
		end
		return tbl
	end
	env.hooksecurefunc = function(target, method, hook)
		if type(target) == "string" then
			target, method, hook = env, target, method
		end
		local original = target[method]
		target[method] = function(...)
			local result = { original(...) }
			hook(...)
			return unpack(result)
		end
	end
	env.InCombatLockdown = function()
		return state.inCombat
	end
	env.GetTime = function()
		return state.time
	end
	env.ReloadUI = function()
		state.reloads = state.reloads + 1
	end
	env.GetCVarBool = function(name)
		return state.cvars and state.cvars[name] or false
	end
	env.IsModifiedClick = function()
		return false
	end
	env.ACCEPT, env.CANCEL = "Accept", "Cancel"
	env.SlashCmdList = {}
	env.StaticPopupDialogs = {}
	env.StaticPopup_Show = function(name, ...)
		state.popups[#state.popups + 1] = { name = name, args = { ... } }
	end
	env.StaticPopup_Hide = function() end
	env.GameTooltip = setmetatable({}, {
		__index = function()
			return function() end
		end,
	})
	env.UIParent = {}

	-- Timers -------------------------------------------------------------------
	state.timers = {}
	env.C_Timer = {
		After = function(_, callback)
			state.timers[#state.timers + 1] = callback
		end,
		NewTicker = function(_, callback)
			local ticker = { cancelled = false }
			function ticker:Cancel()
				self.cancelled = true
			end
			ticker.callback = callback
			state.tickers = state.tickers or {}
			state.tickers[#state.tickers + 1] = ticker
			return ticker
		end,
	}
	-- Runs all pending C_Timer.After callbacks and ticks every live ticker once.
	state.RunTimers = function()
		local pending = state.timers
		state.timers = {}
		for _, callback in ipairs(pending) do
			callback()
		end
		for _, ticker in ipairs(state.tickers or {}) do
			if not ticker.cancelled then
				ticker.callback(ticker)
			end
		end
	end

	-- Bags, items & merchant (empty defaults, tests override them in setup) ----
	env.BACKPACK_CONTAINER = 0
	env.NUM_BAG_SLOTS = 4
	env.Enum = { ItemQuality = { Poor = 0, Common = 1 } }
	env.C_Container = {
		GetContainerNumSlots = function()
			return 0
		end,
		GetContainerItemInfo = function() end,
		UseContainerItem = function() end,
	}
	env.C_Item = {
		GetItemInfo = function() end,
	}
	env.CanMerchantRepair = function()
		return false
	end

	-- Money --------------------------------------------------------------------
	env.C_CurrencyInfo = {
		GetCoinTextureString = function(copper)
			return copper .. "c"
		end,
	}

	-- Settings -----------------------------------------------------------------
	state.settings = {}
	state.categories = {}

	local Setting = {}
	Setting.__index = Setting
	function Setting:GetValue()
		return self.tbl[self.key]
	end
	function Setting:SetValue(value)
		self.tbl[self.key] = value
		if self.callback then
			self.callback(self, value)
		end
	end
	function Setting:SetValueChangedCallback(callback)
		self.callback = callback
	end

	local Initializer = {}
	Initializer.__index = Initializer
	function Initializer:SetParentInitializer(parent, predicate)
		self.parent = parent
		self.predicate = predicate
	end

	local function NewCategory(name, parent)
		local category = { name = name, parent = parent, controls = {}, id = #state.categories + 1 }
		function category:GetID()
			return self.id
		end
		state.categories[#state.categories + 1] = category
		local layout = {
			AddInitializer = function(_, initializer)
				category.controls[#category.controls + 1] = initializer
			end,
		}
		return category, layout
	end

	local function NewControl(kind, category, setting, tooltip)
		local initializer = setmetatable({ kind = kind, setting = setting, tooltip = tooltip }, Initializer)
		category.controls[#category.controls + 1] = initializer
		return initializer
	end

	env.Settings = {
		RegisterVerticalLayoutCategory = function(name)
			return NewCategory(name)
		end,
		RegisterVerticalLayoutSubcategory = function(parent, name)
			return NewCategory(name, parent)
		end,
		RegisterAddOnCategory = function(category)
			state.registeredCategory = category
		end,
		RegisterAddOnSetting = function(_, variable, key, tbl, varType, name, default)
			assert(not state.settings[variable], "Duplicate setting variable " .. variable)
			assert(type(tbl[key]) == varType, ("Setting %s: saved value has type %s, expected %s")
				:format(variable, type(tbl[key]), varType))
			local setting = setmetatable({ variable = variable, key = key, tbl = tbl, name = name, default = default }, Setting)
			state.settings[variable] = setting
			return setting
		end,
		CreateCheckbox = function(category, setting, tooltip)
			return NewControl("checkbox", category, setting, tooltip)
		end,
		CreateSlider = function(category, setting, _, tooltip)
			return NewControl("slider", category, setting, tooltip)
		end,
		CreateDropdown = function(category, setting, _, tooltip)
			return NewControl("dropdown", category, setting, tooltip)
		end,
		CreateSliderOptions = function()
			return { SetLabelFormatter = function() end }
		end,
		OpenToCategory = function(id)
			state.openedCategory = id
		end,
	}
	env.CreateSettingsListSectionHeaderInitializer = function(text)
		return { kind = "header", text = text }
	end
	env.MinimalSliderWithSteppersMixin = { Label = { Right = 1 } }

	return env
end

function WoWMock.Boot(options)
	options = options or {}
	local state = { locale = options.locale, savedVariables = options.savedVariables }
	local env = CreateEnvironment(state)
	if options.setup then
		options.setup(env, state)
	end

	env.QualityOfLifeForeverDB = options.savedVariables

	local addonDir = options.addonDir or "QualityOfLifeForever"
	local ns = {}
	for _, file in ipairs(ReadTocFiles(addonDir)) do
		local chunk = assert(loadfile(addonDir .. "/" .. file))
		setfenv(chunk, env)
		chunk(ADDON_NAME, ns)
	end

	state.ns = ns
	state.env = env

	if options.login ~= false then
		state.FireEvent("ADDON_LOADED", ADDON_NAME)
		state.FireEvent("PLAYER_LOGIN")
	end
	return state
end

return WoWMock
