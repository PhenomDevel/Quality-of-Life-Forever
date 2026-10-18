-- luacheck: read globals EditModeManagerFrame ShowUIPanel CreateFont STANDARD_TEXT_FONT
local _, ns = ...

local L = ns.L
local LibEditMode = ns.LibEditMode

--[[
	Overlays: small frames owned by a module (e.g. the XP widget) that the
	player moves in Blizzard's Edit Mode via LibEditMode. Position and scale
	are stored account-wide per Edit Mode layout:

		ns.db.global.overlays[key][layoutName] = { point, x, y, scale }

	Frames can't be removed from LibEditMode, so an overlay is created once
	and its module shows/hides it. A hidden overlay is not shown in Edit Mode.
]]

local overlays = {}

-- Shared look: flat dark panel with a 1 px border, like the options window.
local BACKGROUND = { 0.07, 0.07, 0.08, 0.8 }
local BORDER = { 1, 1, 1, 0.08 }

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

local function Apply(frame, layoutName)
	local overlay = overlays[frame]
	local data = layoutName and GetLayoutData(overlay.key, layoutName) or {}
	local position = data.point and data or overlay.default
	frame:ClearAllPoints()
	frame:SetPoint(position.point, UIParent, position.point, position.x, position.y)
	frame:SetScale(data.scale or 1)
end

local function OnPositionChanged(frame, layoutName, point, x, y)
	local data = GetLayoutData(overlays[frame].key, layoutName, true)
	data.point, data.x, data.y = point, x, y
	Apply(frame, layoutName)
end

local function AddBorder(frame)
	for _, side in ipairs({ "TOP", "BOTTOM", "LEFT", "RIGHT" }) do
		local line = frame:CreateTexture(nil, "BORDER")
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
	frame:Hide()

	local background = frame:CreateTexture(nil, "BACKGROUND")
	background:SetAllPoints()
	background:SetColorTexture(unpack(BACKGROUND))
	AddBorder(frame)

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

	Apply(frame, LibEditMode:GetActiveLayoutName())
	return frame
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
