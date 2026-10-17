-- luacheck: read globals CreateColorFromHexString CreateFont STANDARD_TEXT_FONT MenuUtil PlaySound SOUNDKIT
local _, ns = ...

--[[
	Flat building blocks for the options window (OptionsWindow.lua): colors,
	fonts, backgrounds, borders and the controls (toggle switch, slider,
	dropdown, button). No Blizzard templates, so the look is fully ours.
]]

local Widgets = {}
ns.OptionsWidgets = Widgets

local accent = CreateColorFromHexString("ff" .. ns.color)
local ACCENT = { accent:GetRGB() }

local colors = {
	accent = ACCENT,
	window = { 0.07, 0.07, 0.08, 0.97 },
	sidebar = { 0.09, 0.09, 0.10, 1 },
	card = { 0.12, 0.12, 0.13, 1 },
	control = { 0.20, 0.20, 0.22, 1 },
	controlHover = { 0.26, 0.26, 0.28, 1 },
	knobOff = { 0.70, 0.70, 0.72, 1 },
	border = { 1, 1, 1, 0.07 },
	hover = { 1, 1, 1, 0.04 },
	selected = { 1, 1, 1, 0.07 },
	text = { 0.93, 0.93, 0.93, 1 },
	muted = { 0.62, 0.62, 0.64, 1 },
	dim = { 0.45, 0.45, 0.47, 1 },
}
Widgets.colors = colors

local function NewFont(name, size, color)
	local font = CreateFont("QualityOfLifeForeverFont" .. name)
	font:SetFont(STANDARD_TEXT_FONT, size, "")
	font:SetShadowOffset(1, -1)
	font:SetShadowColor(0, 0, 0, 0.6)
	font:SetTextColor(unpack(color))
	return font
end

Widgets.fonts = {
	title = NewFont("Title", 18, colors.text),
	heading = NewFont("Heading", 14, colors.text),
	body = NewFont("Body", 12, colors.text),
	small = NewFont("Small", 11, colors.muted),
	dim = NewFont("Dim", 11, colors.dim),
	section = NewFont("Section", 10, colors.accent),
	accent = NewFont("Accent", 12, colors.accent),
}
local fonts = Widgets.fonts

-- Basics ----------------------------------------------------------------------

function Widgets.Fill(frame, color, layer, sublevel)
	local texture = frame:CreateTexture(nil, layer or "BACKGROUND", nil, sublevel)
	texture:SetAllPoints()
	texture:SetColorTexture(unpack(color))
	return texture
end

-- 1 px border inside the frame's edges.
function Widgets.Border(frame, color)
	color = color or colors.border
	local edges = {}
	for _, side in ipairs({ "TOP", "BOTTOM", "LEFT", "RIGHT" }) do
		local line = frame:CreateTexture(nil, "BORDER")
		line:SetColorTexture(unpack(color))
		if side == "TOP" or side == "BOTTOM" then
			line:SetPoint(side .. "LEFT")
			line:SetPoint(side .. "RIGHT")
			line:SetHeight(1)
		else
			line:SetPoint("TOP" .. side)
			line:SetPoint("BOTTOM" .. side)
			line:SetWidth(1)
		end
		edges[#edges + 1] = line
	end
	return edges
end

function Widgets.Text(parent, font, justify)
	local text = parent:CreateFontString(nil, "OVERLAY")
	text:SetFontObject(font)
	text:SetJustifyH(justify or "LEFT")
	text:SetJustifyV("TOP")
	text:SetWordWrap(false)
	return text
end

-- A line drawn between two points relative to `anchor` (icons without textures).
function Widgets.Line(parent, anchor, point, x1, y1, x2, y2, color)
	local line = parent:CreateLine(nil, "OVERLAY")
	line:SetThickness(1.5)
	line:SetColorTexture(unpack(color or colors.muted))
	line:SetStartPoint(point, anchor, x1, y1)
	line:SetEndPoint(point, anchor, x2, y2)
	return line
end

-- Tooltips --------------------------------------------------------------------
-- Frames carry tooltipTitle/tooltipText; children forward their hover to the
-- row so the tooltip stays while the cursor is on a control.

function Widgets.ShowTooltip(frame)
	if frame.OnHoverChanged then
		frame:OnHoverChanged(true)
	end
	if not frame.tooltipText or frame.tooltipText == "" then
		return
	end
	GameTooltip:SetOwner(frame, "ANCHOR_NONE")
	GameTooltip:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 0, 2)
	GameTooltip:SetText(frame.tooltipTitle or "", 1, 1, 1)
	GameTooltip:AddLine(frame.tooltipText, 0.85, 0.85, 0.85, true)
	GameTooltip:Show()
