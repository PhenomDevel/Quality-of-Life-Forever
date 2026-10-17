-- luacheck: read globals UISpecialFrames GetCursorPosition PlaySound SOUNDKIT SettingsPanel HideUIPanel tinsert strtrim
local _, ns = ...

local L = ns.L
local Widgets = ns.OptionsWidgets
local colors, fonts = Widgets.colors, Widgets.fonts

--[[
	Standalone options window (/qol, minimap button, addon compartment).

	┌ header: logo, title, search, close ──────────────────────────────┐
	│ sidebar: General +      │ page title + subtitle                  │
	│ one entry per category  │ module cards in two columns (scrolls)  │
	└─────────────────────────┴────────────────────────────────────────┘

	Cards fill two columns, each card going to the currently shorter one, so
	a card never moves when its own height changes (only the cards after it).
	Pages are rebuilt from pooled frames whenever the layout changes (page,
	search, a module turned on/off). Value changes from elsewhere (slash
	commands, SetOption) only refresh the visible controls.
]]

local WIDTH, HEIGHT = 1040, 640
local HEADER_HEIGHT = 56
local SIDEBAR_WIDTH = 210
local PADDING = 16
local SCROLLBAR_WIDTH = 10
local CONTENT_WIDTH = WIDTH - SIDEBAR_WIDTH - 2 * PADDING - SCROLLBAR_WIDTH
local CARD_PADDING = 14
local CARD_GAP = 10
local COLUMN_WIDTH = (CONTENT_WIDTH - CARD_GAP) / 2
local ROW_WIDTH = COLUMN_WIDTH - 2 * CARD_PADDING
local ROW_HEIGHT = 30
local SLIDER_EXTRA = 22
local SCROLL_STEP = 48

local GENERAL = "GENERAL"

local frame, scroll, content, sidebar, searchBox
local state = { page = GENERAL, search = "" }

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
	row:SetWidth(ROW_WIDTH)
	row.Label:SetWidth(ROW_WIDTH - controlWidth - 16)
	row.Label:SetText(spec.label)
	row.tooltipTitle, row.tooltipText = spec.label, spec.tooltip
	local height = baseHeight
	if spec.note then
		row.Note:SetWidth(ROW_WIDTH - controlWidth - 16)
		row.Note:SetText(spec.note)
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
		row.Value = Widgets.Text(row, fonts.accent, "RIGHT")
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

