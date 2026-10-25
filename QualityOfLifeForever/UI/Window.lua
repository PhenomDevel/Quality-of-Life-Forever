-- luacheck: read globals UISpecialFrames GetCursorPosition PlaySound SOUNDKIT SettingsPanel HideUIPanel tinsert strtrim C_Timer
local _, ns = ...

local L = ns.L
local Widgets = ns.OptionsWidgets
local colors, fonts = Widgets.colors, Widgets.fonts
local Markup = ns.Utils.Markup

--[[
	Standalone options window (/qol, minimap button, addon compartment).

	┌ header: logo, title, search, close ─────────────────────────────────┐
	│ sidebar: General +  │ page title + subtitle                         │
	│ one entry per       │ module list      │ options of the selected    │
	│ category            │ (title, note,    │ module in one full-width   │
	│                     │  switch)         │ card (scrolls)             │
	└─────────────────────┴──────────────────┴─────────────── resize grip ┘

	Category and search pages list their modules on the left, all the same
	height, and show the selected one's options on the right; the General
	page has no list. The selection is remembered per page.
	Pages are rebuilt from pooled frames whenever the layout changes (page,
	search, selection, a module turned on/off). Value changes from elsewhere
	(slash commands, SetOption) only refresh the visible controls.
]]

local DEFAULT_WIDTH, DEFAULT_HEIGHT = 1040, 640
local MIN_WIDTH, MIN_HEIGHT = 900, 420
local MAX_WIDTH, MAX_HEIGHT = 1700, 1200
local HEADER_HEIGHT = 56
local SIDEBAR_WIDTH = 210
local PADDING = 16
local SCROLLBAR_WIDTH = 10
local CARD_PADDING = 14
local CARD_GAP = 10
local LIST_WIDTH = 300
local LIST_GAP = 14
local LIST_ITEM_HEIGHT = 46
local ROW_HEIGHT = 30
local SLIDER_EXTRA = 22
local INPUT_WIDTH = 160
local TEXTAREA_HEIGHT = 64
local SCROLL_STEP = 48

local GENERAL = "GENERAL"

-- Derived from the window width by UpdateLayout() before every render.
local columnWidth, rowWidth

-- scroll/content: the options card(s); listScroll/listContent: module list.
local frame, scroll, content, listScroll, listContent, sidebar, searchBox
-- selected[page key] = key of the selected list entry
local state = { page = GENERAL, search = "", selected = {} }

--------------------------------------------------------------------------------
-- Rows
--------------------------------------------------------------------------------
-- A row = label (+ gray note) on the left, a control on the right. Each row
-- type has its own pool and an Update() that reads the bound value.

local function CreateRowBase(parent)
	local row = CreateFrame("Button", nil, parent)
	row.Label = Widgets.Text(row, fonts.body)
	row.Label:SetPoint("TOPLEFT", 0, -9)
	row.Note = Widgets.Text(row, fonts.small)
	row.Note:SetPoint("TOPLEFT", row.Label, "BOTTOMLEFT", 0, -3)
	row.Note:SetWordWrap(true)
	row:SetScript("OnEnter", Widgets.ShowTooltip)
	row:SetScript("OnLeave", Widgets.HideTooltip)
	return row
end

-- Sets label, note and tooltip; returns the row height.
local function SetupRow(row, spec, controlWidth, baseHeight)
	row:SetWidth(rowWidth)
	row.Label:SetWidth(rowWidth - controlWidth - 16)
	row.Label:SetText(spec.label)
	row.tooltipTitle, row.tooltipText = spec.label, spec.tooltip
	local height = baseHeight
	if spec.note then
		row.Note:SetWidth(rowWidth - controlWidth - 16)
		row.Note:SetText(Markup(spec.note))
		row.Note:Show()
		height = height + row.Note:GetStringHeight() + 2
	else
		row.Note:Hide()
	end
	row:SetHeight(height)
	return height
end

local rowTypes = {}

rowTypes.checkbox = {
	create = function(parent)
		local row = CreateRowBase(parent)
		row.Control = Widgets.CreateToggle(row)
		row.Control:SetPoint("RIGHT", row, "TOPRIGHT", 0, -ROW_HEIGHT / 2)
		Widgets.ForwardHover(row.Control, row)
		row:SetScript("OnClick", function(self)
			self.Control:Click()
		end)
		row.Update = function(self)
			self.Control:SetChecked(not not self.spec.get())
		end
		return row
	end,
	setup = function(row, spec)
		row.Control.onToggle = spec.set
		return SetupRow(row, spec, 32, ROW_HEIGHT)
	end,
}

local function FormatSliderValue(spec, value)
	if spec.format then
		return spec.format(value)
	end
	if value == math.floor(value) then
		return tostring(value)
	end
	return ("%.1f"):format(value)
end

rowTypes.slider = {
	create = function(parent)
		local row = CreateRowBase(parent)
		row.Value = Widgets.Text(row, fonts.value, "RIGHT")
		row.Value:SetPoint("TOPRIGHT", 0, -9)
		row.Control = Widgets.CreateSlider(row)
		row.Control:SetPoint("TOPLEFT", 0, -ROW_HEIGHT - 2)
		row.Control:SetPoint("TOPRIGHT", 0, -ROW_HEIGHT - 2)
		Widgets.ForwardHover(row.Control, row)
		row.Update = function(self)
			local value = self.spec.get()
			self.Value:SetText(FormatSliderValue(self.spec, value))
			if not self.Control:IsDraggingThumb() then
				self.Control:SetValue(value)
			end
		end
		return row
	end,
	setup = function(row, spec)
		local slider = row.Control
		slider:SetMinMaxValues(spec.min, spec.max)
		slider:SetValueStep(spec.step or 1)
		slider.onChange = function(value)
			spec.set(value)
			row.Value:SetText(FormatSliderValue(spec, value))
		end
		local height = SetupRow(row, spec, 60, ROW_HEIGHT + SLIDER_EXTRA)
		-- The note sits between label and slider.
		row.Control:SetPoint("TOPLEFT", 0, -(height - SLIDER_EXTRA + 2))
		row.Control:SetPoint("TOPRIGHT", 0, -(height - SLIDER_EXTRA + 2))
		return height
	end,
}

