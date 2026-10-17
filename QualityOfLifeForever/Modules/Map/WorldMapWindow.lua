-- luacheck: read globals WorldMapFrame UIParent CreateFrame InCombatLockdown
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Movable world map",
		SECTION_SIZE = "Size",
		SECTION_POSITION = "Position",
		NOTE = "Scale and position of the windowed map",
		DESC = "Scales the windowed world map (map and quest log) and lets you move it by dragging its title bar. The position is saved. The fullscreen map stays unchanged.",
		SCALE = "Scale",
		SCALE_DESC = "Size of the windowed map.",
		MOVABLE = "Movable",
		MOVABLE_DESC = "Drag the title bar of the windowed map to move it.",
		RESET = "Saved position",
		RESET_BUTTON = "Reset",
		RESET_DESC = "Forgets the saved position. The next time the map opens it is back in its default place.",
	},
	deDE = {
		TITLE = "Verschiebbare Weltkarte",
		SECTION_SIZE = "Größe",
		SECTION_POSITION = "Position",
		NOTE = "Größe und Position der Fensterkarte",
		DESC = "Skaliert die Weltkarte im Fenstermodus (Karte und Questlog) und lässt sie sich an der Titelleiste verschieben. Die Position wird gespeichert. Die Vollbildkarte bleibt unverändert.",
		SCALE = "Skalierung",
		SCALE_DESC = "Größe der Karte im Fenstermodus.",
		MOVABLE = "Verschiebbar",
		MOVABLE_DESC = "Die Titelleiste der Fensterkarte ziehen, um sie zu verschieben.",
		RESET = "Gespeicherte Position",
		RESET_BUTTON = "Zurücksetzen",
		RESET_DESC = "Vergisst die gespeicherte Position. Beim nächsten Öffnen ist die Karte wieder an ihrem Standardplatz.",
	},
})

local function FormatPercent(value)
	return ("%d%%"):format(value * 100 + 0.5)
end

local module = ns:NewModule("WorldMapWindow", {
	title = L.TITLE,
	description = L.DESC,
	note = L.NOTE,
	category = "MAP",
	defaults = {
		scale = 0.8,
		movable = true,
	},
	options = {
		{ type = "header", label = L.SECTION_SIZE },
		{ key = "scale", type = "slider", label = L.SCALE, tooltip = L.SCALE_DESC, min = 0.5, max = 1, step = 0.05, format = FormatPercent },
		{ type = "header", label = L.SECTION_POSITION },
		{ key = "movable", type = "checkbox", label = L.MOVABLE, tooltip = L.MOVABLE_DESC },
		{
			type = "button",
			label = L.RESET,
			buttonText = L.RESET_BUTTON,
			tooltip = L.RESET_DESC,
			onClick = function(self)
				self.db.x, self.db.y = nil, nil
			end,
		},
	},
})

-- Invisible drag area over the title bar.
local handle

local function CanModify()
	return not (InCombatLockdown() and WorldMapFrame:IsProtected())
end

-- Keeps the top left corner in place, so the panel manager's anchor (which
-- already accounts for the scale) stays valid.
local function SetScaleKeepingCorner(scale)
	local old = WorldMapFrame:GetScale()
	if math.abs(old - scale) < 0.001 then
		return
	end
	local left, top = WorldMapFrame:GetLeft(), WorldMapFrame:GetTop()
	WorldMapFrame:SetScale(scale)
	if left and top then
		WorldMapFrame:ClearAllPoints()
		WorldMapFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left * old / scale, top * old / scale)
	end
end

-- Runs after Blizzard positioned the map (show, minimize/maximize, other
-- panels opening).
function module:Apply()
	if not WorldMapFrame:IsShown() then
		return
	end
	if not CanModify() then
		self:RegisterEvent("PLAYER_REGEN_ENABLED", self.Apply)
		return
	end
	self:UnregisterEvent("PLAYER_REGEN_ENABLED")

	if WorldMapFrame:IsMaximized() then
		-- The fullscreen size is computed from UIParent and anchored at TOP.
		WorldMapFrame:SetScale(1)
		handle:Hide()
		return
	end
	local scale = self.db.scale
	SetScaleKeepingCorner(scale)
	handle:SetShown(self.db.movable)
	if self.db.movable and self.db.x then
		WorldMapFrame:ClearAllPoints()
		WorldMapFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", self.db.x / scale, self.db.y / scale)
	end
end

function module:StartDrag()
	if not CanModify() then
		return
	end
	self.dragging = true
	self.wasClamped = WorldMapFrame:IsClampedToScreen()
	WorldMapFrame:SetMovable(true)
	WorldMapFrame:SetClampedToScreen(true)
	WorldMapFrame:StartMoving()
end

function module:StopDrag()
	if not self.dragging then
		return
	end
	self.dragging = false
	WorldMapFrame:StopMovingOrSizing()
	-- Not user placed: the client would otherwise restore the position itself.
	WorldMapFrame:SetUserPlaced(false)
	WorldMapFrame:SetMovable(false)
	WorldMapFrame:SetClampedToScreen(self.wasClamped)
	-- Saved in UIParent coordinates, independent of the map scale.
	local scale = WorldMapFrame:GetScale()
	self.db.x, self.db.y = WorldMapFrame:GetLeft() * scale, WorldMapFrame:GetTop() * scale
end

function module:CreateHandle()
	local border = WorldMapFrame.BorderFrame
	handle = CreateFrame("Frame", nil, border)
	handle:SetPoint("TOPLEFT", border.TitleContainer, "TOPLEFT")
	handle:SetPoint("BOTTOMRIGHT", border.TitleContainer, "BOTTOMRIGHT")
	-- Below the title bar buttons (close, maximize), which sit on top of it.
	handle:SetFrameLevel(border:GetFrameLevel() + 1)
	handle:EnableMouse(true)
	handle:RegisterForDrag("LeftButton")
	handle:SetScript("OnDragStart", function()
		self:StartDrag()
	end)
	handle:SetScript("OnDragStop", function()
		self:StopDrag()
		self:Apply()
	end)
	handle:Hide()
end

function module:OnEnable()
	if not handle then
		self:CreateHandle()
	end
	self:SecureHook(WorldMapFrame, "SynchronizeDisplayState", self.Apply)
	self:SecureHook("UpdateUIPanelPositions", self.Apply)
	self:HookScript(WorldMapFrame, "OnShow", self.Apply)
	self:Apply()
end

function module:OnDisable()
	handle:Hide()
	self:StopDrag()
	if CanModify() then
		SetScaleKeepingCorner(1)
	end
end

function module:OnOptionChanged()
	self:Apply()
end
