-- luacheck: read globals InCombatLockdown
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Action bar padding",
		NOTE = "Button spacing beyond the Edit Mode range",
		DESC = "Sets the space between the buttons of the action bars freely, including no gap at all, instead of the 2 to 10 pixels Edit Mode allows.",
		PADDING = "Padding",
		PADDING_DESC = "Space between two buttons in pixels.",
		BARS = "Bars",
		MAIN = "Main bars",
		MAIN_DESC = "Action bar 1 to 8.",
		EXTRA = "Stance and pet bar",
		EXTRA_DESC = "The stance (form) bar and the pet bar.",
	},
	deDE = {
		TITLE = "Abstand der Aktionsleisten",
		NOTE = "Tastenabstand außerhalb des Bearbeitungsmodus-Bereichs",
		DESC = "Legt den Abstand zwischen den Tasten der Aktionsleisten frei fest, auch ganz ohne Lücke, statt der 2 bis 10 Pixel, die der Bearbeitungsmodus erlaubt.",
		PADDING = "Abstand",
		PADDING_DESC = "Abstand zwischen zwei Tasten in Pixeln.",
		BARS = "Leisten",
		MAIN = "Hauptleisten",
		MAIN_DESC = "Aktionsleiste 1 bis 8.",
		EXTRA = "Haltungs- und Begleiterleiste",
		EXTRA_DESC = "Die Haltungs- (Gestalt-) Leiste und die Begleiterleiste.",
	},
})

local function FormatPixels(value)
	return ("%d px"):format(value)
end

local module = ns:NewModule("ActionBarPadding", {
	title = L.TITLE,
	description = L.DESC,
	note = L.NOTE,
	category = "INTERFACE",
	combatProtected = true,
	defaults = {
		padding = 0,
		main = true,
		extra = true,
	},
	options = {
		{ key = "padding", type = "slider", label = L.PADDING, tooltip = L.PADDING_DESC, min = 0, max = 20, step = 1, format = FormatPixels },
		{ type = "header", label = L.BARS },
		{ key = "main", type = "checkbox", label = L.MAIN, tooltip = L.MAIN_DESC },
		{ key = "extra", type = "checkbox", label = L.EXTRA, tooltip = L.EXTRA_DESC },
	},
})

-- Bar frame name -> option that turns it on. MainActionBar is the Midnight
-- name, MainMenuBar the older one.
local BARS = {
	MainActionBar = "main",
	MainMenuBar = "main",
	MultiBarBottomLeft = "main",
	MultiBarBottomRight = "main",
	MultiBarRight = "main",
	MultiBarLeft = "main",
	MultiBar5 = "main",
	MultiBar6 = "main",
	MultiBar7 = "main",
	StanceBar = "extra",
	PetActionBar = "extra",
}

-- button -> anchor from Blizzard's last grid layout { point, relativeTo, relativePoint, x, y }
local originals = {}

local function Round(value)
	return math.floor(value + 0.5)
end

local function RestoreBar(bar)
	for _, button in ipairs(bar.actionButtons) do
		local anchor = originals[button]
		if anchor then
			button:ClearAllPoints()
			button:SetPoint(unpack(anchor))
		end
	end
end

-- Smallest non-zero distance between two buttons along one axis: the grid
-- step (button size plus Blizzard's padding).
local function GridStep(anchors, index)
	local first = anchors[1][index]
	local step
	for _, anchor in ipairs(anchors) do
		local distance = math.abs(anchor[index] - first)
		if distance > 0.5 and (not step or distance < step) then
			step = distance
		end
	end
	return step
end

-- Blizzard anchors every button of a bar to the same corner of the bar on a
-- grid; the grid position of a button is its offset divided by the step.
-- Re-placing them with button size plus our padding keeps orientation, rows
-- and growth direction without knowing the bar's settings.
function module:ApplyBar(bar)
	local buttons = bar.actionButtons
	local anchors = {}
	for i, button in ipairs(buttons) do
		if not originals[button] then
			if button:GetNumPoints() ~= 1 then
				self:Debug("unexpected anchors on", button:GetName() or "?")
				return
			end
			originals[button] = { button:GetPoint(1) }
		end
		anchors[i] = originals[button]
	end
	local first = anchors[1]
	if not first then
		return
	end
	for _, anchor in ipairs(anchors) do
		if anchor[2] ~= first[2] or anchor[1] ~= first[1] then
			self:Debug("buttons are not anchored on one grid")
			return
		end
	end

	local padding = self.db.padding
	local stepX, stepY = GridStep(anchors, 4), GridStep(anchors, 5)
	for i, button in ipairs(buttons) do
		local anchor = anchors[i]
		local x, y = anchor[4], anchor[5]
		if stepX then
			x = first[4] + Round((x - first[4]) / stepX) * (button:GetWidth() + padding)
		end
		if stepY then
			y = first[5] + Round((y - first[5]) / stepY) * (button:GetHeight() + padding)
		end
		button:ClearAllPoints()
		button:SetPoint(anchor[1], anchor[2], anchor[3], x, y)
	end
end

function module:UpdateBar(bar, option)
	if InCombatLockdown() then
		self:RegisterEvent("PLAYER_REGEN_ENABLED", "UpdateAll")
		return
	end
	if self.enabled and self.db[option] then
		self:ApplyBar(bar)
	else
		RestoreBar(bar)
	end
end

local function EachBar(callback)
	for name, option in pairs(BARS) do
		local bar = _G[name]
		if bar and bar.actionButtons then
			callback(bar, option)
		end
	end
end

function module:UpdateAll()
	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	EachBar(function(bar, option)
		self:UpdateBar(bar, option)
	end)
end

function module:OnEnable()
	EachBar(function(bar, option)
		if bar.UpdateGridLayout then
			-- Blizzard laid the buttons out again (Edit Mode, bar settings):
			-- its anchors are the new originals.
			self:SecureHook(bar, "UpdateGridLayout", function()
				for _, button in ipairs(bar.actionButtons) do
					originals[button] = nil
				end
				self:UpdateBar(bar, option)
			end)
		end
	end)
	self:UpdateAll()
end

-- combatProtected: never called in combat.
function module:OnDisable()
	EachBar(RestoreBar)
	wipe(originals)
end

function module:OnOptionChanged()
	self:UpdateAll()
end