rowTypes.dropdown = {
	create = function(parent)
		local row = CreateRowBase(parent)
		row.Control = Widgets.CreateDropdown(row)
		row.Control:SetPoint("RIGHT", row, "TOPRIGHT", 0, -ROW_HEIGHT / 2)
		Widgets.ForwardHover(row.Control, row)
		row.Update = function(self)
			self.Control:Update()
		end
		return row
	end,
	setup = function(row, spec)
		row.Control:SetEntries(spec.values, spec.get, spec.set)
		return SetupRow(row, spec, row.Control:GetWidth(), ROW_HEIGHT)
	end,
}

rowTypes.button = {
	create = function(parent)
		local row = CreateRowBase(parent)
		row.Control = Widgets.CreateButton(row)
		row.Control:SetPoint("RIGHT", row, "TOPRIGHT", 0, -ROW_HEIGHT / 2)
		Widgets.ForwardHover(row.Control, row)
		row.Control:SetScript("OnClick", function()
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION)
			row.spec.onClick()
		end)
		row.Update = function() end
		return row
	end,
	setup = function(row, spec)
		row.Control:SetLabel(spec.buttonText or spec.label)
		return SetupRow(row, spec, row.Control:GetWidth(), ROW_HEIGHT)
	end,
}

-- Single-line text ("text" option).
rowTypes.text = {
	create = function(parent)
		local row = CreateRowBase(parent)
		row.Control = Widgets.CreateInput(row, false)
		row.Control:SetWidth(INPUT_WIDTH)
		row.Control:SetPoint("RIGHT", row, "TOPRIGHT", 0, -ROW_HEIGHT / 2)
		Widgets.ForwardHover(row.Control.EditBox, row)
		row.Update = function(self)
			self.Control:Update()
		end
		return row
	end,
	setup = function(row, spec)
		row.Control:SetBinding(spec.get, spec.set, spec.placeholder, spec.maxLetters)
		return SetupRow(row, spec, INPUT_WIDTH, ROW_HEIGHT)
	end,
}

-- Multi-line text below the label ("text" option with multiline = true).
rowTypes.textarea = {
	create = function(parent)
		local row = CreateRowBase(parent)
		row.Control = Widgets.CreateInput(row, true)
		row.Control:SetHeight(TEXTAREA_HEIGHT)
		Widgets.ForwardHover(row.Control.EditBox, row)
		row.Update = function(self)
			self.Control:Update()
		end
		return row
	end,
	setup = function(row, spec)
		row.Control:SetBinding(spec.get, spec.set, spec.placeholder, spec.maxLetters)
		local height = SetupRow(row, spec, 0, ROW_HEIGHT + TEXTAREA_HEIGHT + 6)
		-- The note sits between label and text field.
		local top = height - TEXTAREA_HEIGHT - 4
		row.Control:ClearAllPoints()
		row.Control:SetPoint("TOPLEFT", 0, -top)
		row.Control:SetPoint("TOPRIGHT", 0, -top)
		return height
	end,
}

-- Section title inside a card ("header" option).
rowTypes.header = {
	create = function(parent)
		local row = CreateFrame("Frame", nil, parent)
		local marker = row:CreateTexture(nil, "ARTWORK")
		marker:SetColorTexture(unpack(colors.accent))
		marker:SetSize(2, 12)
		marker:SetPoint("BOTTOMLEFT", 0, 4)
		row.Label = Widgets.Text(row, fonts.section)
		row.Label:SetPoint("BOTTOMLEFT", marker, "BOTTOMRIGHT", 6, 0)
		row.Update = function() end
		return row
	end,
	setup = function(row, spec)
		row:SetSize(rowWidth, 28)
		row.Label:SetText(spec.label)
		return 28
	end,
}

-- Highlighted, wrapping hint: the module's `notice` (e.g. game settings it
-- changes) and `status` (e.g. data still missing).
local NOTICE_COLOR = { 1, 0.82, 0.3, 1 }
local NOTICE_BAR = 2
local NOTICE_INDENT = NOTICE_BAR + 8

rowTypes.notice = {
	create = function(parent)
		local row = CreateFrame("Frame", nil, parent)
		row.Bar = row:CreateTexture(nil, "ARTWORK")
		row.Bar:SetColorTexture(unpack(NOTICE_COLOR))
		row.Bar:SetWidth(NOTICE_BAR)
		row.Label = Widgets.Text(row, fonts.small)
		row.Label:SetPoint("TOPLEFT", NOTICE_INDENT, -8)
		row.Label:SetWordWrap(true)
		row.Label:SetTextColor(unpack(NOTICE_COLOR))
		row.Bar:SetPoint("TOPLEFT", 0, -6)
		row.Bar:SetPoint("BOTTOMLEFT", 0, 4)
		row.Update = function() end
		return row
	end,
	setup = function(row, spec)
		row.Label:SetWidth(rowWidth - NOTICE_INDENT)
		row.Label:SetText(Markup(spec.label))
		local height = row.Label:GetStringHeight() + 14
		row:SetSize(rowWidth, height)
		return height
	end,
}

-- Wrapping description of a module at the top of its options.
rowTypes.description = {
	create = function(parent)
		local row = CreateFrame("Frame", nil, parent)
		row.Label = Widgets.Text(row, fonts.small)
		row.Label:SetPoint("TOPLEFT", 0, -6)
		row.Label:SetWordWrap(true)
		row.Update = function() end
		return row
	end,
	setup = function(row, spec)
		row.Label:SetWidth(rowWidth)
		row.Label:SetText(Markup(spec.label))
		local height = row.Label:GetStringHeight() + 12
		row:SetSize(rowWidth, height)
		return height
	end,
}

