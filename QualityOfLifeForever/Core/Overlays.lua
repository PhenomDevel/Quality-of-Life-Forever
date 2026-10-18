-- luacheck: read globals EditModeManagerFrame ShowUIPanel CreateFont STANDARD_TEXT_FONT
local _, ns = ...

local L = ns.L
local LibEditMode = ns.LibEditMode

--[[
	Overlays: small frames owned by a module (e.g. the XP widget). The player
	drags them directly or moves and scales them in Blizzard's Edit Mode via
	LibEditMode. Position and scale are stored account-wide per Edit Mode
	layout:

		ns.db.global.overlays[key][layoutName] = { point, x, y, scale }

	Frames can't be removed from LibEditMode, so an overlay is created once
	and its module shows/hides it. A hidden overlay is not shown in Edit Mode.
]]

local overlays = {}

-- Shared look: flat dark panel with a 1 px border, like the options window.
local BACKGROUND = { 0.07, 0.07, 0.08, 0.92 }
local BORDER = { 1, 1, 1, 0.15 }

ns.overlayFont = CreateFont("QualityOfLifeForeverOverlayFont")
ns.overlayFont:SetFont(STANDARD_TEXT_FONT, 11, "")
ns.overlayFont:SetShadowOffset(1, -1)
ns.overlayFont:SetShadowColor(0, 0, 0, 0.8)

local function GetLayoutData(key, layoutName, create)
	local store = ns.db.global.overlays
	local layouts = store[key]
	if not layouts then
		if not create then
			return nil
		end
		layouts = {}
		store[key] = layouts
	end
	if not layouts[layoutName] and create then
		layouts[layoutName] = {}
	end
	return layouts[layoutName]
end

-- Widget stack ------------------------------------------------------------------
-- With ns.db.global.stackWidgets the shown widgets are stacked top to bottom,
-- left-aligned, below one shared anchor (its own overlay, so it is moved like
-- any widget). Their own positions stay saved for when stacking is off.

local STACK_ORDER = {
	XPWidget = 1,
	ReputationWidget = 2,
	GoldWidget = 3,
	ReagentWidget = 4,
	PerformanceWidget = 5,
	-- Last: it shows and hides often and would move the others.
	PowerTickWidget = 6,
}
local STACK_GAP = 2
local stackAnchor

local function IsStacked(frame)
	local overlay = overlays[frame]
	return overlay ~= nil and STACK_ORDER[overlay.key] ~= nil and ns.db.global.stackWidgets
end

