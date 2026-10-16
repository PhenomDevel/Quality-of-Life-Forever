local _, ns = ...

local L = ns.L

--[[
	Builds the options in the Blizzard settings panel (Options > AddOns).

	Layout:
		Quality of Life Forever       general settings (chat messages, debug)
		  ├─ Merchant                 one sub page per category that has modules
		  ├─ Loot
		  └─ ...

	Every module gets an enable checkbox. Its options are nested below it and are
	only editable while the module is enabled. The settings are bound directly to
	the saved variables, so no extra save step is needed.
]]

local VARIABLE_PREFIX = "QOLFOREVER_"

local function RegisterSetting(category, variable, key, tbl, name, defaultValue, onChange)
	local setting = Settings.RegisterAddOnSetting(
		category,
		VARIABLE_PREFIX .. variable,
		key,
		tbl,
		type(defaultValue),
		name,
		defaultValue
	)
	if onChange then
		setting:SetValueChangedCallback(function(_, value)
			onChange(value)
		end)
	end
	return setting
end

local function CreateOptionControl(category, module, option, parentInitializer)
	local defaultValue = module.defaults[option.key]
	local setting = RegisterSetting(
		category,
		module.name .. "_" .. option.key,
		option.key,
		module.db,
		option.label,
		defaultValue,
		function(value)
			ns:NotifyOptionChanged(module, option.key, value)
		end
	)
	module.settings[option.key] = setting

	local initializer
	if option.type == "checkbox" then
		initializer = Settings.CreateCheckbox(category, setting, option.tooltip)
	elseif option.type == "slider" then
		local sliderOptions = Settings.CreateSliderOptions(option.min, option.max, option.step or 1)
		sliderOptions:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, option.format)
		initializer = Settings.CreateSlider(category, setting, sliderOptions, option.tooltip)
	elseif option.type == "dropdown" then
		local function GetOptions()
			local container = Settings.CreateControlTextContainer()
			for _, entry in ipairs(option.values) do
				container:Add(entry.value, entry.label)
			end
			return container:GetData()
		end
		initializer = Settings.CreateDropdown(category, setting, GetOptions, option.tooltip)
	else
		error(("Module %q option %q has unknown type %q"):format(module.name, option.key, tostring(option.type)))
	end

	if parentInitializer then
		initializer:SetParentInitializer(parentInitializer, function()
			return module.db.enabled
		end)
	end
	return initializer
end

local function AddModule(category, module)
	module.settings = {}

	local enabledSetting = RegisterSetting(
		category,
		module.name .. "_enabled",
		"enabled",
		module.db,
		module.title,
		module.defaultEnabled,
		function()
			ns:ApplyModuleState(module)
		end
	)
	module.settings.enabled = enabledSetting
	local enabledInitializer = Settings.CreateCheckbox(category, enabledSetting, module.description)

	for _, option in ipairs(module.options) do
		CreateOptionControl(category, module, option, enabledInitializer)
	end
end

local function AddGeneralSettings(category, layout)
	layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(L.SETTINGS_GENERAL_HEADER))

	local printSetting = RegisterSetting(
		category, "printMessages", "printMessages", ns.db.global,
		L.SETTING_PRINT_MESSAGES, true
	)
	Settings.CreateCheckbox(category, printSetting, L.SETTING_PRINT_MESSAGES_DESC)

	local debugSetting = RegisterSetting(
		category, "debug", "debug", ns.db.global,
		L.SETTING_DEBUG, false
	)
	Settings.CreateCheckbox(category, debugSetting, L.SETTING_DEBUG_DESC)
	ns.debugSetting = debugSetting
end

function ns:BuildSettings()
	if not (Settings and Settings.RegisterVerticalLayoutCategory and Settings.RegisterAddOnSetting) then
		ns:Debug("Settings API not available")
		return false
	end

	local root, rootLayout = Settings.RegisterVerticalLayoutCategory(ns.title)
	AddGeneralSettings(root, rootLayout)

	for _, categoryInfo in ipairs(ns.categories) do
		local modules = {}
		for _, module in ns:IterateModules() do
			if module.category == categoryInfo.id then
				modules[#modules + 1] = module
			end
		end
		if #modules > 0 then
			local subcategory = Settings.RegisterVerticalLayoutSubcategory(root, categoryInfo.name)
			for _, module in ipairs(modules) do
				AddModule(subcategory, module)
			end
		end
	end

	Settings.RegisterAddOnCategory(root)
	ns.settingsCategory = root
	return true
end

function ns:OpenSettings()
	if ns.settingsCategory and Settings and Settings.OpenToCategory then
		Settings.OpenToCategory(ns.settingsCategory:GetID())
	else
		ns:Print(L.SETTINGS_UNAVAILABLE)
	end
end