end

function Widgets.HideTooltip(frame)
	if frame.OnHoverChanged then
		frame:OnHoverChanged(false)
	end
	GameTooltip:Hide()
end

function Widgets.ForwardHover(child, owner)
	child:HookScript("OnEnter", function()
		Widgets.ShowTooltip(owner)
	end)
	child:HookScript("OnLeave", function()
		Widgets.HideTooltip(owner)
	end)
end

-- Pools -----------------------------------------------------------------------

function Widgets.NewPool(create)
	return { free = {}, used = {}, create = create }
end

function Widgets.Acquire(pool, parent)
	local frame = table.remove(pool.free) or pool.create(parent)
	frame:SetParent(parent)
	frame:Show()
	pool.used[#pool.used + 1] = frame
	return frame
end

function Widgets.ReleaseAll(pool)
	for _, frame in ipairs(pool.used) do
		frame:Hide()
		frame:ClearAllPoints()
		pool.free[#pool.free + 1] = frame
	end
	wipe(pool.used)
end

-- Toggle switch ---------------------------------------------------------------

local TOGGLE_WIDTH, TOGGLE_HEIGHT, KNOB_SIZE = 32, 16, 12

local function SetToggleChecked(toggle, checked)
	toggle.checked = checked
	toggle.Track:SetColorTexture(unpack(checked and colors.accent or colors.control))
	toggle.Knob:SetColorTexture(unpack(checked and colors.text or colors.knobOff))
	toggle.Knob:ClearAllPoints()
	toggle.Knob:SetPoint(checked and "RIGHT" or "LEFT", checked and -2 or 2, 0)
end

-- toggle.onToggle(newValue) is called on click; the caller sets the new state.
function Widgets.CreateToggle(parent)
	local toggle = CreateFrame("Button", nil, parent)
	toggle:SetSize(TOGGLE_WIDTH, TOGGLE_HEIGHT)
	toggle.Track = Widgets.Fill(toggle, colors.control, "ARTWORK")
	toggle.Knob = toggle:CreateTexture(nil, "OVERLAY")
	toggle.Knob:SetSize(KNOB_SIZE, KNOB_SIZE)
	toggle.SetChecked = SetToggleChecked
	toggle:SetScript("OnClick", function(self)
		local checked = not self.checked
		PlaySound(checked and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
		if self.onToggle then
			self.onToggle(checked)
		end
	end)
	toggle:SetChecked(false)
	return toggle
end

-- Slider ----------------------------------------------------------------------

-- slider.onChange(value) is called for user input only.
function Widgets.CreateSlider(parent)
	local slider = CreateFrame("Slider", nil, parent)
	slider:SetOrientation("HORIZONTAL")
	slider:SetHeight(14)
	slider:SetObeyStepOnDrag(true)
	slider:SetHitRectInsets(0, 0, -4, -4)

	local track = slider:CreateTexture(nil, "BACKGROUND")
	track:SetColorTexture(unpack(colors.control))
	track:SetHeight(4)
	track:SetPoint("LEFT")
	track:SetPoint("RIGHT")

	local thumb = slider:CreateTexture(nil, "OVERLAY")
	thumb:SetSize(8, 14)
	thumb:SetColorTexture(unpack(colors.text))
	slider:SetThumbTexture(thumb)

	local fill = slider:CreateTexture(nil, "ARTWORK")
	fill:SetColorTexture(unpack(colors.accent))
	fill:SetHeight(4)
	fill:SetPoint("LEFT", track)
	fill:SetPoint("RIGHT", thumb, "CENTER")

	slider:SetScript("OnValueChanged", function(self, value, userInput)
		if userInput and self.onChange then
			self.onChange(value)
		end
	end)
	return slider
end

-- Dropdown --------------------------------------------------------------------

-- dropdown:SetEntries(entries, getValue, setValue); entries = { { value, label }, ... }
local function UpdateDropdownText(dropdown)
	local current = dropdown.getValue and dropdown.getValue()
	local text = ""
	for _, entry in ipairs(dropdown.entries or {}) do
		if entry.value == current then
			text = entry.label
		end
	end
	dropdown.Text:SetText(text)
end

function Widgets.CreateDropdown(parent)
	local dropdown = CreateFrame("Button", nil, parent)
	dropdown:SetSize(180, 22)
	dropdown.Background = Widgets.Fill(dropdown, colors.control)
	Widgets.Border(dropdown)
	dropdown.Text = Widgets.Text(dropdown, fonts.body)
	dropdown.Text:SetPoint("LEFT", 8, 0)
	dropdown.Text:SetPoint("RIGHT", -24, 0)
	dropdown.Text:SetJustifyV("MIDDLE")
	-- Chevron
	Widgets.Line(dropdown, dropdown, "RIGHT", -15, 2, -11, -2)
	Widgets.Line(dropdown, dropdown, "RIGHT", -11, -2, -7, 2)

	dropdown.SetEntries = function(self, entries, getValue, setValue)
		self.entries, self.getValue, self.setValue = entries, getValue, setValue
		UpdateDropdownText(self)
	end
	dropdown.Update = UpdateDropdownText

	dropdown:SetScript("OnEnter", function(self)
		self.Background:SetColorTexture(unpack(colors.controlHover))
	end)
	dropdown:SetScript("OnLeave", function(self)
		self.Background:SetColorTexture(unpack(colors.control))
	end)
	dropdown:SetScript("OnClick", function(self)
		MenuUtil.CreateContextMenu(self, function(_, root)
			for _, entry in ipairs(self.entries or {}) do
				root:CreateRadio(entry.label, function()
					return self.getValue() == entry.value
				end, function()
					self.setValue(entry.value)
					UpdateDropdownText(self)
				end)
			end
		end)
	end)
	return dropdown
end

-- Button ----------------------------------------------------------------------

local function SetButtonHovered(button, hovered)
	button.Background:SetColorTexture(ACCENT[1], ACCENT[2], ACCENT[3], hovered and 0.28 or 0.14)
end

function Widgets.CreateButton(parent)
	local button = CreateFrame("Button", nil, parent)
	button:SetHeight(22)
	button.Background = Widgets.Fill(button, colors.control)
	Widgets.Border(button, { ACCENT[1], ACCENT[2], ACCENT[3], 0.45 })
	button.Text = Widgets.Text(button, fonts.accent, "CENTER")
	button.Text:SetPoint("LEFT", 10, 0)
	button.Text:SetPoint("RIGHT", -10, 0)
	button.Text:SetJustifyV("MIDDLE")
	button.SetLabel = function(self, text)
		self.Text:SetText(text)
		self:SetWidth(math.max(90, self.Text:GetUnboundedStringWidth() + 24))
	end
	button:SetScript("OnEnter", function(self)
		SetButtonHovered(self, true)
	end)
	button:SetScript("OnLeave", function(self)
		SetButtonHovered(self, false)
	end)
	SetButtonHovered(button, false)
	return button
end
