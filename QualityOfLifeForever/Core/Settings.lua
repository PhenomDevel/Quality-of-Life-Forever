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

--------------------------------------------------------------------------------
-- Wider labels
--------------------------------------------------------------------------------
-- Blizzard's list rows end the label at CENTER-85 and place the control at
-- CENTER-80, which truncates longer module names. Rows created by this addon
-- (initializer.qolForever) get LABEL_EXTRA more label width and shifted
-- controls. Rows are pooled and reused by other settings pages, so a shifted
-- row is moved back to Blizzard's position when it is initialized for
-- something else. Positions match Blizzard_SettingControls.lua (Forever 1.60.1).
-- Buttons are left alone: their anchor depends on per-row alignment.
local LABEL_EXTRA = 120
local TEXT_RIGHT_X = -85
local CONTROL_ANCHORS = {
	{ mixin = "SettingsCheckboxControlMixin", key = "Checkbox", x = -80, y = 0 },
	{ mixin = "SettingsSliderControlMixin", key = "SliderWithSteppers", x = -80, y = 3 },
	{ mixin = "SettingsDropdownControlMixin", key = "Control", x = -48, y = 3 },
}

local function Relayout(frame, initializer, anchor)
	local ours = initializer and initializer.qolForever
	if not ours and not frame.qolForeverShifted then
		return
	end
	local shift = ours and LABEL_EXTRA or 0
	frame.Text:SetPoint("RIGHT", frame, "CENTER", TEXT_RIGHT_X + shift, 0)
	local control = frame[anchor.key]
	if control then
		control:ClearAllPoints()
		control:SetPoint("LEFT", frame, "CENTER", anchor.x + shift, anchor.y)
	end
	frame.qolForeverShifted = ours or nil
end

-- Must run before the settings list creates its rows: templates copy the mixin
-- functions into each frame at creation time.
for _, anchor in ipairs(CONTROL_ANCHORS) do
	local mixin = _G[anchor.mixin]
	if mixin and mixin.Init then
		hooksecurefunc(mixin, "Init", function(frame, initializer)
			Relayout(frame, initializer, anchor)
		end)
	end
end

local function Mark(initializer)
	initializer.qolForever = true
	return initializer
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
		initializer = Mark(Settings.CreateCheckbox(category, setting, option.tooltip))
	elseif option.type == "slider" then
		local sliderOptions = Settings.CreateSliderOptions(option.min, option.max, option.step or 1)
		sliderOptions:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, option.format or DefaultSliderFormatter)
		initializer = Mark(Settings.CreateSlider(category, setting, sliderOptions, option.tooltip))
	elseif option.type == "dropdown" then
		local function GetOptions()
			local container = Settings.CreateControlTextContainer()
			for _, entry in ipairs(option.values) do
				container:Add(entry.value, entry.label)
			end
			return container:GetData()
		end
		initializer = Mark(Settings.CreateDropdown(category, setting, GetOptions, option.tooltip))
	else
		error(("Module %q option %q has unknown type %q"):format(module.name, option.key, tostring(option.type)))
	end

	SetParent(initializer, module, parentInitializer)
	return initializer
end

local function AddModule(category, layout, module)
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
	local enabledInitializer = Mark(Settings.CreateCheckbox(category, enabledSetting, module.description))

	for _, option in ipairs(module.options) do
		CreateOptionControl(category, layout, module, option, enabledInitializer)
	end
end

local function AddGeneralSettings(category, layout)
	layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(L.SETTINGS_GENERAL_HEADER))

	local printSetting = RegisterSetting(
		category, "printMessages", "printMessages", ns.db.global,
		L.SETTING_PRINT_MESSAGES, true
	)
	Mark(Settings.CreateCheckbox(category, printSetting, L.SETTING_PRINT_MESSAGES_DESC))

	local debugSetting = RegisterSetting(
		category, "debug", "debug", ns.db.global,
		L.SETTING_DEBUG, false
	)
	Mark(Settings.CreateCheckbox(category, debugSetting, L.SETTING_DEBUG_DESC))
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
			local subcategory, layout = Settings.RegisterVerticalLayoutSubcategory(root, categoryInfo.name)
			for _, module in ipairs(modules) do
				AddModule(subcategory, layout, module)
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