local function Restack()
	if not stackAnchor then
		return
	end
	if not ns.db.global.stackWidgets then
		stackAnchor:Hide()
		return
	end
	local shown = {}
	for frame, overlay in pairs(overlays) do
		if STACK_ORDER[overlay.key] and frame:IsShown() then
			shown[#shown + 1] = frame
		end
	end
	table.sort(shown, function(a, b)
		return STACK_ORDER[overlays[a].key] < STACK_ORDER[overlays[b].key]
	end)
	-- Sizes in the anchor's coordinates; each widget keeps its own scale.
	local anchorScale = stackAnchor:GetEffectiveScale()
	local width, height = 0, 0
	for i, frame in ipairs(shown) do
		frame:ClearAllPoints()
		if i == 1 then
			frame:SetPoint("TOPLEFT", stackAnchor, "TOPLEFT")
		else
			frame:SetPoint("TOPLEFT", shown[i - 1], "BOTTOMLEFT", 0, -STACK_GAP)
		end
		local scale = frame:GetEffectiveScale() / anchorScale
		width = math.max(width, frame:GetWidth() * scale)
		height = height + frame:GetHeight() * scale + (i > 1 and STACK_GAP or 0)
	end
	stackAnchor:SetSize(math.max(width, 60), math.max(height, 20))
	stackAnchor:Show()
end

local function Apply(frame, layoutName)
	local overlay = overlays[frame]
	local data = layoutName and GetLayoutData(overlay.key, layoutName) or {}
	frame:SetScale(data.scale or 1)
	if IsStacked(frame) then
		Restack()
		return
	end
	local position = data.point and data or overlay.default
	frame:ClearAllPoints()
	frame:SetPoint(position.point, UIParent, position.point, position.x, position.y)
end

local function OnPositionChanged(frame, layoutName, point, x, y)
	local data = GetLayoutData(overlays[frame].key, layoutName, true)
	data.point, data.x, data.y = point, x, y
	Apply(frame, layoutName)
end

-- Dragging outside Edit Mode stores the position the same way, as a CENTER
-- offset in the frame's own (scaled) coordinates.
-- A stacked widget drags the whole stack.
local function DragTarget(frame)
	return IsStacked(frame) and stackAnchor or frame
end

local function OnDragStart(frame)
	frame = DragTarget(frame)
	-- LibEditMode turns movable off again after editing a frame.
	frame:SetMovable(true)
	frame:StartMoving()
end

local function OnDragStop(frame)
	frame = DragTarget(frame)
	frame:StopMovingOrSizing()
	frame:SetUserPlaced(false)
	local layoutName = LibEditMode:GetActiveLayoutName()
	if not layoutName then
		-- Layouts not loaded yet: nothing to store under, snap back.
		Apply(frame, nil)
		return
	end
	local scale = frame:GetScale()
	local x, y = frame:GetCenter()
	local parentX, parentY = UIParent:GetCenter()
	OnPositionChanged(frame, layoutName, "CENTER", x - parentX / scale, y - parentY / scale)
end

local function AddBorder(frame)
	frame.Border = {}
	for _, side in ipairs({ "TOP", "BOTTOM", "LEFT", "RIGHT" }) do
		local line = frame:CreateTexture(nil, "BORDER")
		frame.Border[#frame.Border + 1] = line
		line:SetColorTexture(unpack(BORDER))
		if side == "TOP" or side == "BOTTOM" then
			line:SetPoint(side .. "LEFT")
			line:SetPoint(side .. "RIGHT")
			line:SetHeight(1)
		else
			line:SetPoint("TOP" .. side)
			line:SetPoint("BOTTOM" .. side)
			line:SetWidth(1)
		end
	end
end

-- Shared panel look (overlays, notices): frame.Background and frame.Border.
function ns:AddPanelBackground(frame)
	frame.Background = frame:CreateTexture(nil, "BACKGROUND")
	frame.Background:SetAllPoints()
	frame.Background:SetColorTexture(unpack(BACKGROUND))
	AddBorder(frame)
end

--[[
	info = {
		title    = name shown in Edit Mode (localized)
		width, height
		default  = { point, x, y } relative to UIParent
		settings = optional extra LibEditMode settings (after scale)
	}
	Returns the hidden overlay frame.
]]
function ns:CreateOverlay(key, info)
	local frame = CreateFrame("Frame", "QualityOfLifeForeverOverlay" .. key, UIParent)
	frame:SetSize(info.width, info.height)
	frame:SetClampedToScreen(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", OnDragStart)
	frame:SetScript("OnDragStop", OnDragStop)
	frame:Hide()

	ns:AddPanelBackground(frame)

	overlays[frame] = { key = key, default = info.default }
	LibEditMode:AddFrame(frame, OnPositionChanged, info.default, info.title)

	local settings = {
		{
			kind = LibEditMode.SettingType.Slider,
			name = L.OVERLAY_SCALE,
			default = 1,
			minValue = 0.5,
			maxValue = 2,
			valueStep = 0.05,
			formatter = function(value)
				return ("%d%%"):format(math.floor(value * 100 + 0.5))
			end,
			get = function(layoutName)
				local data = GetLayoutData(key, layoutName)
				return data and data.scale or 1
			end,
			set = function(layoutName, value)
				GetLayoutData(key, layoutName, true).scale = value
				Apply(frame, layoutName)
			end,
		},
	}
	for _, setting in ipairs(info.settings or {}) do
		settings[#settings + 1] = setting
	end
	LibEditMode:AddFrameSettings(frame, settings)

	if STACK_ORDER[key] then
		for _, script in ipairs({ "OnShow", "OnHide", "OnSizeChanged" }) do
			frame:HookScript(script, Restack)
		end
	end

	Apply(frame, LibEditMode:GetActiveLayoutName())
	return frame
end

-- Called once on login, before the modules create their widgets.
function ns:InitializeWidgetStack()
	-- Invisible and click-through; only Edit Mode's selection shows it.
	stackAnchor = ns:CreateOverlay("WidgetStack", {
		title = L.WIDGET_STACK_EDIT_MODE_NAME,
		width = 260,
		height = 40,
		default = { point = "TOP", x = 0, y = -60 },
	})
	ns:SetOverlayBackgroundAlpha(stackAnchor, 0)
	stackAnchor:EnableMouse(false)
	Restack()
end

-- The stackWidgets setting changed: re-place every widget.
function ns:UpdateWidgetStack()
	local layoutName = LibEditMode:GetActiveLayoutName()
	for frame in pairs(overlays) do
		Apply(frame, layoutName)
	end
	Restack()
end

-- Opacity of the shared background (0–1). The border fades along, relative
-- to its default, so the default background alpha keeps the default look.
function ns:SetOverlayBackgroundAlpha(frame, alpha)
	frame.Background:SetColorTexture(BACKGROUND[1], BACKGROUND[2], BACKGROUND[3], alpha)
	local borderAlpha = math.min(1, BORDER[4] * alpha / BACKGROUND[4])
	for _, line in ipairs(frame.Border) do
		line:SetColorTexture(BORDER[1], BORDER[2], BORDER[3], borderAlpha)
	end
end

LibEditMode:RegisterCallback("layout", function(layoutName)
	for frame in pairs(overlays) do
		Apply(frame, layoutName)
	end
end)

-- Same path as Esc > Edit Mode; Blizzard's checks still apply.
function ns:OpenEditMode()
	if InCombatLockdown() then
		ns:Print(L.EDIT_MODE_COMBAT)
		return
	end
	if EditModeManagerFrame and EditModeManagerFrame:CanEnterEditMode() then
		ShowUIPanel(EditModeManagerFrame)
	end
end