-- Gray single line, e.g. "More options appear when enabled."
rowTypes.hint = {
	create = function(parent)
		local row = CreateFrame("Frame", nil, parent)
		row.Label = Widgets.Text(row, fonts.dim)
		row.Label:SetPoint("TOPLEFT", 0, -2)
		row.Update = function() end
		return row
	end,
	setup = function(row, spec)
		row:SetSize(rowWidth, 18)
		row.Label:SetText(spec.label)
		return 18
	end,
}

for _, rowType in pairs(rowTypes) do
	rowType.pool = Widgets.NewPool(rowType.create)
end

--------------------------------------------------------------------------------
-- Cards
--------------------------------------------------------------------------------
-- spec = { title, note, tooltip, toggle = { get, set }, rows = { rowSpec }, hint }

local cardPool = Widgets.NewPool(function(parent)
	local card = CreateFrame("Frame", nil, parent)
	Widgets.Fill(card, colors.card)
	Widgets.Border(card)

	-- Hover area over title and note for the description tooltip.
	card.Header = CreateFrame("Button", nil, card)
	card.Header:SetPoint("TOPLEFT")
	card.Header:SetPoint("TOPRIGHT")
	card.Header:SetScript("OnEnter", Widgets.ShowTooltip)
	card.Header:SetScript("OnLeave", Widgets.HideTooltip)

	card.Title = Widgets.Text(card.Header, fonts.heading)
	card.Title:SetPoint("TOPLEFT", CARD_PADDING, -CARD_PADDING)
	card.Note = Widgets.Text(card.Header, fonts.small)
	card.Note:SetPoint("TOPLEFT", card.Title, "BOTTOMLEFT", 0, -4)
	card.Note:SetWordWrap(true)

	card.Toggle = Widgets.CreateToggle(card.Header)
	card.Toggle:SetPoint("TOPRIGHT", -CARD_PADDING, -CARD_PADDING)
	Widgets.ForwardHover(card.Toggle, card.Header)

	card.Divider = card:CreateTexture(nil, "ARTWORK")
	card.Divider:SetColorTexture(unpack(colors.border))
	card.Divider:SetHeight(1)
	return card
end)

local activeRows = {}

