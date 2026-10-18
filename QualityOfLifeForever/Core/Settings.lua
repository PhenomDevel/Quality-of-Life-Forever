local _, ns = ...

local L = ns.L

--[[
	Builds the options in the Blizzard settings panel (Options > AddOns).

	Layout:
		Quality of Life Forever       general settings (chat messages, debug)
		  ├─ Merchant                 one sub page per category that has modules
		  ├─ Loot
		  └─ ...

	Every module gets an enable checkbox, modules are separated by a thin line.
	Its options are nested below it and only shown while the module is enabled
	(Blizzard re-evaluates the shown predicates whenever a setting changes); a
	disabled module with options shows a hint instead. Group headers inside a
	module indent the options after them by one more level. The settings are
	bound directly to the saved variables, so no extra save step is needed.
]]

local VARIABLE_PREFIX = "QOLFOREVER_"

-- Optional gray note below a row ("note" on a module or option). Uses its own
-- template; Blizzard's rows have a fixed label width, so long explanations go
-- here instead of into the label.
local NOTE_TEMPLATE = "QualityOfLifeForeverSettingsNoteTemplate"
local SUBHEADER_TEMPLATE = "QualityOfLifeForeverSettingsSubheaderTemplate"
local DIVIDER_TEMPLATE = "QualityOfLifeForeverSettingsDividerTemplate"
local INDENT_SIZE = 15 -- Blizzard_SettingControls.lua indentSize

QualityOfLifeForeverSettingsNoteMixin = {}

function QualityOfLifeForeverSettingsNoteMixin:Init(initializer)
	local data = initializer:GetData()
	self.Text:ClearAllPoints()
	-- 37 = left offset of Blizzard's row labels.
	self.Text:SetPoint("LEFT", 37 + data.indent, 0)
	self.Text:SetPoint("RIGHT", -20, 0)
	self.Text:SetText(data.text)
end

QualityOfLifeForeverSettingsDividerMixin = {}

function QualityOfLifeForeverSettingsDividerMixin:Init()
end

-- level: 0, 1 or 2 indent steps (true = 1). Returns the initializer, if any.
local function AddText(layout, template, text, level)
	if text then
		if level == true then
			level = 1
		end
		local initializer = Settings.CreateElementInitializer(template, {
			text = text,
			indent = (level or 0) * INDENT_SIZE,
		})
		layout:AddInitializer(initializer)
		return initializer
	end
end

local function AddNote(layout, text, indented)
	return AddText(layout, NOTE_TEMPLATE, text, indented and 1 or 0)
end

local function ShowWhileEnabled(initializer, module)
	if initializer then
		initializer:AddShownPredicate(function()
			return module.db.enabled
		end)
	end
end

local function HasControls(module)
	for _, option in ipairs(module.options) do
		if option.type ~= "header" then
			return true
		end
	end
	return false
end

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

local function DefaultSliderFormatter(value)
	if value == math.floor(value) then
		return tostring(value)
	end
	return ("%.1f"):format(value)
end

local function SetParent(initializer, module, parentInitializer)
	if parentInitializer then
		initializer:SetParentInitializer(parentInitializer, function()
			return module.db.enabled
		end)
	end
end

-- Buttons have no saved value, they only run an action.
local function CreateButton(layout, module, option, parentInitializer)
	local initializer = CreateSettingsButtonInitializer(
		option.label,
		option.buttonText or option.label,
		function()
			if module.enabled then
				ns.Utils.SafeCall(option.onClick, module)
			end
		end,
		option.tooltip,
		true
	)
	layout:AddInitializer(initializer)
	SetParent(initializer, module, parentInitializer)
	return initializer
end

-- Blizzard's rows only know one indent level (parent initializer).
local function IndentTwice(initializer)
	initializer.GetIndent = function()
		return 2 * INDENT_SIZE
	end
end

local function CreateOptionControl(category, layout, module, option, parentInitializer)
	if option.type == "button" then
		return CreateButton(layout, module, option, parentInitializer)
	end

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
		sliderOptions:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, option.format or DefaultSliderFormatter)
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

	SetParent(initializer, module, parentInitializer)
	return initializer
end

local function AddModule(category, layout, module, isFirst)
	module.settings = {}

	if not isFirst then
		layout:AddInitializer(Settings.CreateElementInitializer(DIVIDER_TEMPLATE, {}))
	end

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
	AddNote(layout, module.note, false)
	if HasControls(module) then
		local hint = AddNote(layout, L.SETTINGS_ENABLE_FOR_OPTIONS, false)
		hint:AddShownPredicate(function()
			return not module.db.enabled
		end)
	end

	local grouped = false
	for _, option in ipairs(module.options) do
		if option.type == "header" then
			ShowWhileEnabled(AddText(layout, SUBHEADER_TEMPLATE, option.label, true), module)
			grouped = true
		else
			local initializer = CreateOptionControl(category, layout, module, option, enabledInitializer)
			ShowWhileEnabled(initializer, module)
			if grouped then
				IndentTwice(initializer)
			end
			ShowWhileEnabled(AddText(layout, NOTE_TEMPLATE, option.note, grouped and 2 or 1), module)
		end
	end
end

local function AddGeneralSettings(category, layout)
	layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(L.SETTINGS_GENERAL_HEADER))

	local printSetting = RegisterSetting(
		category, "printMessages", "printMessages", ns.db.global,
		L.SETTING_PRINT_MESSAGES, true
	)
	Settings.CreateCheckbox(category, printSetting, L.SETTING_PRINT_MESSAGES_DESC)

	local minimapSetting = RegisterSetting(
		category, "minimapButton", "minimapButton", ns.db.global,
		L.SETTING_MINIMAP_BUTTON, true,
		function()
			ns:UpdateMinimapButton()
		end
	)
	Settings.CreateCheckbox(category, minimapSetting, L.SETTING_MINIMAP_BUTTON_DESC)
	ns.minimapSetting = minimapSetting

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
		local modules = ns:GetSortedModules(categoryInfo.id)
		if #modules > 0 then
			local subcategory, layout = Settings.RegisterVerticalLayoutSubcategory(root, categoryInfo.name)
			for index, module in ipairs(modules) do
				AddModule(subcategory, layout, module, index == 1)
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
