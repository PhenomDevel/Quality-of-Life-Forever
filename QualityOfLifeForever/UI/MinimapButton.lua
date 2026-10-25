-- luacheck: read globals Minimap GetCursorPosition GetMinimapShape CreateColorFromHexString
local _, ns = ...

local L = ns.L

--[[
	Flat round button on the minimap rim: left-click opens the options,
	right-click Edit Mode (to move overlays), drag moves it around the rim. The angle (degrees, 0 = right, counterclockwise)
	and visibility are stored account-wide in ns.db.global.
]]

local SIZE = 30
local ICON_SIZE = 20
local RING_ALPHA, RING_ALPHA_HOVER = 0.75, 1
local CIRCLE_MASK = "Interface\\CharacterFrame\\TempPortraitAlphaMask"
local ACCENT = CreateColorFromHexString("ff" .. ns.color)

local button

-- Minimap shapes that have square instead of round corners, by quadrant
-- (top right, top left, bottom left, bottom right). GetMinimapShape is set by
-- minimap addons; the default minimap is round.
local SQUARE_QUADRANTS = {
	["SQUARE"] = { true, true, true, true },
	["CORNER-TOPRIGHT"] = { true, false, false, false },
	["CORNER-TOPLEFT"] = { false, true, false, false },
	["CORNER-BOTTOMLEFT"] = { false, false, true, false },
	["CORNER-BOTTOMRIGHT"] = { false, false, false, true },
	["SIDE-TOP"] = { true, true, false, false },
	["SIDE-LEFT"] = { false, true, true, false },
	["SIDE-BOTTOM"] = { false, false, true, true },
	["SIDE-RIGHT"] = { true, false, false, true },
	["TRICORNER-TOPRIGHT"] = { true, true, false, true },
	["TRICORNER-TOPLEFT"] = { true, true, true, false },
	["TRICORNER-BOTTOMLEFT"] = { false, true, true, true },
	["TRICORNER-BOTTOMRIGHT"] = { true, false, true, true },
}

local function UpdatePosition()
	local angle = math.rad(ns.db.global.minimapAngle)
	local x, y = math.cos(angle), math.sin(angle)
	local quadrant = (x >= 0 and (y >= 0 and 1 or 4)) or (y >= 0 and 2 or 3)
	local shape = GetMinimapShape and GetMinimapShape() or "ROUND"
	local square = SQUARE_QUADRANTS[shape]
	-- Centered on the rim; on square corners pushed out to the edge.
	local radius = Minimap:GetWidth() / 2
	if square and square[quadrant] then
		local scale = 1 / math.max(math.abs(x), math.abs(y))
		x, y = x * scale, y * scale
	end
	button:ClearAllPoints()
	button:SetPoint("CENTER", Minimap, "CENTER", x * radius, y * radius)
end

local function OnDragUpdate()
	local centerX, centerY = Minimap:GetCenter()
	local scale = Minimap:GetEffectiveScale()
	local cursorX, cursorY = GetCursorPosition()
	local angle = math.deg(math.atan2(cursorY / scale - centerY, cursorX / scale - centerX))
	ns.db.global.minimapAngle = math.floor(angle % 360 + 0.5)
	UpdatePosition()
end

local function SetHovered(hovered)
	button.Ring:SetAlpha(hovered and RING_ALPHA_HOVER or RING_ALPHA)
	local brightness = hovered and 1 or 0.9
	button.Icon:SetVertexColor(brightness, brightness, brightness)
end

local function ShowTooltip(self)
	local version = "|cffb8b8bc" .. L.OPTIONS_VERSION:format(ns.version) .. "|r"
	local body = table.concat({ version, "", L.MINIMAP_HINT_OPTIONS, L.MINIMAP_HINT_EDIT_MODE, L.MINIMAP_HINT_DRAG }, "\n")
	ns.OptionsWidgets.ShowTooltipAt(self, "TOPRIGHT", "BOTTOMLEFT", 0, 0, ns.title, body)
end

local function AddCircle(layer, sublevel, size)
	local texture = button:CreateTexture(nil, layer, nil, sublevel)
	texture:SetSize(size, size)
	texture:SetPoint("CENTER")
	local mask = button:CreateMaskTexture()
	mask:SetTexture(CIRCLE_MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
	mask:SetAllPoints(texture)
	texture:AddMaskTexture(mask)
	return texture
end

local function CreateButton()
	button = CreateFrame("Button", "QualityOfLifeForeverMinimapButton", Minimap)
	button:SetSize(SIZE, SIZE)
	button:SetFrameStrata("MEDIUM")
	button:SetFrameLevel(Minimap:GetFrameLevel() + 8)
	button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	button:RegisterForDrag("LeftButton")

	-- Accent ring = accent circle with a slightly smaller dark circle on top.
	button.Ring = AddCircle("BACKGROUND", 0, SIZE)
	button.Ring:SetColorTexture(ACCENT:GetRGB())
	local background = AddCircle("BACKGROUND", 1, SIZE - 4)
	background:SetColorTexture(0.07, 0.07, 0.08, 1)
	button.Icon = AddCircle("ARTWORK", 0, ICON_SIZE)
	button.Icon:SetTexture("Interface\\AddOns\\QualityOfLifeForever\\Media\\Logo")

	button:SetScript("OnClick", function(_, mouseButton)
		if mouseButton == "RightButton" then
			ns:OpenEditMode()
		else
			ns:ToggleSettings()
		end
	end)
	button:SetScript("OnEnter", function(self)
		SetHovered(true)
		ShowTooltip(self)
	end)
	button:SetScript("OnLeave", function()
		SetHovered(false)
		ns.OptionsWidgets.HideTooltip()
	end)
	button:SetScript("OnDragStart", function(self)
		ns.OptionsWidgets.HideTooltip()
		self:SetScript("OnUpdate", OnDragUpdate)
	end)
	button:SetScript("OnDragStop", function(self)
		self:SetScript("OnUpdate", nil)
	end)

	SetHovered(false)
end

-- Creates the button on first use, so a hidden button costs nothing.
function ns:UpdateMinimapButton()
	if not ns.db.global.minimapButton then
		if button then
			button:Hide()
		end
		return
	end
	if not button then
		CreateButton()
	end
	UpdatePosition()
	button:Show()
end