local function AddRow(card, spec, y)
	local rowType = rowTypes[spec.type]
	local row = Widgets.Acquire(rowType.pool, card)
	row.spec = spec
	local height = rowType.setup(row, spec)
	row:SetPoint("TOPLEFT", CARD_PADDING, -y)
	row:Update()
	activeRows[#activeRows + 1] = row
	return height
end

-- Builds a card at (left, top) of the content frame; returns its height.
local function AddCard(spec, left, top)
	local card = Widgets.Acquire(cardPool, content)
	card:SetWidth(columnWidth)
	card:SetPoint("TOPLEFT", left, -top)
	-- Room for the toggle switch on the right.
	card.Title:SetWidth(rowWidth - 48)
	card.Note:SetWidth(rowWidth - 48)

	local y
	if spec.title then
		card.Title:SetText(spec.title)
		card.Title:Show()
		y = CARD_PADDING + card.Title:GetStringHeight()
		if spec.note and spec.note ~= "" then
			card.Note:SetText(Markup(spec.note))
			card.Note:Show()
			y = y + 4 + card.Note:GetStringHeight()
		else
			card.Note:Hide()
		end
		y = y + CARD_PADDING
		card.Header:SetHeight(y)
		card.Header:Show()
		card.Header.tooltipTitle, card.Header.tooltipText = spec.title, spec.tooltip
	else
		card.Header:Hide()
		y = 4
	end

	if spec.toggle then
		card.Toggle:SetChecked(not not spec.toggle.get())
		card.Toggle.onToggle = spec.toggle.set
		card.Toggle:Show()
	else
		card.Toggle:Hide()
	end

	local hasRows = #spec.rows > 0 or spec.hint
	if hasRows and spec.title then
		card.Divider:ClearAllPoints()
		card.Divider:SetPoint("TOPLEFT", CARD_PADDING, -y)
		card.Divider:SetPoint("TOPRIGHT", -CARD_PADDING, -y)
		card.Divider:Show()
		y = y + 4
	else
		card.Divider:Hide()
	end
	for _, rowSpec in ipairs(spec.rows) do
		y = y + AddRow(card, rowSpec, y)
	end
	if spec.hint then
		y = y + AddRow(card, { type = "hint", label = spec.hint }, y)
	end
	if hasRows then
		y = y + CARD_PADDING - 4
	end

	card:SetHeight(y)
	return y
end

--------------------------------------------------------------------------------
-- Page content
--------------------------------------------------------------------------------

local function HasControls(module)
	for _, option in ipairs(module.options) do
		if option.type ~= "header" then
			return true
		end
	end
	return false
end

local function OptionRow(module, option)
	local spec = {
		type = option.type == "text" and option.multiline and "textarea" or option.type,
		label = option.label,
		tooltip = option.tooltip,
		note = option.note,
	}
	if option.type == "header" then
		return spec
	end
	if option.type == "button" then
		spec.buttonText = option.buttonText
		spec.onClick = function()
			if module.enabled then
				ns.Utils.SafeCall(option.onClick, module)
			end
		end
		return spec
	end
	spec.get = function()
		return module.db[option.key]
	end
	spec.set = function(value)
		module:SetOption(option.key, value)
	end
	spec.min, spec.max, spec.step, spec.format = option.min, option.max, option.step, option.format
	spec.values = option.values
	spec.placeholder, spec.maxLetters = option.placeholder, option.maxLetters
	return spec
end

local function ModuleToggle(module)
	return {
		get = function()
			return module.db.enabled
		end,
		set = function(enabled)
			ns:SetModuleEnabled(module, enabled)
		end,
	}
end

local function ModuleNote(module, categoryName)
	local note = module.note
	if categoryName then
		note = note and (categoryName .. "  ·  " .. note) or categoryName
	end
	return note
end

local function ModuleCard(module, categoryName)
	local spec = {
		title = module.title,
		note = ModuleNote(module, categoryName),
		toggle = ModuleToggle(module),
		rows = {},
	}
	if module.description ~= "" then
		spec.rows[1] = { type = "description", label = module.description }
	end
	if module.notice then
		spec.rows[#spec.rows + 1] = { type = "notice", label = module.notice }
	end
	if module.db.enabled then
		local status = module.status and module:status()
		if status then
			spec.rows[#spec.rows + 1] = { type = "notice", label = status }
		end
		for _, option in ipairs(module.options) do
			spec.rows[#spec.rows + 1] = OptionRow(module, option)
		end
	else
		-- Hooks of this session stay until a reload (see Module:SecureHook).
		if module.hooked then
			spec.rows[#spec.rows + 1] = { type = "notice", label = L.SETTINGS_UNLOAD_ON_RELOAD }
		end
		if HasControls(module) then
			spec.hint = L.SETTINGS_ENABLE_FOR_OPTIONS
		end
	end
	return spec
end

local function GlobalToggle(key, label, tooltip, onChange)
	return {
		type = "checkbox",
		label = label,
		tooltip = tooltip,
		get = function()
			return ns.db.global[key]
		end,
		set = function(value)
			ns.db.global[key] = value
			if onChange then
				onChange(value)
			end
			ns:RefreshOptionValues()
		end,
	}
end

-- Returns title, subtitle, no list entries, cards.
local function GeneralPage()
	return L.SETTINGS_GENERAL_HEADER, L.OPTIONS_VERSION:format(ns.version), nil, {
		{
			rows = {
				GlobalToggle("printMessages", L.SETTING_PRINT_MESSAGES, L.SETTING_PRINT_MESSAGES_DESC),
				GlobalToggle("notices", L.SETTING_NOTICES, L.SETTING_NOTICES_DESC),
				{
					type = "button",
					label = L.NOTICES_TEST,
					tooltip = L.NOTICES_TEST_DESC,
					buttonText = L.NOTICES_TEST_BUTTON,
					onClick = function()
						ns:ShowTestNotice()
					end,
				},
				GlobalToggle("whatsNew", L.SETTING_WHATS_NEW, L.SETTING_WHATS_NEW_DESC),
				{
					type = "button",
					label = L.WHATS_NEW_SHOW,
					tooltip = L.WHATS_NEW_SHOW_DESC,
					buttonText = L.NOTICES_TEST_BUTTON,
					onClick = function()
						ns:ShowWhatsNew()
					end,
				},
				GlobalToggle("minimapButton", L.SETTING_MINIMAP_BUTTON, L.SETTING_MINIMAP_BUTTON_DESC, function()
					ns:UpdateMinimapButton()
				end),
				GlobalToggle("debug", L.SETTING_DEBUG, L.SETTING_DEBUG_DESC),
				{
					type = "button",
					label = L.OPTIONS_RESET,
					tooltip = L.OPTIONS_RESET_DESC,
					buttonText = L.OPTIONS_RESET_BUTTON,
					onClick = function()
						ns:ConfirmReset()
					end,
				},
			},
		},
	}
end

local function CountEnabled(modules)
	local count = 0
	for _, module in ipairs(modules) do
		if module.db.enabled then
			count = count + 1
		end
	end
	return count
end

-- A list entry: { key, title, note, toggle, card = function() -> card spec }.
local function ModuleEntry(module, categoryName)
	return {
		key = module.name,
		title = module.title,
		note = ModuleNote(module, categoryName),
		toggle = ModuleToggle(module),
		card = function()
			return ModuleCard(module, categoryName)
		end,
	}
end

-- Widgets page: the stack setting comes first, above the widgets it affects.
local function WidgetStackEntry()
	local toggle = {
		get = function()
			return ns.db.global.stackWidgets
		end,
		set = function(value)
			ns.db.global.stackWidgets = value
			ns:UpdateWidgetStack()
			ns:RefreshOptions()
		end,
	}
	return {
		key = "WidgetStack",
		title = L.SETTING_STACK_WIDGETS,
		note = L.SETTING_STACK_WIDGETS_NOTE,
		toggle = toggle,
		card = function()
			return {
				title = L.SETTING_STACK_WIDGETS,
				note = L.SETTING_STACK_WIDGETS_NOTE,
				toggle = toggle,
				rows = { { type = "description", label = L.SETTING_STACK_WIDGETS_DESC } },
			}
		end,
	}
end

-- Returns title, subtitle, list entries.
local function CategoryPage(category)
	local modules = ns:GetSortedModules(category.id)
	local entries = {}
	if category.id == "WIDGETS" then
		entries[1] = WidgetStackEntry()
	end
	for _, module in ipairs(modules) do
		entries[#entries + 1] = ModuleEntry(module)
	end
	return category.name, L.OPTIONS_ENABLED_COUNT:format(CountEnabled(modules), #modules), entries
end

local function Matches(module, query)
	local function Has(text)
		return text and text:lower():find(query, 1, true)
	end
	if Has(module.title) or Has(module.note) or Has(module.description) or Has(module.notice) then
		return true
	end
	for _, option in ipairs(module.options) do
		if Has(option.label) or Has(option.tooltip) then
			return true
		end
	end
	return false
end

local function SearchPage()
	local query = state.search:lower()
	local categoryNames = {}
	for _, category in ipairs(ns.categories) do
		categoryNames[category.id] = category.name
	end
	local entries = {}
	for _, module in ipairs(ns:GetSortedModules()) do
		if Matches(module, query) then
			entries[#entries + 1] = ModuleEntry(module, categoryNames[module.category])
		end
	end
	local subtitle = #entries > 0 and L.OPTIONS_RESULT_COUNT:format(#entries) or L.OPTIONS_NO_RESULTS:format(state.search)
	return L.OPTIONS_SEARCH_RESULTS, subtitle, entries
end

local function PageKey()
	return state.search ~= "" and "SEARCH" or state.page
end

local function GetPage()
	if state.search ~= "" then
		return SearchPage()
	end
	if state.page ~= GENERAL then
		for _, category in ipairs(ns.categories) do
			if category.id == state.page then
				return CategoryPage(category)
			end
		end
	end
	return GeneralPage()
end

--------------------------------------------------------------------------------
-- Scrolling
--------------------------------------------------------------------------------

local function UpdateScrollBar(area)
	local bar = area.Bar
	local range = area:GetVerticalScrollRange()
	if range <= 0 then
		bar:Hide()
		return
	end
	bar:Show()
	local visible = area:GetHeight()
	local thumbHeight = math.max(24, visible * visible / (visible + range))
	bar.Thumb:SetHeight(thumbHeight)
	bar.Thumb:ClearAllPoints()
	bar.Thumb:SetPoint("TOP", 0, -area:GetVerticalScroll() / range * (visible - thumbHeight))
end

local function SetScroll(area, offset)
	local range = area:GetVerticalScrollRange()
	area:SetVerticalScroll(math.max(0, math.min(range, offset)))
	UpdateScrollBar(area)
end

local function OnThumbDrag(thumb)
	local area = thumb.area
	local _, cursorY = GetCursorPosition()
	cursorY = cursorY / thumb:GetEffectiveScale()
	local visible = area:GetHeight()
	local track = visible - thumb:GetHeight()
	if track > 0 then
		local range = area:GetVerticalScrollRange()
		SetScroll(area, thumb.startScroll + (thumb.startY - cursorY) / track * range)
	end
end

-- A scroll frame with a thin bar on its right; positioned by Render().
local function CreateScrollArea(parent)
	local area = CreateFrame("ScrollFrame", nil, parent)
	area:EnableMouseWheel(true)
	area:SetScript("OnMouseWheel", function(self, delta)
		SetScroll(self, self:GetVerticalScroll() - delta * SCROLL_STEP)
	end)

	area.Content = CreateFrame("Frame", nil, area)
	area.Content:SetSize(1, 1)
	area:SetScrollChild(area.Content)

	local bar = CreateFrame("Frame", nil, parent)
	bar:SetPoint("TOPLEFT", area, "TOPRIGHT", 5, 0)
	bar:SetPoint("BOTTOMLEFT", area, "BOTTOMRIGHT", 5, 0)
	bar:SetWidth(3)
	Widgets.Fill(bar, colors.hover)
	local thumb = CreateFrame("Frame", nil, bar)
	thumb.area = area
	thumb:SetWidth(3)
	thumb:SetHitRectInsets(-4, -4, 0, 0)
	thumb:EnableMouse(true)
	thumb.Texture = Widgets.Fill(thumb, colors.control)
	thumb:SetScript("OnMouseDown", function(self)
		local _, cursorY = GetCursorPosition()
		self.startY = cursorY / self:GetEffectiveScale()
		self.startScroll = area:GetVerticalScroll()
		self:SetScript("OnUpdate", OnThumbDrag)
	end)
	thumb:SetScript("OnMouseUp", function(self)
		self:SetScript("OnUpdate", nil)
	end)
	thumb:SetScript("OnEnter", function(self)
		self.Texture:SetColorTexture(unpack(colors.muted))
	end)
	thumb:SetScript("OnLeave", function(self)
		self.Texture:SetColorTexture(unpack(colors.control))
	end)
	bar.Thumb = thumb
	area.Bar = bar
	return area
end

--------------------------------------------------------------------------------
-- Module list
--------------------------------------------------------------------------------
-- Every entry has the same height: title, one line of note, switch.

local Render

local function SelectEntry(key)
	state.selected[PageKey()] = key
	scroll:SetVerticalScroll(0)
	Render()
end

local listItemPool = Widgets.NewPool(function(parent)
	local item = CreateFrame("Button", nil, parent)
	item:SetHeight(LIST_ITEM_HEIGHT)
	item.Hover = Widgets.Fill(item, colors.hover)
	item.Hover:Hide()
	item.Selected = Widgets.Fill(item, colors.selected)
	item.Marker = item:CreateTexture(nil, "ARTWORK")
	item.Marker:SetColorTexture(unpack(colors.accent))
	item.Marker:SetPoint("TOPLEFT")
	item.Marker:SetPoint("BOTTOMLEFT")
	item.Marker:SetWidth(2)

	item.Toggle = Widgets.CreateToggle(item)
	item.Toggle:SetPoint("RIGHT", -10, 0)

	item.Title = Widgets.Text(item, fonts.body)
	item.Title:SetPoint("TOPLEFT", 12, -8)
	item.Title:SetPoint("RIGHT", item.Toggle, "LEFT", -10, 0)
	item.Title:SetWordWrap(false)
	item.Note = Widgets.Text(item, fonts.small)
	item.Note:SetPoint("TOPLEFT", item.Title, "BOTTOMLEFT", 0, -4)
	item.Note:SetPoint("RIGHT", item.Toggle, "LEFT", -10, 0)
	item.Note:SetWordWrap(false)

	-- Also driven by the switch through ForwardHover.
	item.OnHoverChanged = function(self, hovered)
		self.Hover:SetShown(hovered)
	end
	item:SetScript("OnEnter", Widgets.ShowTooltip)
	item:SetScript("OnLeave", Widgets.HideTooltip)
	item:SetScript("OnClick", function(self)
		if not self.selected then
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION)
			SelectEntry(self.entry.key)
		end
	end)
	Widgets.ForwardHover(item.Toggle, item)
	return item
end)

local activeItems = {}

local function AddListItem(entry, selected, top, width)
	local item = Widgets.Acquire(listItemPool, listContent)
	item.entry, item.selected = entry, selected
	item:SetPoint("TOPLEFT", 0, -top)
	item:SetWidth(width)
	item.Selected:SetShown(selected)
	item.Marker:SetShown(selected)
	item.Title:SetText(entry.title)
	-- Long titles are cut off; the tooltip has them in full.
	item.tooltipTitle, item.tooltipText = entry.title, entry.note
	item.Title:SetTextColor(unpack(selected and colors.text or colors.muted))
	item.Note:SetText(Markup(entry.note or ""))
	item.Toggle:SetChecked(not not entry.toggle.get())
	item.Toggle.onToggle = entry.toggle.set
	activeItems[#activeItems + 1] = item
end

--------------------------------------------------------------------------------
-- Sidebar
--------------------------------------------------------------------------------

local sidebarButtons = {}

local function UpdateSidebar()
	for _, button in ipairs(sidebarButtons) do
		local selected = state.search == "" and state.page == button.page
		button.Selected:SetShown(selected)
		button.Marker:SetShown(selected)
		button.Label:SetTextColor(unpack(selected and colors.text or colors.muted))
	end
end

local function SelectPage(page)
	state.page = page
	if state.search ~= "" then
		searchBox:SetText("")
		searchBox:ClearFocus()
	end
	scroll:SetVerticalScroll(0)
	listScroll:SetVerticalScroll(0)
	Render()
end

local function AddSidebarButton(page, label, y)
	local button = CreateFrame("Button", nil, sidebar)
	button:SetPoint("TOPLEFT", 8, -y)
	button:SetPoint("TOPRIGHT", -8, -y)
	button:SetHeight(28)
	button.page = page

	button.Hover = Widgets.Fill(button, colors.hover)
	button.Hover:Hide()
	button.Selected = Widgets.Fill(button, colors.selected)
	button.Marker = button:CreateTexture(nil, "ARTWORK")
	button.Marker:SetColorTexture(unpack(colors.accent))
	button.Marker:SetPoint("TOPLEFT")
	button.Marker:SetPoint("BOTTOMLEFT")
	button.Marker:SetWidth(2)

	button.Label = Widgets.Text(button, fonts.body)
	button.Label:SetPoint("LEFT", 12, 0)
	button.Label:SetPoint("RIGHT", -8, 0)
	button.Label:SetJustifyV("MIDDLE")
	button.Label:SetText(label)

	button:SetScript("OnEnter", function(self)
		self.Hover:Show()
	end)
	button:SetScript("OnLeave", function(self)
		self.Hover:Hide()
	end)
	button:SetScript("OnClick", function(self)
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION)
		SelectPage(self.page)
	end)
	sidebarButtons[#sidebarButtons + 1] = button
end

local function CreateSidebar(parent)
	sidebar = CreateFrame("Frame", nil, parent)
	sidebar:SetPoint("TOPLEFT", 0, -HEADER_HEIGHT)
	sidebar:SetPoint("BOTTOMLEFT")
	sidebar:SetWidth(SIDEBAR_WIDTH)
	Widgets.Fill(sidebar, colors.sidebar)
	local edge = sidebar:CreateTexture(nil, "BORDER")
	edge:SetColorTexture(unpack(colors.border))
	edge:SetPoint("TOPRIGHT")
	edge:SetPoint("BOTTOMRIGHT")
	edge:SetWidth(1)

	local y = 10
	AddSidebarButton(GENERAL, L.SETTINGS_GENERAL_HEADER, y)
	y = y + 28 + 12
	for _, category in ipairs(ns.categories) do
		local modules = ns:GetSortedModules(category.id)
		if #modules > 0 then
			AddSidebarButton(category.id, category.name, y)
			y = y + 28
		end
	end
	return y + 10
end

--------------------------------------------------------------------------------
-- Header
--------------------------------------------------------------------------------

local function CreateSearchBox(parent)
	searchBox = CreateFrame("EditBox", nil, parent)
	searchBox:SetSize(220, 26)
	searchBox:SetAutoFocus(false)
	searchBox:SetFontObject(fonts.body)
	searchBox:SetTextInsets(10, 10, 0, 0)
	searchBox:SetMaxLetters(40)
	Widgets.Fill(searchBox, colors.control)
	Widgets.Border(searchBox)
	searchBox.Placeholder = Widgets.Text(searchBox, fonts.dim)
	searchBox.Placeholder:SetPoint("LEFT", 10, 0)
	searchBox.Placeholder:SetJustifyV("MIDDLE")
	searchBox.Placeholder:SetText(L.OPTIONS_SEARCH)

	local function UpdatePlaceholder(self)
		self.Placeholder:SetShown(self:GetText() == "" and not self:HasFocus())
	end
	searchBox:SetScript("OnEditFocusGained", UpdatePlaceholder)
	searchBox:SetScript("OnEditFocusLost", UpdatePlaceholder)
	searchBox:SetScript("OnEscapePressed", function(self)
		self:SetText("")
		self:ClearFocus()
	end)
	searchBox:SetScript("OnEnterPressed", searchBox.ClearFocus)
	searchBox:SetScript("OnTextChanged", function(self)
		UpdatePlaceholder(self)
		local text = strtrim(self:GetText())
		if text ~= state.search then
			state.search = text
			scroll:SetVerticalScroll(0)
			listScroll:SetVerticalScroll(0)
			Render()
		end
	end)
	return searchBox
end

local function CreateCloseButton(parent)
	local button = CreateFrame("Button", nil, parent)
	button:SetSize(26, 26)
	button.Hover = Widgets.Fill(button, colors.hover)
	button.Hover:Hide()
	local lines = {
		Widgets.Line(button, button, "CENTER", -5, 5, 5, -5),
		Widgets.Line(button, button, "CENTER", -5, -5, 5, 5),
	}
	button:SetScript("OnEnter", function(self)
		self.Hover:Show()
		for _, line in ipairs(lines) do
			line:SetColorTexture(unpack(colors.text))
		end
	end)
	button:SetScript("OnLeave", function(self)
		self.Hover:Hide()
		for _, line in ipairs(lines) do
			line:SetColorTexture(unpack(colors.muted))
		end
	end)
	button:SetScript("OnClick", function()
		frame:Hide()
	end)
	return button
end

local NotifyModules

-- Label + switch; the label is part of the button, so clicking it toggles too.
local function CreatePreviewToggle(parent)
	local button = CreateFrame("Button", nil, parent)
	button:SetHeight(26)
	button.tooltipTitle = L.OPTIONS_PREVIEW
	button.tooltipText = L.OPTIONS_PREVIEW_DESC
	local toggle = Widgets.CreateToggle(button)
	toggle:SetPoint("RIGHT")
	toggle:SetChecked(ns.db.global.optionsPreview)
	toggle.onToggle = function(checked)
		ns.db.global.optionsPreview = checked
		toggle:SetChecked(checked)
		NotifyModules(frame:IsShown())
	end
	Widgets.ForwardHover(toggle, button)
	local label = Widgets.Text(button, fonts.small, "RIGHT")
	label:SetPoint("RIGHT", toggle, "LEFT", -8, 0)
	label:SetJustifyV("MIDDLE")
	label:SetText(L.OPTIONS_PREVIEW)
	button:SetWidth(label:GetUnboundedStringWidth() + 8 + toggle:GetWidth())
	button:SetScript("OnEnter", Widgets.ShowTooltip)
	button:SetScript("OnLeave", Widgets.HideTooltip)
	button:SetScript("OnClick", function()
		toggle:Click()
	end)
	return button
end

local function CreateHeader(parent)
	local header = CreateFrame("Frame", nil, parent)
	header:SetPoint("TOPLEFT")
	header:SetPoint("TOPRIGHT")
	header:SetHeight(HEADER_HEIGHT)
	header:EnableMouse(true)
	header:RegisterForDrag("LeftButton")
	header:SetScript("OnDragStart", function()
		frame:StartMoving()
	end)
	header:SetScript("OnDragStop", function()
		frame:StopMovingOrSizing()
	end)

	local logo = header:CreateTexture(nil, "ARTWORK")
	logo:SetSize(28, 28)
	logo:SetPoint("LEFT", PADDING, 0)
	logo:SetTexture("Interface\\AddOns\\QualityOfLifeForever\\Media\\Logo")

	local title = Widgets.Text(header, fonts.heading)
	title:SetPoint("LEFT", logo, "RIGHT", 10, 0)
	title:SetJustifyV("MIDDLE")
	title:SetText(("Quality of Life |cff%sForever|r"):format(ns.color))

	local byline = Widgets.Text(header, fonts.small)
	byline:SetPoint("BOTTOMLEFT", title, "BOTTOMRIGHT", 8, 1)
	byline:SetText(L.OPTIONS_BYLINE)

	local version = Widgets.Text(header, fonts.dim)
	version:SetPoint("BOTTOMLEFT", byline, "BOTTOMRIGHT", 8, 0)
	version:SetText(L.OPTIONS_VERSION:format(ns.version))

	local close = CreateCloseButton(header)
	close:SetPoint("RIGHT", -PADDING + 4, 0)
	local search = CreateSearchBox(header)
	search:SetPoint("RIGHT", close, "LEFT", -10, 0)
	CreatePreviewToggle(header):SetPoint("RIGHT", search, "LEFT", -16, 0)

	local edge = header:CreateTexture(nil, "BORDER")
	edge:SetColorTexture(unpack(colors.border))
	edge:SetPoint("BOTTOMLEFT")
	edge:SetPoint("BOTTOMRIGHT")
	edge:SetHeight(1)
end

--------------------------------------------------------------------------------
-- Window
--------------------------------------------------------------------------------

local pageTitle, pageSubtitle

local CONTENT_TOP = HEADER_HEIGHT + 64

-- Places list and options area; without a list the options take the width.
local function UpdateLayout(hasList)
	local left = SIDEBAR_WIDTH + PADDING
	local width = frame:GetWidth() - left - PADDING - SCROLLBAR_WIDTH
	listScroll:SetShown(hasList)
	if not hasList then
		listScroll.Bar:Hide()
	end
	listScroll:ClearAllPoints()
	listScroll:SetPoint("TOPLEFT", left, -CONTENT_TOP)
	listScroll:SetPoint("BOTTOMLEFT", left, PADDING)
	listScroll:SetWidth(LIST_WIDTH - SCROLLBAR_WIDTH)
	listContent:SetWidth(LIST_WIDTH - SCROLLBAR_WIDTH)
	if hasList then
		left = left + LIST_WIDTH + LIST_GAP
		width = width - LIST_WIDTH - LIST_GAP
	end
	scroll:ClearAllPoints()
	scroll:SetPoint("TOPLEFT", left, -CONTENT_TOP)
	scroll:SetPoint("BOTTOMRIGHT", -(PADDING + SCROLLBAR_WIDTH), PADDING)
	columnWidth = width
	rowWidth = columnWidth - 2 * CARD_PADDING
	content:SetWidth(width)
end

-- The remembered selection if it is still listed, else the first entry.
local function SelectedEntry(entries)
	local key = state.selected[PageKey()]
	for _, entry in ipairs(entries) do
		if entry.key == key then
			return entry
		end
	end
	return entries[1]
end

Render = function()
	local offset, listOffset = scroll:GetVerticalScroll(), listScroll:GetVerticalScroll()
	for _, rowType in pairs(rowTypes) do
		Widgets.ReleaseAll(rowType.pool)
	end
	Widgets.ReleaseAll(cardPool)
	Widgets.ReleaseAll(listItemPool)
	wipe(activeRows)
	wipe(activeItems)

	local title, subtitle, entries, cards = GetPage()
	pageTitle:SetText(title)
	pageSubtitle:SetText(subtitle)
	UpdateLayout(entries ~= nil)

	if entries then
		local selected = SelectedEntry(entries)
		local width = LIST_WIDTH - SCROLLBAR_WIDTH
		for i, entry in ipairs(entries) do
			AddListItem(entry, entry == selected, (i - 1) * LIST_ITEM_HEIGHT, width)
		end
		listContent:SetHeight(math.max(1, #entries * LIST_ITEM_HEIGHT))
		listScroll:UpdateScrollChildRect()
		SetScroll(listScroll, listOffset)
		cards = { selected and selected.card() }
	end

	local height = 0
	for _, card in ipairs(cards) do
		height = height + AddCard(card, 0, height) + CARD_GAP
	end
	content:SetHeight(math.max(1, height - CARD_GAP))
	scroll:UpdateScrollChildRect()
	SetScroll(scroll, offset)
	UpdateSidebar()
end

-- Re-render at most every 0.05 s while the window is being resized.
local renderQueued
local function QueueRender()
	if renderQueued then
		return
	end
	renderQueued = true
	C_Timer.After(0.05, function()
		renderQueued = false
		if frame:IsShown() then
			Render()
		end
	end)
end

local function CreateResizeGrip(parent)
	local grip = CreateFrame("Button", nil, parent)
	grip:SetSize(16, 16)
	grip:SetPoint("BOTTOMRIGHT", -1, 1)
	grip:SetFrameLevel(parent:GetFrameLevel() + 20)
	local lines = {
		Widgets.Line(grip, grip, "BOTTOMRIGHT", -13, 3, -3, 13),
		Widgets.Line(grip, grip, "BOTTOMRIGHT", -9, 3, -3, 9),
		Widgets.Line(grip, grip, "BOTTOMRIGHT", -5, 3, -3, 5),
	}
	local function SetColor(color)
		for _, line in ipairs(lines) do
			line:SetColorTexture(unpack(color))
		end
	end
	grip:SetScript("OnEnter", function()
		SetColor(colors.text)
	end)
	grip:SetScript("OnLeave", function()
		SetColor(colors.muted)
	end)
	grip:SetScript("OnMouseDown", function()
		parent:StartSizing("BOTTOMRIGHT")
	end)
	grip:SetScript("OnMouseUp", function()
		parent:StopMovingOrSizing()
		ns.db.global.optionsWidth, ns.db.global.optionsHeight = parent:GetSize()
		Render()
	end)
end

local function Clamp(value, min, max)
	return math.max(min, math.min(max, value))
end

-- Modules can react to the window, e.g. show a preview of a widget that is
-- otherwise only visible in certain situations. The header's preview switch
-- turns that off while the window stays open.
function NotifyModules(shown)
	local preview = shown and ns.db.global.optionsPreview
	ns:UpdateOverlayTitles(preview)
	ns:UpdateNoticePreview(preview)
	for _, module in ipairs(ns.moduleOrder) do
		if module.enabled and module.OnOptionsShown then
			ns.Utils.SafeCall(module.OnOptionsShown, module, preview)
		end
	end
end

local function CreateWindow()
	frame = CreateFrame("Frame", "QualityOfLifeForeverOptionsFrame", UIParent)
	frame:SetPoint("CENTER")
	frame:SetFrameStrata("DIALOG")
	frame:SetToplevel(true)
	frame:SetMovable(true)
	frame:SetClampedToScreen(true)
	frame:EnableMouse(true)
	frame:Hide()
	Widgets.Fill(frame, colors.window)
	Widgets.Border(frame)
	tinsert(UISpecialFrames, frame:GetName())

	CreateHeader(frame)
	-- Never shorter than the sidebar's category list.
	local minHeight = math.max(MIN_HEIGHT, HEADER_HEIGHT + CreateSidebar(frame))
	frame:SetResizable(true)
	frame:SetResizeBounds(MIN_WIDTH, minHeight, MAX_WIDTH, MAX_HEIGHT)
	frame:SetSize(
		Clamp(ns.db.global.optionsWidth or DEFAULT_WIDTH, MIN_WIDTH, MAX_WIDTH),
		Clamp(ns.db.global.optionsHeight or DEFAULT_HEIGHT, minHeight, MAX_HEIGHT)
	)
	listScroll = CreateScrollArea(frame)
	listContent = listScroll.Content
	scroll = CreateScrollArea(frame)
	content = scroll.Content
	CreateResizeGrip(frame)

	pageTitle = Widgets.Text(frame, fonts.title)
	pageTitle:SetPoint("TOPLEFT", SIDEBAR_WIDTH + PADDING, -(HEADER_HEIGHT + 18))
	pageSubtitle = Widgets.Text(frame, fonts.small)
	pageSubtitle:SetPoint("TOPLEFT", pageTitle, "BOTTOMLEFT", 0, -5)

	frame:SetScript("OnSizeChanged", QueueRender)
	frame:SetScript("OnShow", function()
		PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN)
		Render()
		NotifyModules(true)
	end)
	frame:SetScript("OnHide", function()
		PlaySound(SOUNDKIT.IG_CHARACTER_INFO_CLOSE)
		Widgets.HideTooltip()
		searchBox:ClearFocus()
		NotifyModules(false)
	end)
end

--------------------------------------------------------------------------------
-- API
--------------------------------------------------------------------------------

function ns:OpenSettings()
	if not frame then
		CreateWindow()
	end
	-- Coming from Esc > Options > AddOns: leave Blizzard's panel. Not in
	-- combat, where closing it from addon code could block its protected calls.
	if SettingsPanel and SettingsPanel:IsShown() and not InCombatLockdown() then
		HideUIPanel(SettingsPanel)
	end
	frame:Show()
	frame:Raise()
end

function ns:ToggleSettings()
	if frame and frame:IsShown() then
		frame:Hide()
	else
		ns:OpenSettings()
	end
end

function ns:IsOptionsShown()
	return frame ~= nil and frame:IsShown()
end

-- Options open with the preview switch on: widgets and reminders show samples.
function ns:IsOptionsPreviewShown()
	return ns:IsOptionsShown() and ns.db.global.optionsPreview
end

-- Layout changed (module turned on/off): rebuild the visible page.
function ns:RefreshOptions()
	if frame and frame:IsShown() then
		Render()
	end
end

-- A value changed elsewhere: update the visible controls.
function ns:RefreshOptionValues()
	if not (frame and frame:IsShown()) then
		return
	end
	for _, row in ipairs(activeRows) do
		row:Update()
	end
	for _, item in ipairs(activeItems) do
		item.Toggle:SetChecked(not not item.entry.toggle.get())
	end
end