-- Section title inside a card ("header" option).
rowTypes.header = {
	create = function(parent)
		local row = CreateFrame("Frame", nil, parent)
		row.Label = Widgets.Text(row, fonts.section)
		row.Label:SetPoint("BOTTOMLEFT", 0, 4)
		row.Update = function() end
		return row
	end,
	setup = function(row, spec)
		row:SetSize(ROW_WIDTH, 28)
		row.Label:SetText(spec.label)
		return 28
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
		row:SetSize(ROW_WIDTH, 18)
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
	card.Title:SetWidth(ROW_WIDTH - 48)
	card.Note = Widgets.Text(card.Header, fonts.small)
	card.Note:SetPoint("TOPLEFT", card.Title, "BOTTOMLEFT", 0, -4)
	card.Note:SetWidth(ROW_WIDTH - 48)
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
	card:SetWidth(COLUMN_WIDTH)
	card:SetPoint("TOPLEFT", left, -top)

	local y
	if spec.title then
		card.Title:SetText(spec.title)
		card.Title:Show()
		y = CARD_PADDING + card.Title:GetStringHeight()
		if spec.note and spec.note ~= "" then
			card.Note:SetText(spec.note)
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
		type = option.type,
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
	return spec
end

local function ModuleCard(module, categoryName)
	local note = module.note
	if categoryName then
		note = note and (categoryName .. "  ·  " .. note) or categoryName
	end
	local spec = {
		title = module.title,
		note = note,
		tooltip = module.description,
		toggle = {
			get = function()
				return module.db.enabled
			end,
			set = function(enabled)
				ns:SetModuleEnabled(module, enabled)
			end,
		},
		rows = {},
	}
	if module.db.enabled then
		for _, option in ipairs(module.options) do
			spec.rows[#spec.rows + 1] = OptionRow(module, option)
		end
	elseif HasControls(module) then
		spec.hint = L.SETTINGS_ENABLE_FOR_OPTIONS
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

local function GeneralPage()
	return L.SETTINGS_GENERAL_HEADER, L.OPTIONS_VERSION:format(ns.version), {
		{
			rows = {
				GlobalToggle("printMessages", L.SETTING_PRINT_MESSAGES, L.SETTING_PRINT_MESSAGES_DESC),
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

local function CategoryPage(category)
	local modules = ns:GetSortedModules(category.id)
	local cards = {}
	for _, module in ipairs(modules) do
		cards[#cards + 1] = ModuleCard(module)
	end
	return category.name, L.OPTIONS_ENABLED_COUNT:format(CountEnabled(modules), #modules), cards
end

local function Matches(module, query)
	local function Has(text)
		return text and text:lower():find(query, 1, true)
	end
	if Has(module.title) or Has(module.note) or Has(module.description) then
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
	local cards = {}
	for _, module in ipairs(ns:GetSortedModules()) do
		if Matches(module, query) then
			cards[#cards + 1] = ModuleCard(module, categoryNames[module.category])
		end
	end
	local subtitle = #cards > 0 and L.OPTIONS_RESULT_COUNT:format(#cards) or L.OPTIONS_NO_RESULTS:format(state.search)
	return L.OPTIONS_SEARCH_RESULTS, subtitle, cards
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

local function UpdateScrollBar()
	local bar = scroll.Bar
	local range = scroll:GetVerticalScrollRange()
	if range <= 0 then
		bar:Hide()
		return
	end
	bar:Show()
	local visible = scroll:GetHeight()
	local thumbHeight = math.max(24, visible * visible / (visible + range))
	bar.Thumb:SetHeight(thumbHeight)
	bar.Thumb:ClearAllPoints()
	bar.Thumb:SetPoint("TOP", 0, -scroll:GetVerticalScroll() / range * (visible - thumbHeight))
end

local function SetScroll(offset)
	local range = scroll:GetVerticalScrollRange()
	scroll:SetVerticalScroll(math.max(0, math.min(range, offset)))
	UpdateScrollBar()
end

local function OnThumbDrag(thumb)
	local _, cursorY = GetCursorPosition()
	cursorY = cursorY / thumb:GetEffectiveScale()
	local visible = scroll:GetHeight()
	local track = visible - thumb:GetHeight()
	if track > 0 then
		local range = scroll:GetVerticalScrollRange()
		SetScroll(thumb.startScroll + (thumb.startY - cursorY) / track * range)
	end
end

local function CreateScrollArea(parent)
	scroll = CreateFrame("ScrollFrame", nil, parent)
	scroll:SetPoint("TOPLEFT", SIDEBAR_WIDTH + PADDING, -(HEADER_HEIGHT + 64))
	scroll:SetPoint("BOTTOMRIGHT", -(PADDING + SCROLLBAR_WIDTH), PADDING)
	scroll:EnableMouseWheel(true)
	scroll:SetScript("OnMouseWheel", function(self, delta)
		SetScroll(self:GetVerticalScroll() - delta * SCROLL_STEP)
	end)

	content = CreateFrame("Frame", nil, scroll)
	content:SetSize(CONTENT_WIDTH, 1)
	scroll:SetScrollChild(content)

	local bar = CreateFrame("Frame", nil, parent)
	bar:SetPoint("TOPLEFT", scroll, "TOPRIGHT", 5, 0)
	bar:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", 5, 0)
	bar:SetWidth(3)
	Widgets.Fill(bar, colors.hover)
	local thumb = CreateFrame("Frame", nil, bar)
	thumb:SetWidth(3)
	thumb:SetHitRectInsets(-4, -4, 0, 0)
	thumb:EnableMouse(true)
	thumb.Texture = Widgets.Fill(thumb, colors.control)
	thumb:SetScript("OnMouseDown", function(self)
		local _, cursorY = GetCursorPosition()
		self.startY = cursorY / self:GetEffectiveScale()
		self.startScroll = scroll:GetVerticalScroll()
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
	scroll.Bar = bar
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
		if button.modules then
			button.Count:SetText(("%d/%d"):format(CountEnabled(button.modules), #button.modules))
		end
	end
end

local Render

local function SelectPage(page)
	state.page = page
	if state.search ~= "" then
		searchBox:SetText("")
		searchBox:ClearFocus()
	end
	scroll:SetVerticalScroll(0)
	Render()
end

local function AddSidebarButton(page, label, modules, y)
	local button = CreateFrame("Button", nil, sidebar)
	button:SetPoint("TOPLEFT", 8, -y)
	button:SetPoint("TOPRIGHT", -8, -y)
	button:SetHeight(28)
	button.page, button.modules = page, modules

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
	button.Label:SetPoint("RIGHT", -40, 0)
	button.Label:SetJustifyV("MIDDLE")
	button.Label:SetText(label)
	button.Count = Widgets.Text(button, fonts.dim, "RIGHT")
	button.Count:SetPoint("RIGHT", -8, 0)
	button.Count:SetJustifyV("MIDDLE")

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
	AddSidebarButton(GENERAL, L.SETTINGS_GENERAL_HEADER, nil, y)
	y = y + 28 + 12
	for _, category in ipairs(ns.categories) do
		local modules = ns:GetSortedModules(category.id)
		if #modules > 0 then
			AddSidebarButton(category.id, category.name, modules, y)
			y = y + 28
		end
	end
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

	local close = CreateCloseButton(header)
	close:SetPoint("RIGHT", -PADDING + 4, 0)
	CreateSearchBox(header):SetPoint("RIGHT", close, "LEFT", -10, 0)

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

Render = function()
	local offset = scroll:GetVerticalScroll()
	for _, rowType in pairs(rowTypes) do
		Widgets.ReleaseAll(rowType.pool)
	end
	Widgets.ReleaseAll(cardPool)
	wipe(activeRows)

	local title, subtitle, cards = GetPage()
	pageTitle:SetText(title)
	pageSubtitle:SetText(subtitle)

	local columns = { 0, 0 }
	for _, card in ipairs(cards) do
		local column = columns[2] < columns[1] and 2 or 1
		local left = (column - 1) * (COLUMN_WIDTH + CARD_GAP)
		columns[column] = columns[column] + AddCard(card, left, columns[column]) + CARD_GAP
	end
	content:SetHeight(math.max(1, math.max(columns[1], columns[2]) - CARD_GAP))
	scroll:UpdateScrollChildRect()
	SetScroll(offset)
	UpdateSidebar()
end

local function CreateWindow()
	frame = CreateFrame("Frame", "QualityOfLifeForeverOptionsFrame", UIParent)
	frame:SetSize(WIDTH, HEIGHT)
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
	CreateSidebar(frame)
	CreateScrollArea(frame)

	pageTitle = Widgets.Text(frame, fonts.title)
	pageTitle:SetPoint("TOPLEFT", SIDEBAR_WIDTH + PADDING, -(HEADER_HEIGHT + 18))
	pageSubtitle = Widgets.Text(frame, fonts.small)
	pageSubtitle:SetPoint("TOPLEFT", pageTitle, "BOTTOMLEFT", 0, -5)

	frame:SetScript("OnShow", function()
		PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN)
		Render()
	end)
	frame:SetScript("OnHide", function()
		PlaySound(SOUNDKIT.IG_CHARACTER_INFO_CLOSE)
		GameTooltip:Hide()
		searchBox:ClearFocus()
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
end
